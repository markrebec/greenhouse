module Greenhouse
  module Tasks
    class PurgeProject
      include Task
      include ProjectTask

      def perform(project, force=false)
        @project = project
        purge(force)
      end
    end
  end
end
