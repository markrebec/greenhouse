module Greenhouse
  module Commands
    class Bundle
      include Command
      command_summary "Run bundler for one or all of your projects"
      valid_arguments Scripts::Argument.new("install", summary: "Install the gems specified by the Gemfile or Gemfile.lock"), Scripts::Argument.new("update", summary: "Update dependencies to their latest versions")
      project_arguments *Projects::projects.map(&:to_arg)
      
      class << self
        def usage
          puts <<USAGE
usage: #{::Greenhouse::CLI.command_name} #{command_name} <#{valid_arguments.map(&:key).join(", ")}> [<project>]

Arguments:
#{valid_arguments.to_help}

Projects:
#{project_arguments.to_help}
USAGE
        end
      end

      def bundle_all(cmd)
        Projects::projects.each do |project|
          Tasks::BundleProject.perform(project, cmd)
        end
      end

      def bundle_project(project, cmd)
        Tasks::BundleProject.perform(project, cmd)
      end

      def run
        cmd = arguments.select { |arg| valid_arguments.map(&:key).include?(arg.key) }.first
        if cmd.nil?
          puts "Please specify a bundle command."
          usage
          return
        end

        project = Projects::projects.select { |project| arguments.map(&:key).include?(project.name) }.first
        project.nil? ? bundle_all(cmd) : bundle_project(project, cmd)
      end
    end
  end
end
