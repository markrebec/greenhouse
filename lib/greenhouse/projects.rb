require 'yaml'
require 'git'
require 'greenhouse/projects/repository'
require 'greenhouse/projects/collection'
require 'greenhouse/projects/project'
require 'greenhouse/projects/engine'
require 'greenhouse/projects/application'
require 'greenhouse/projects/gem'

module Greenhouse
  module Projects
    @@path = nil
    @@procfile = nil
    @@ignore_file = nil
    @@projects_file = nil
    @@dotenv = nil
    @@projects = nil

    def self.method_missing(meth, *args)
      if Project.subclasses.map { |subclass| subclass.name.pluralize.underscore.split("/").last.to_sym }.include?(meth.to_sym)
        projects.select { |proj| proj.class.name.pluralize.underscore.split("/").last.to_sym == meth.to_sym }
      else
        super
      end
    end

    def self.projects
      @@projects = Collection.new
      return @@projects unless projects_file.exists?
      
      projects_file.projects.each do |name,project|
        type = (project.has_key?('type') ? project['type'] : 'project')
        projargs = project.merge({:remote => (project['remote'] || project['git'])})
        classname = "Greenhouse::Projects::#{type.singularize.camelize}"
        @@projects << (defined?(classname.constantize) ? classname.constantize.new(name, projargs) : Greenhouse::Projects::Project.new(name, projargs))
      end
      @@projects
    end

    # Attempts to look for and returns the path of the root projects directory
    #
    # Looks up the tree from the current directory, currently checking for a .projects
    # file (this might change in the future).
    #
    # If no projects path is found, the current directory is returned.
    def self.path
      return @@path unless @@path.nil?
      dir = Dir.pwd
      while dir != "" do
        if File.exists?("#{dir}/.projects")
          @@path = dir
          return @@path
        end
        dir = dir.gsub(/\/[^\/]*\Z/,'')
      end
      @@path = Dir.pwd # if we haven't found a .projects file, this must be where they want to work
      @@path
    end

    def self.ignore_file
      return @@ignore_file unless @@ignore_file.nil?
      @@ignore_file = Resources::IgnoreFile.new("#{path}/.ignore")
    end

    def self.projects_file
      return @@projects_file unless @@projects_file.nil?
      @@projects_file = Resources::ProjectsFile.new("#{path}/.projects")
    end

    def self.procfile
      return @@procfile unless @@procfile.nil?
      @@procfile = Resources::Procfile.new("#{path}/Procfile")
    end

    def self.dotenv
      return @@dotenv unless @@dotenv.nil?
      @@dotenv = Resources::DotenvFile.new("#{path}/.env")
    end

    def self.ignored
      return [] unless ignore_file.exists?
      ignore_file.ignored
    end
  
  end
end
