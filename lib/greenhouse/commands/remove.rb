module Greenhouse
  module Commands
    class Remove
      include Command
      command_summary "Purge a project and remove it from the ecosystem .projects file"
      project_arguments *Projects::projects.map(&:to_arg)
      
      class << self
        def usage
          puts <<USAGE
usage: #{::Greenhouse::CLI.command_name} #{command_name} <project>

Projects:
#{project_arguments.to_help}
USAGE
        end
      end
      
      def run
        if arguments.empty?
          puts "You must provide the name of the project you want to remove from your ecosystem."
          usage
          return
        end

        project = Projects::projects.select { |proj| proj.name == arguments[0].key }.first
        Tasks::PurgeProject.perform(project)
        Tasks::RemoveProject.perform(project)
      end
    end
  end
end
