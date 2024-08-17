NUSPAWN(1)

# NAME

nuspawn - systemd-nspawn helper

# SYNOPSIS

nuspawn [COMMAND [ARGS...]] [OPTIONS...]

# DESCRIPTION


# ENVIRONMENT

_$NUSPAWN_LOG_
A boolean. If false will supress all logs from the Nuspawn logger. Used from internal command calls but can also be used in exteral scripts integrating it.

_$NUSPAWN_DEBUG_
A boolean. If true enables the Nuspawn logger's "debug" call, which is used internally for debugging aspects of the commands, it is recommended to enable this when reporting issues

_$NO_COLOR_
A boolean. If true, disable all coloring in the logger messages for usage when not in a ansi-supported terminal environment, for example.

# EXAMPLES

Example 1. Pulling down a Debian image from nspawnhub

> nuspawn pull debian sid --name chungus

# SEE ALSO

_nuspawn_(5), _systemd-nspawn_(1), _machinectl_(1)

# AUTHORS

tulilirockz <tulilirockz@outlook.com>. 
You can find this project's source code in https://codeberg.org/tulilirockz/nuspawn
