set -l C complete --command log
$C -f # disable file completion

set -l log_levels debug info warn error fatal

$C -n "not __fish_seen_subcommand_from $log_levels" -a "$log_levels"
