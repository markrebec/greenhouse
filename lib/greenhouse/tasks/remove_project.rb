module Greenhouse
  module Tasks
    class RemoveProject
      include Task
      include ProjectTask

      def perform(project)
        @project = project
        puts "\e[33mRemoving #{@project.title} from your .projects file...\e[0m"
        Projects::projects_file.projects.delete_if { |name,project| name == @project.name }
        Projects::projects_file.write
      end
    end
  end
end
