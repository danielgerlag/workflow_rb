module WorkflowRb

  class WorkflowRegistry

    def initialize
      @registry = []
    end

    def get_definition(id, version)
      @registry.each do |item|
        if (item.id == id) and (item.version == version)
          return item
        end
      end

    end

    def register_workflow(definition)
      @registry << definition
    end

  end

end