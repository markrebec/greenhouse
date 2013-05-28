require 'greenhouse/tasks/sync_project'

module Greenhouse
  module Commands
    class Init
      include Command
      command_summary "Initialize the current directory as a Greenhouse projects directory"

      # Make sure .ignore defaults are set before init
      before_hook do
        unless Projects::ignore_file.exists?
          Projects::ignore_file.open('w') do |f|
            f.write <<IGNORE
# Add any files here that are checked into your git repository, but are commonly edited
# or changed when working in a dev environment.
#
# Files will be ignored across all projects with `git --assume-unchanged FILE` and all
# paths are relative to the project directory.
#
# If you wish to commit changes to a file, you may run `git --no-assume-unchanged FILE`
# to unignore it temporarily, then run `git --assume-unchanged FILE` again when you're
# done.
#
# You may also create a .ignore file within each project directory if you'd like, and
# the files listed there will only be ignored for that project. Of course anything
# defined in a project .gitignore file is permanently ignored by git and does not
# need to be accounted for here.

# Ignore Gemfile so you can point to local ecosystem paths during development without
# worry of inadvertently committing your Gemfile.
Gemfile

# Ignore Gemfile.lock (mainly for applications) so that you don't inadvertently commit
# any development/local gems to the bundle.
Gemfile.lock

# Ignore your application database config since different devs may be using different
# setups.
config/database.yml

# Ignore tmp dir just in case
tmp/
IGNORE
          end
          Projects::ignore_file.reload
        end
      end
      
      after_hook do
        puts
        puts "New ecosystem initialized in \e[36m#{Projects::path}\e[0m"
      end

      class << self
        def usage
          puts "usage: #{::Greenhouse::CLI.command_name} #{command_name} #{valid_arguments.to_s}"
        end
      end

      def add_another?
        another = nil
        while !['', 'n','no'].include?(another) do
          puts "The following projects will be initialized in your ecosystem:"
          Projects.projects.each do |project|
            puts "    \e[36m#{project.title}\e[0m"
          end
          puts
          print "Would you like to add another project before initializing? ([y]es/[N]o): "
          another = STDIN.gets.chomp.downcase
          Tasks::AddProject.perform if ['y','yes'].include?(another)
        end
      end

      def run
        while Projects.projects.empty? do
          puts "You must define at least one project for your ecosystem.\n"
          Tasks::AddProject.perform
        end
        
        # Prompt to add another project
        add_another?
        
        # Sync all projects
        Projects.projects.each do |project|
          Tasks::SyncProject.perform(project)
        end

        # Create a Procfile that uses `greenhouse launch` to launch the app's processes
        Tasks::GenerateProcfile.perform
      end
    end
  end
end
