module Greenhouse
  module Commands
    class New
      include Command

      command_summary "Setup a new Greenhouse projects directory"
      validate_arguments false

      class << self
        def usage
          puts "usage: #{::Greenhouse::CLI::binary} #{command_name} <name> #{valid_arguments.to_s}"
        end
      end

      def run
        if arguments.length == 0
          usage
          exit 1
        end

        projects_directory = arguments.first.key
        if File.exists?(projects_directory)
          STDERR.puts "Directory already exists: #{projects_directory}"
          STDERR.puts "You can try running `#{::Greenhouse::CLI::binary} init` from inside the directory."
          exit 1
        end

        begin
          FileUtils.mkdir(projects_directory)
        rescue
          STDERR.puts "Unable to create projects directory: #{projects_directory}"
          exit 1
        end
        
        exec "cd #{projects_directory}; #{::Greenhouse::CLI::binary} init"
      end
    end
  end
end
