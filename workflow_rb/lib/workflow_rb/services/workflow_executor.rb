require 'workflow_rb/services/workflow_registry'
require 'workflow_rb/models/execution_pointer'
require 'workflow_rb/models/workflow_instance'
require 'workflow_rb/models/step_execution_context'
require 'workflow_rb/models/subscription_step'

module WorkflowRb


  class WorkflowExecutor


    public
      def initialize(registry, persistence, host, logger)
        @registry = registry
        @persistence = persistence
        @host = host
        @logger = logger
      end

      def execute(workflow)
        @logger.debug("Executing workflow #{workflow.id}")
        exe_pointers = workflow.execution_pointers.select { |x| x.active }
        definition = @registry.get_definition(workflow.definition_id, workflow.version)
        if not definition
          raise Exception "Workflow definition #{workflow.definition_id}"
        end

        exe_pointers.each do |pointer|
          step = definition.steps.select { |x| x.id == pointer.step_id }.first
          if not step
            raise Exception "Step #{pointer.step_id} not found in definition"
          end

          if (step.kind_of?(SubscriptionStep)) and (not pointer.event_published)
            pointer.event_name = step.event_name
            pointer.event_key = step.event_key
            pointer.active = false
            @host.subscribe_event(workflow.id, step.id, step.event_name, step.event_key)
            next
          end


          if not pointer.start_time
            pointer.start_time = Time.new
          end

          execution_context = StepExecutionContext.new
          execution_context.persistence_data = pointer.persistence_data
          execution_context.workflow = workflow
          execution_context.step = step


          if step.body.kind_of?(Proc)
            body_class = Class.new(StepBody) do
              def initialize(body)
                @body = body
              end
              def run(context)
                @body.call(context)
              end
            end
            body_obj = body_class.new(step.body)
          else
            if step.body <= StepBody
              body_obj = step.body.new
            end
          end

          if not body_obj
            raise "Cannot construct step body #{step.body}"
          end

          step.inputs.each do |input|
            io_value = input.value.call(workflow.data)
            body_obj.send("#{input.property}=", io_value)
          end

          if (body_obj.kind_of?(SubscriptionStepBody)) and (pointer.event_published)
            body_obj.event_data = pointer.event_data
          end

          result = body_obj.run(execution_context)

          if (result.proceed)

            step.outputs.each do |output|
              io_value = output.value.call(body_obj)
              workflow.data.send("#{output.property}=", io_value)
            end

            pointer.active = false
            pointer.end_time = Time.new
            fork_counter = 1
            pointer.path_terminator = true

            step.outcomes.select {|x| x.value == result.outcome_value}.each do |outcome|
              new_pointer = ExecutionPointer.new
              new_pointer.active = true
              new_pointer.step_id = outcome.next_step
              new_pointer.concurrent_fork = fork_counter * pointer.concurrent_fork
              workflow.execution_pointers << new_pointer
              pointer.path_terminator = false
              fork_counter += 1
            end
          else
            pointer.persistence_data = result.persistence_data
            pointer.sleep_until = result.sleep_until
          end

        end
        determine_next_execution(workflow)
        @persistence.persist_workflow(workflow)
      end

    private
      def determine_next_execution(workflow)
        workflow.next_execution = nil
        workflow.execution_pointers.select {|item| item.active }.each do |pointer|
          if not pointer.sleep_until
            workflow.next_execution = Time.new
            return
          end
          workflow.next_execution = [pointer.sleep_until, workflow.next_execution ? workflow.next_execution : pointer.sleep_until].min
        end

        if not workflow.next_execution
          forks = 1
          terminals = 0
          workflow.execution_pointers.each do |pointer|
            forks = [forks, pointer.concurrent_fork].max
            if pointer.path_terminator
              terminals += 1
            end
          end
          if forks <= terminals
            workflow.status = WorkflowStatus::COMPLETE
            workflow.complete_time = Time.new
          end
        end
      end


  end

end
