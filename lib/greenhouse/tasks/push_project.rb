module Greenhouse
  module Tasks
    class PushProject
      include Task
      include ProjectTask

      def perform(project)
        @project = project
        
        push
      end
    end
  end
end
