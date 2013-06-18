module Greenhouse
  module Tasks
    class SyncProject
      include Task
      include ProjectTask

      def perform(project, force=false)
        @project = project

        if @project.exists?
          pull(force) && bundle
          push(force)
        else
          clone && bundle
        end
      end
    end
  end
end
