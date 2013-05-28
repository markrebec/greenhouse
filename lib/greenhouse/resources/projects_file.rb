require 'yaml'

module Greenhouse
  module Resources
    class ProjectsFile
      include FileResource
      
      def projects(refresh=false)
        return @projects unless refresh || @projects.nil? || @projects.empty?
        reload
      end

      def write
        open('w') do |pfile|
          #pfile.write @projects.to_yaml.gsub("!ruby/symbol ", ":").sub("---","").split("\n").map(&:rstrip).join("\n").strip
          @projects.each do |name,project|
            pfile.write "#{name}:\n"
            project.each do |key,val|
              pfile.write "  #{key}: #{val.to_s}\n"
            end
          end
        end
      end
      alias_method :save, :write

      def reload
        @projects = {}
        return @projects unless exists?
        @projects = YAML::load_file(path)
        @projects ||= {}
        @projects
      end

      def unlink
        super
        reload
      end

      def initialize(path)
        super
      end
    end
  end
end
