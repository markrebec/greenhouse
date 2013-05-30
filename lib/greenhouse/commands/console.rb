module Greenhouse
  module Commands
    class Console
      include Command
      command_summary "Run a rails console for one of your applications"
      project_arguments *Projects::applications.map(&:to_arg)
      
      class << self
        def usage
          puts <<USAGE
usage: #{::Greenhouse::CLI.command_name} #{command_name} <application> #{valid_arguments.to_s}

Applications:
#{project_arguments.to_help}
USAGE
        end
      end

      def run
        if arguments.empty? || arguments.all? { |arg| valid_arguments.map(&:keys).flatten.include?(arg) }
          puts "An application is required."
          puts
          print "    "
          usage
          return
        end

        app = Projects::applications.select { |application| arguments.map(&:key).include?(application.name) }.first
        if app.nil?
          puts "Application does not exist. Try adding it with `#{::Greenhouse::CLI::binary} add` and initializing it with `#{::Greenhouse::CLI::binary} init`"
          return
        end

        Bundler.with_clean_env do
          app.chdir do
            exec 'bundle exec rails console'
          end
        end
      end
    end
  end
end
