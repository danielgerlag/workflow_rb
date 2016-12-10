require 'thread'

module WorkflowRb
  class SingleNodeLockProvider

    def initialize
      @semaphore = Mutex.new
      @named_locks = []
    end

    def acquire_lock(id)
      @semaphore.synchronize do
        if @named_locks.include?(id)
          return false
        end
        @named_locks << id
        return true
      end
    end

    def release_lock(id)
      @semaphore.synchronize do
        @named_locks.delete(id)
      end
    end

  end
end
