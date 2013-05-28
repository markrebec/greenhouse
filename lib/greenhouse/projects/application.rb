module Greenhouse
  module Projects
    class Application < Project
      attr_reader :dotenv, :procfile

      def configured?
        @dotenv.exists?
      end

      protected

      def initialize(name, args={})
        super
        @procfile = Resources::Procfile.new("#{path}/Procfile")
        @dotenv = Resources::DotenvFile.new("#{path}/.env")
      end
    end
  end
end
