module Greenhouse
  module Commands
    module Command
      def self.included(base)
        Commands::commands << base # Keep track of all commands

        base.send :include, Scripts::Script
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods
        def command_name(n=nil)
          @command_name = n unless n.nil?
          return @command_name unless @command_name.nil?
          self.name.underscore.split("/").last
        end
        
        def command_summary(summary=nil)
          @command_summary = summary unless summary.nil?
          @command_summary
        end
        alias_method :summary, :command_summary

        def usage
          puts "usage: #{::Greenhouse::CLI.command_name} #{command_name} #{valid_arguments.to_s}"
        end

        def run
          begin
            @command ||= new
            before_hooks.each { |block| @command.instance_eval(&block) }
            @command.run
            after_hooks.each { |block| @command.instance_eval(&block) }
          rescue Exception => e
            puts e.message
            @command.usage if e.is_a?(Scripts::InvalidArgument)
            return
          end
        end

        def append_after_hook(&block)
          @after_hooks ||= []
          @after_hooks << block
        end
        alias_method :after_hook, :append_after_hook

        def prepend_after_hook(&block)
          @after_hooks ||= []
          @after_hooks.unshift block
        end

        def after_hooks
          @after_hooks ||= []
          @after_hooks
        end

        def append_before_hook(&block)
          @before_hooks ||= []
          @before_hooks << block
        end
        alias_method :before_hook, :append_before_hook

        def prepend_before_hook(&block)
          @before_hooks ||= []
          @before_hooks.unshift block
        end

        def before_hooks
          @before_hooks ||= []
          @before_hooks
        end

        def to_arg
          Scripts::Argument.new(command_name, :summary => command_summary)
        end
      end

      module InstanceMethods
        %w(command_name command_summary usage).each do |method|
          define_method method do |*args|
            self.class.send method, *args
          end
        end
      end

    end
  end
end
