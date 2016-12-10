require 'securerandom'
require 'logger'
require 'etc'
require 'workflow_rb'
require 'workflow_rb/services/memory_persistence_provider'
require 'workflow_rb/services/single_node_queue_provider'
require 'workflow_rb/services/single_node_lock_provider'

module WorkflowRb
  class WorkflowHost

    def initialize
      @persistence = MemoryPersistenceProvider.new
      @queue_provider = SingleNodeQueueProvider.new
      @lock_provider = SingleNodeLockProvider.new
      @registry = WorkflowRegistry.new
      @is_shutdown = true;
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::WARN
      @thread_count = Etc.nprocessors
      @threads = []
      @poll_interval = 5
      @poll_tick = 0
    end

    def use_logger(logger)
      @logger = logger
    end

    def use_persistence(persistence)
      @persistence = persistence
    end

    def register_workflow(workflow_class)
      builder = WorkflowRb::WorkflowBuilder.new
      workflow_obj = workflow_class.new
      workflow_obj.build(builder)
      definition = builder.build(workflow_class::ID, workflow_class::VERSION, workflow_class::DATA_CLASS)
      @registry.register_workflow(definition)
    end

    def start_workflow(definition_id, version, data = nil)
      wf_def = @registry.get_definition(definition_id, version)

      wf = WorkflowInstance.new
      wf.definition_id = definition_id
      wf.version = version
      wf.next_execution = Time.new
      wf.create_time = Time.new
      wf.status = WorkflowStatus::RUNNABLE

      if data
        wf.data = data
      else
        if wf_def.data_class
          wf.data = wf_def.data_class.new
        end
      end

      ep = ExecutionPointer.new
      ep.active = true
      ep.step_id = wf_def.initial_step
      ep.concurrent_fork = 1
      wf.execution_pointers << ep

      id = @persistence.create_new_workflow(wf)
      @queue_provider.queue_for_processing(id)
      id
    end

    def start
      if (@is_shutdown)
        @is_shutdown = false;
        @logger.info('Starting worker thread pool')

        @thread_count.times do
          @threads << Thread.new { run_workflows }
        end

        @threads << Thread.new { run_publications }
        @threads << Thread.new { house_keeping }

      end
    end

    def stop
      @is_shutdown = true;
      @logger.info('Stopping worker thread pool')
      @threads.each do |thread|
        thread.join(10)
      end
    end

    def subscribe_event(workflow_id, step_id, event_name, event_key)
      @logger.info("Subscribing to event #{event_name} #{event_key} for workflow #{workflow_id} step #{step_id}")
      sub = EventSubscription.new
      sub.workflow_id = workflow_id
      sub.step_id = step_id
      sub.event_name = event_name
      sub.event_key = event_key
      @persistence.create_subscription(sub)
    end

    def publish_event(event_name, event_key, event_data)
      if @is_shutdown
        raise Exception 'Host is not running'
      end
      @logger.info("Publishing event #{event_name} #{event_key}")
      subs = @persistence.get_subscriptions(event_name, event_key)
      subs.each do |sub|
        pub = EventPublication.new
        pub.id = SecureRandom.uuid
        pub.event_data = event_data
        pub.event_key = event_key
        pub.event_name = event_name
        pub.step_id = sub.step_id
        pub.workflow_id = sub.workflow_id
        @queue_provider.queue_for_publish(pub)
        @persistence.terminate_subscription(sub.id)
      end
    end

    def suspend_workflow(id)
      if @lock_provider.acquire_lock(id)
        begin
          workflow = @persistence.get_workflow_instance(id)
          if workflow.status == WorkflowStatus::RUNNABLE
            workflow.status = WorkflowStatus::SUSPENDED
            @persistence.persist_workflow(workflow)
            return true
          else
            return false
          end
        rescue Exception => e
          @logger.error("#{e.message} #{e.backtrace}")
        ensure
          @lock_provider.release_lock(id)
        end
      else
        false
      end
    end

    def resume_workflow(id)
      if @lock_provider.acquire_lock(id)
        begin
          workflow = @persistence.get_workflow_instance(id)
          if workflow.status == WorkflowStatus::SUSPENDED
            workflow.status = WorkflowStatus::RUNNABLE
            @persistence.persist_workflow(workflow)
            return true
          else
            return false
          end
        rescue Exception => e
          @logger.error("#{e.message} #{e.backtrace}")
        ensure
          @lock_provider.release_lock(id)
        end
      else
        false
      end
    end

    def terminate_workflow(id)
      if @lock_provider.acquire_lock(id)
        begin
          workflow = @persistence.get_workflow_instance(id)
          workflow.status = WorkflowStatus::TERMINATED
          @persistence.persist_workflow(workflow)
          return true
        rescue Exception => e
          @logger.error("#{e.message} #{e.backtrace}")
        ensure
          @lock_provider.release_lock(id)
        end
      else
        false
      end
    end

    private

    def run_workflows
      executor = WorkflowExecutor.new(@registry, @persistence, self, @logger)
      while not @is_shutdown
        begin
          workflow_id = @queue_provider.dequeue_for_processing
          if (workflow_id)

            if @lock_provider.acquire_lock(workflow_id)
              begin
              workflow = @persistence.get_workflow_instance(workflow_id)
              executor.execute(workflow)
              ensure
                @lock_provider.release_lock(workflow_id)
              end

              if workflow.next_execution
                if (workflow.status == WorkflowStatus::RUNNABLE) and (workflow.next_execution <= Time.new)
                  @queue_provider.queue_for_processing(workflow_id)
                end
              end
            else
              @logger.info("Workflow #{workflow_id} is locked")
            end
          else
            sleep(0.2) #no work
          end
        rescue Exception => e
          @logger.error("#{e.message} #{e.backtrace}")
        end
      end
    end

    def run_publications
      while not @is_shutdown
        begin
          pub = @queue_provider.dequeue_for_publish
          if (pub)
            if @lock_provider.acquire_lock(pub.workflow_id)
              begin
                workflow = @persistence.get_workflow_instance(pub.workflow_id)
                pointers = workflow.execution_pointers.select { |ep| ep.event_name == pub.event_name and ep.event_key == pub.event_key and not ep.event_published}
                pointers.each do |pointer|
                  pointer.event_data = pub.event_data
                  pointer.event_published = true
                  pointer.active = true
                end
                workflow.next_execution = Time.new
                @persistence.persist_workflow(workflow)
              rescue Exception => e
                @logger.error(e)
                @persistence.create_unpublished_event(pub)
              ensure
                @lock_provider.release_lock(pub.workflow_id)
                @queue_provider.queue_for_processing(pub.workflow_id)
              end

              if workflow.next_execution
                if (workflow.status == WorkflowStatus::RUNNABLE) and (workflow.next_execution <= Time.new)
                  @queue_provider.queue_for_processing(pub.workflow_id)
                end
              end
            else
              @logger.info("Workflow #{workflow_id} is locked")
            end
          else
            sleep(0.5) #no work
          end
        rescue Exception => e
          @logger.error("#{e.message} #{e.backtrace}")
        end
      end
    end

    def house_keeping
      while (!@is_shutdown)
        begin
          if (@poll_tick >= @poll_interval)
            @poll_tick = 0
            @logger.debug('Polling for runnable instances')
            @persistence.get_runnable_instances.each do |item|
              @queue_provider.queue_for_processing(item)
            end
          end
          @poll_tick += 1
          sleep(1)
        rescue Exception => e
          @logger.error("#{e.message} #{e.backtrace}")
        end
      end
    end

  end
end
