module Greenhouse
  VERSION = "0.0.4"
end

__END__
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
