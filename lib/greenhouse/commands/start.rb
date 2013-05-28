module Greenhouse
  module Commands
    class Start
      include Command

      command_summary "Startup the entire ecosystem of apps using your Procfile (aliases `foreman start`)"

      class << self
        def usage
          puts "usage: #{::Greenhouse::CLI.command_name} #{command_name} #{valid_arguments.to_s}"
        end
      end

      def run
        Dir.chdir(Projects::path) do
          exec 'foreman start'
        end
      end
    end
  end
end
