module Greenhouse
  module Commands
    class Add
      include Command
      command_summary "Add a project to the ecosystem"
      
      def add_another?
        another = nil
        while !['', 'n','no'].include?(another) do
          puts "The following projects are configured in your ecosystem: "
          #Projects::projects.each do |project|
          #  puts
          #  Tasks::ProjectStatus.perform(project)
          #end
          Projects.projects.each do |project|
            puts "    #{project.title.cyan}"
          end
          puts
          print "Would you like to add another project? ([y]es/[N]o): "
          another = STDIN.gets.chomp.downcase
          Tasks::AddProject.perform if ['y','yes'].include?(another)
        end
      end

      def run
        Tasks::AddProject.perform

        add_another?
      end
    end
  end
end
