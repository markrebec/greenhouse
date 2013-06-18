module Greenhouse
  module Tasks
    class PullProject
      include Task
      include ProjectTask

      def perform(project, force=false)
        @project = project
        
        pull(force) && bundle
      end
    end
  end
end
