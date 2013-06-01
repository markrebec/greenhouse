module Greenhouse
  module Tasks
    class BundleProject
      include Task
      include ProjectTask
        
      def perform(project, cmd='install')
        @project = project
        bundle(cmd)
      end
    end
  end
end
