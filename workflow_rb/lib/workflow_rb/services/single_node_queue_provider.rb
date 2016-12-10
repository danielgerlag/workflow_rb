require 'thread'

module WorkflowRb
  class SingleNodeQueueProvider

    def initialize
      @process_queue = Queue.new
      @publish_queue = Queue.new
    end

    def queue_for_processing(id)
      @process_queue << id
    end

    def dequeue_for_processing
      begin
        return @process_queue.pop(true)
      rescue
        return nil
      end
    end

    def queue_for_publish(pub)
      @publish_queue << pub
    end

    def dequeue_for_publish
      begin
        return @publish_queue.pop(true)
      rescue
        return nil
      end
    end

  end
end
