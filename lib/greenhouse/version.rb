module Greenhouse
  VERSION = "0.0.7"
end

__END__
0.0.7:
* Simple bundler command to run install/update for a single or all projects
* Refactor `status` command, renamed --verbose flag to --git, only fetching git remotes with --git flag
* Cleanup for script arguments
* Dummy `specs` command as a placeholder to be overridden by extensions

0.0.6:
* Don't downcase git repos (duh)
* Add console command to easily run rails console for rails apps
* Some minor internal cleanup

0.0.5:
* Fix for pushing projects by ensuring each branch is pushed individually

0.0.4:
* Fixed bug with new not referencing the active binary
* Fixed a couple off by one errors in resource files
* Printing version in binary usage output

0.0.3:
* Ability to set the CLI binary name
* Broke out Forth Rail specific stuff into it's own binary `forthrail`

0.0.2:
* Improved command arguments (multiple keys, summaries, etc.)
* Separated project arguments from standard arguments
* Allow passing a project to commands like push, pull, sync, purge, status, etc.
* Added -v/--verbose flag for status command to output repository details (uncommitted files, out of sync branches, etc.)
* Improved resource file handling for Procfiles and .ignore files
* Added -a/--all flag for purge command to control whether to purge the entire ecosystem or just the project directories

0.0.1:
* Refactoring, improving and gemming Greenhouse
* Started pulling out Forth Rail specific functionality into a abstracted monkeypatches and mixins
