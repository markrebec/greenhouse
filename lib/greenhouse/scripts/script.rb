module Greenhouse
  module Scripts
    module Script
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods
        def self.extended(base)
        end
        
        def run
          @script ||= new
          raise "You must define a `run` method for your script." unless @script.respond_to?(:run)
          @script.run
        end

        def validate_arguments(val=nil)
          @validate_arguments = val
        end

        def validate_arguments?
          @validate_arguments = true if @validate_arguments.nil?
          @validate_arguments
        end

        def valid_argument(arg)
          @valid_args ||= Arguments.new
          if arg.is_a?(Argument)
            @valid_args << arg
          elsif arg.is_a?(Hash)
            @valid_args << Argument.new(arg.keys.first.to_s, arg.values.first)
          elsif arg.is_a?(Array)
            @valid_args << Argument.new(arg[0].to_s, (arg.length > 1 ? arg[1] : []))
          else
            @valid_args << Argument.new(arg.to_s)
          end
          @valid_args.last
        end

        def valid_arguments(*args)
          @valid_args ||= Arguments.new
          return @valid_args if args.empty?
          
          args.each { |arg| valid_argument(arg) }
          @valid_args
        end
        
        def project_argument(proj)
          @valid_projects ||= Arguments.new
          if proj.is_a?(Argument)
            @valid_projects << proj
          elsif proj.is_a?(Hash)
            @valid_projects << Argument.new(proj.keys.first.to_s, proj.values.first)
          elsif proj.is_a?(Array)
            @valid_projects << Argument.new(proj[0].to_s, (proj.length > 1 ? proj[1] : []))
          else
            @valid_projects << Argument.new(proj.to_s)
          end
          @valid_projects.last
        end

        def project_arguments(*projs)
          @valid_projects ||= Arguments.new
          return @valid_projects if projs.empty?
          
          projs.each { |proj| project_argument(proj) }
          @valid_projects
        end

        def arguments(*args)
          add_arguments(*args)
        end

        def user_arguments
          arguments
        end

        def set_arguments(*args)
          @arguments = Arguments.new
          add_arguments(*args)
        end

        def add_arguments(*args)
          @arguments ||= Arguments.new
          args.each_with_index do |arg,a|
            argk, argv = *parse_arg(arg)
            
            if !argument_flag?(arg) && !valid_argument?(argk) && (a > 0 && argument_flag?(args[a-1]))
              @arguments.last.value = arg
              next
            end

            raise InvalidArgument, "Invalid Argument: #{arg}" if validate_arguments? && !valid_argument?(argk)
            @arguments << argument_object(argk)
            @arguments.last.value = argv unless argv.empty?
          end
          @arguments
        end

        def parse_arg(arg)
          arga = arg.split("=")
          [arga.slice!(0), arga.join("=")]
        end
        
        def valid_argument?(key)
          valid_arguments.clone.concat(project_arguments).map(&:keys).flatten.include?(key)
        end

        def argument_flag?(arg)
          arg.match(/\A(-)+[a-z0-9\-]=?.*\Z/i)
        end

        def argument_object(key)
          valid_arguments.clone.concat(project_arguments).select { |varg| varg.keys.include?(key) }.first || Argument.new(key)
        end
      end

      module InstanceMethods
        %w(arguments valid_arguments project_arguments).each do |method|
          define_method method do |*args|
            self.class.send method, *args
          end
        end
      end
    
    end
  end
end
