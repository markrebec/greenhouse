require 'greenhouse/tasks/sync_project'

module Greenhouse
  module Commands
    class Launch
      include Command
      command_summary "Launch an application's processes using it's Procfile"
      project_arguments *Projects::applications.map(&:to_arg)
      valid_arguments *Projects::applications.map { |app| app.procfile.processes.select { |key,process| process.enabled? }.keys }.flatten

      class << self
        def usage
          puts <<USAGE
usage: #{::Greenhouse::CLI.command_name} #{command_name} <application> [<process> [<process> [...]]]

Applications:
#{project_arguments.to_help}
USAGE
        end
      end

      def run
        if arguments.empty?
          puts "Please provide the application you'd like to launch."
          puts
          usage
          return
        end

        appname = arguments.slice!(0).key
        app = Projects.applications.select { |app| app.name == appname }.first
        
        if app.nil?
          if Projects.projects.select { |proj| proj.name == appname }.first.nil?
            puts "The application '#{appname}' does not exist."
          else
            puts "The project '#{appname}' is not defined as an application."
          end
          puts
          usage
          return
        end

        if !app.exists?
          puts "The application directory #{app.path} does not exist. Are you sure you've initialized your ecosystem?"
          puts
          usage
          return
        end

        Signal.trap("HUP") { |signo| quit(signo) }
        Signal.trap("INT") { |signo| quit(signo) }
        Signal.trap("KILL") { |signo| quit(signo) }
        Signal.trap("TERM") { |signo| quit(signo) }
        
        begin
          @procs = {}
          Bundler.with_clean_env do
            app.chdir do
              if app.dotenv.exists?
                begin
                  # We have to unset these because foreman sets them by default, and Dotenv won't override a set value
                  %w(PORT RACK_ENV RAILS_ENV).each { |key| ENV[key] = nil }
                  require 'dotenv'
                  Dotenv.load!
                rescue
                  puts "Error parsing .env file for #{app.title.cyan}.".red
                  exit 1
                end
              else
                puts "Warning: No .env file found in #{app.title.cyan}!".yellow
                puts "Your application may not behave as expected without a .env file."
              end
              
              unless app.procfile.exists?
                puts "No Procfile found for #{app.title.cyan}".red
                exit 1
              end

              app.procfile.enabled.each do |key,process|
                next if arguments.length > 0 && !arguments.map(&:key).include?(key)
                @procs[key] = process
              end

              arguments.map(&:key).each { |key| puts "Skipping process not found in Procfile: #{key}" unless @procs.keys.include?(key) }
              @procs.each do |key,process|
                @procs[key] = fork do
                  exec process.command
                end
              end
              
              Process.wait
            end
          end
        rescue
          quit 1
        end

      end

      def quit(signo)
        @procs.each do |key,pid|
          begin
            Process.kill("KILL", pid)
          rescue # make sure to kill all children
          end
        end
        exit signo
      end

    end
  end
end
