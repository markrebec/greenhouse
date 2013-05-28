module Greenhouse
  module Commands
    class Help
      include Command

      command_summary "Provides help for greenhouse usage"

      valid_arguments *Commands::commands.map(&:to_arg)
      validate_arguments false

      def self.usage
        puts <<USAGE
usage: #{::Greenhouse::CLI.command_name} #{command_name} <command>
      
The available greenhouse commands are:
USAGE
        
        Commands::commands.select { |cmd| cmd != self}.each do |cmd|
          print "   %-#{Commands::commands.sort { |a,b| a.command_name.length <=> b.command_name.length }.last.command_name.length + 2}s" % cmd.command_name
          puts "# #{cmd.command_summary}"
        end
      end

      def run
        if arguments.empty?
          usage
          return
        end

        begin
          cmd = Commands::commands.select { |cmd| cmd.command_name == arguments.first.key.underscore }.first
          raise if cmd.nil?

          puts cmd.command_summary
          puts
          print "    "
          cmd.usage
        rescue
          puts "Invalid Command: #{arguments.first.key.underscore}"
          usage
        end
      end
    end
  end
end
