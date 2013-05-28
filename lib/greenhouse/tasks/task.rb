module Greenhouse
  module Tasks
    module Task
      def self.included(base)
        Tasks::tasks << base # Keep track of all tasks
        
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods
        def perform(*args)
          @task = new
          @task.before(*args) if @task.respond_to?(:before)
          @task.perform(*args)
          @task.after(*args) if @task.respond_to?(:after)
          @task
        end
      end

      module InstanceMethods
      end
    end
  end
end
