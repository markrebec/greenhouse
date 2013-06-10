module Greenhouse
  module Tasks
    class RemoveProject
      include Task
      include ProjectTask

      def perform(project)
        @project = project
        puts "Removing #{@project.title} from your .projects file...".yellow
        Projects::projects_file.projects.delete_if { |name,project| name == @project.name }
        Projects::projects_file.write
      end
    end
  end
end
