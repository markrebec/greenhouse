module Greenhouse
  module Projects
    class Collection < Array
      protected

      def initialize(*args)
        super
        
        # DEPRECATED - moving this to Projects itself
        each do |project|
          meth = project.class.name.pluralize.underscore.split("/").last.to_sym
          next if respond_to?(meth)
          
          self.class.instance_eval do
            define_method meth do
              select { |proj| proj.class.name.pluralize.underscore.split("/").last.to_sym == meth }
            end
          end
        end
      end
    end
  end
end
