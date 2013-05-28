module Greenhouse
  module Tasks
    def self.tasks
      @tasks ||= []
      @tasks
    end
  end
end

require 'greenhouse/tasks/task'
require 'greenhouse/tasks/project_task'
require 'greenhouse/tasks/project_status'
require 'greenhouse/tasks/add_project'
require 'greenhouse/tasks/push_project'
require 'greenhouse/tasks/pull_project'
require 'greenhouse/tasks/sync_project'
require 'greenhouse/tasks/purge_project'
require 'greenhouse/tasks/remove_project'
require 'greenhouse/tasks/generate_procfile'
require 'greenhouse/tasks/remove_greenhouse_files'
