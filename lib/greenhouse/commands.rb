module Greenhouse
  module Commands
    def self.commands
      @commands ||= []
      @commands
    end

    def self.exists?(cmd)
      commands.map(&:command_name).include?(cmd.underscore.to_s)
    end

    def self.command(cmd)
      raise "Command does not exist: #{cmd}" unless exists?(cmd)
      commands.select { |command| command.command_name == cmd.underscore.to_s }.first
    end
  end
end

require 'greenhouse/commands/command'
require 'greenhouse/commands/new'
require 'greenhouse/commands/init'
require 'greenhouse/commands/configure'
require 'greenhouse/commands/add'
require 'greenhouse/commands/status'
require 'greenhouse/commands/launch'
require 'greenhouse/commands/start'
require 'greenhouse/commands/push'
require 'greenhouse/commands/pull'
require 'greenhouse/commands/sync'
require 'greenhouse/commands/purge'
require 'greenhouse/commands/remove'
require 'greenhouse/commands/help'
