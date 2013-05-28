module Greenhouse
  module Tasks
    class SyncProject
      include Task
      include ProjectTask

      def perform(project)
        @project = project

        if @project.exists?
          pull && bundle
          push
        else
          clone && bundle
        end
      end
    end
  end
end
