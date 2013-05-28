module Greenhouse
  module Tasks
    class PullProject
      include Task
      include ProjectTask

      def perform(project)
        @project = project
        
        pull && bundle
      end
    end
  end
end
