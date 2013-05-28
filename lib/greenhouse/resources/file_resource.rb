module Greenhouse
  module Resources
    module FileResource
      def self.included(base)
        base.send :include, InstanceMethods
      end

      module ClassMethods
      end

      module InstanceMethods
        def self.included(base)
          base.send :attr_reader, :path
        end

        def exists?
          File.exists?(path)
        end

        def open(mode, &block)
          File.open(path, mode, &block)
        end

        def lines(reload=false)
          @lines = nil if reload
          @lines ||= [] unless exists?
          @lines ||= File.read(path).split("\n")
          @lines
        end

        def read(&block)
          lines(true).each_with_index(&block)
        end

        def unlink
          File.unlink(path) if exists?
        end

        def chdir(&block)
          Dir.chdir(File.expand_path("../", path), &block)
        end

        def initialize(path)
          @path = File.expand_path(path)
        end
      end

    end
  end
end
