function log --argument-names level --description "Utility to create a 'loglike' formatted msg"
    # The log output is meant only for interactive sessions
    # status is-interactive; or return 0

    # TODO: <kpbaks 2023-07-19 10:20:18> add a subcommand to show all log messages for the current session e.g. `log history` or `log show`
    # TODO: <kpbaks 2023-07-14 09:18:05> add support for logging to a file
    # TODO: <kpbaks 2023-07-14 09:18:05> add support for logging to a file and stdout/stderr
    # TODO: <kpbaks 2023-07-14 09:18:05> add support for reading from stdin, do it in streaming fashion, and log each line

    # Set the default log severity level to info, if it is not already set.
    set --query LOG_SEVERITY; or set -g LOG_SEVERITY info

    set -l options (fish_opt --short h --long help)
    set -a options (fish_opt --short f --long file)
    set -a options (fish_opt --short t --long timestamp --optional-val) # The optional-val is the format string for the time format. It uses `date`
    if not argparse $options -- $argv
        return 1
    end

    if set --query _flag_help
        set -l usage "$(set_color --bold)Utility to create a 'loglike' formatted msg$(set_color normal)

$(set_color yellow)Usage:$(set_color normal) $(set_color blue)$(status current-command)$(set_color normal) [options] level msg...

$(set_color yellow)Arguments:$(set_color normal)
	$(set_color green)level$(set_color normal)    Log level { debug | info | warn | error | fatal }
	$(set_color green)msg$(set_color normal)      Log message

$(set_color yellow)Options:$(set_color normal)
	$(set_color green)-h$(set_color normal), $(set_color green)--help$(set_color normal)      Show this help message and exit
	$(set_color green)-f$(set_color normal), $(set_color green)--file$(set_color normal)      Log to file
	$(set_color green)-t$(set_color normal), $(set_color green)--timestamp$(set_color normal) Log with timestamp"

        echo $usage
        return 0
    end

    set -l argc (count $argv)
    switch $argc
        case 0
            log error "Missing log level and message"
            log --help
            return 1
        case 1
            log error "Missing log message"
            log --help
            return 1
    end

    # msgs computed after parsing the arguments with argparse
    # because argparse will remove the arguments it recognizes
    set -l msgs $argv[2..-1]

    # NOTE: The ordering of this list matters!
    # If a levels index in the list precedes another, then it
    # is considered less severe than the other.
    set -l log_severity_levels debug info warn error fatal
    set -l log_severity_colors blue green yellow red magenta

    set level (string lower $level)

    if not contains -- $level $log_severity_levels
        log error "Invalid log level: $level" "Valid log levels are: $log_severity_levels"
        return 1
    end

    set -l index_of_level (contains -i -- $level $log_severity_levels)
    set -l index_of_log_severity (contains -i -- $LOG_SEVERITY $log_severity_levels)

    # if the log level is less severe than the log severity level, then
    # do not log the message.
    if test $index_of_level -lt $index_of_log_severity
        return 0
    end
    set -l log_severity_color $log_severity_colors[$index_of_level]

    set -l reset (set_color normal)

    # create a log output similar to the one used by the
    # pluto.jl package.
    # here is an example of the output:
    #> [ Info: Loading...
    #> [ Info: Listening on: 127.0.0.1:1234, thread id: 1
    #> ┌ Info:
    #> └ Go to http://localhost:1234/?secret=YgffWLft in your browser to start writing ~ have fun!

    # When the log output is a single line, the log level is
    # "[ <level>: <msg>"
    # When the log output spans multiple lines, the first line
    # is prefixed with the log level, and the rest of the lines
    # are indented to match the log level prefix.
    # For example:
    # ┌ <level>: <msg[0]>
    # │ <msg[1]>
    # │ <msg[n]>
    # └ <msg[-1]>
    set -l msgs_count (count $msgs)
    switch $msgs_count
        case 1
            # log output is a single line
            # [ <level>: <msg>
            printf "%s[ %s:%s %s\n" \
                (set_color $log_severity_color --bold) \
                (string upper $level) \
                $reset \
                $msgs[1]
        case 2
            # log output spans multiple lines
            # ┌ <level>: <msg[0]>
            # └ <msg[1]>
            printf "%s┌ %s:%s %s\n" \
                (set_color $log_severity_color --bold) \
                (string upper $level) \
                $reset \
                $msgs[1]
            printf "%s└%s %s\n" \
                (set_color $log_severity_color --bold) \
                $reset \
                $msgs[2]

        case "*"
            # log output spans multiple lines
            # ┌ <level>: <msg[0]>
            # │ <msg[1]>
            # │ <msg[n]>
            # └ <msg[-1]>
            printf "%s┌ %s:%s %s\n" \
                (set_color $log_severity_color --bold) \
                (string upper $level) \
                $reset \
                $msgs[1]
            # 1 is subtracted from the msgs_count because `seq $n $n` will
            # return $n, instead of an empty list. Where as `seq $n $n-1` will
            # return an empty list.
            for i in (seq 2 (math "$msgs_count - 1"))
                printf "%s│%s %s\n" \
                    (set_color $log_severity_color --bold) \
                    $reset \
                    $msgs[$i]
            end
            printf "%s└%s %s\n" \
                (set_color $log_severity_color --bold) \
                $reset \
                $msgs[-1]
    end
end
