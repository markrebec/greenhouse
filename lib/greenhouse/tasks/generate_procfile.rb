module Greenhouse
  module Tasks
    class GenerateProcfile
      include Task

      def perform
        Projects::applications.each do |app|
          next unless app.procfile.exists?
          app.procfile.reload

          if app.procfile.processes.keys.length == 1
            Projects::procfile.processes[app.name] = "#{app.name}: greenhouse launch #{app.name} #{app.procfile.processes.keys.first}" unless Projects::procfile.processes.has_key?(app.name)
          else
            app.procfile.processes.keys.each { |process| Projects::procfile.processes["#{app.name}_#{process}"] = "#{app.name}_#{process}: greenhouse launch #{app.name} #{process}" unless Projects::procfile.processes.has_key?("#{app.name}_#{process}") }
          end
        end
        Projects::procfile.write
      end

    end
  end
end
