module Greenhouse
  module Tasks
    class AddProject
      include Task
        
      def prompt_for_project
        remote = nil
        print "Enter a git remote to add a project (leave blank to skip): "
        remote = STDIN.gets.chomp
        return if remote.empty?
        project = Projects::Project.new(remote.match(/([^\/]*)\.git/)[1], {remote: remote})
        
        if Projects::projects_file.projects.keys.include?(project.name) || Projects::projects_file.projects.values.map { |p| p['git'].downcase }.include?(project.repository.remote.downcase)
          puts "\e[31mCannot add project. Another project with the same name already exists.\e[0m"
          # TODO prompt to replace it?
          # would need to probably remove the project, remove procs from procfile, resync project, reconfig, etc.
          return
        end

        print "Enter a custom title for this project (leave blank for default) [#{project.title}]: "
        title = STDIN.gets.chomp
        project.title = title unless title.empty?

        print "Is this project a 'gem', rails 'application', rails 'engine' or other type of project (leave blank to skip)?: "
        type = STDIN.gets.chomp.downcase
        type = 'application' if type == 'app' # hacky :/
        unless type.empty?
          classname = "::Greenhouse::Projects::#{type.singularize.camelize}"
          if defined?(classname.constantize)
            project = classname.constantize.new(project.name, {remote: project.repository.remote, title: project.title})
            puts "Configuring #{project.title} as #{type == 'gem' ? 'a' : 'an'} #{type}"
          end
        end

        project
      end

      def add_project(project)
        Projects::projects_file.projects[project.name] = {'git' => project.repository.remote}
        Projects::projects_file.projects[project.name]['title'] = project.title unless project.title == project.name.camelize
        Projects::projects_file.projects[project.name]['type'] = project.class.name.underscore.split("/").last unless project.class == Projects::Project
        
        Projects::projects_file.write

        puts "Added \e[36m#{project.title}\e[0m to the ecosystem."
        project
      end

      def perform
        project = prompt_for_project
        return if project.nil?
        
        add_project(project)
      end
    end
  end
end
