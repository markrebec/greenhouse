module Greenhouse
  module Tasks
    class PushProject
      include Task
      include ProjectTask

      def perform(project, force=false)
        @project = project
        
        push force
      end
    end
  end
end
