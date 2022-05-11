# Options library for bash, v1.6
#
# https://github.com/davvil/shellOptions
#
# Copyright 2009 David Vilar
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser Public License as published by
# the Free Software Foundation, version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# options.bash and options.zsh
#     by David Vilar
#
# This is a small library for handling command line options in bash and zsh. It is
# inspired by the optparse python library. An example usage is
#
#     addOption -n --number required help="Specify some number" dest=myNumber
#     addOption -a --aux flagTrue help="Another option, but without dest"
#     addOption -o help="Option with default" default="a b" dest=otherO
#     parseOptions "$@"
#
# This example defines the options -n/--number, -a/--aux and -o. -n sets the
# variable $myNumber and is required by the script to run. -a sets the $aux
# variable to true when given (it does not require arguments). -o sets the
# variable $otherO, but if not specified on the command line, it defaults to "a b".
# Additionaly the option -h/--help is automatically generated and produces this
# output:
#
#     usage: example.bash [options]
#
#     Options:
#
#        -n,--number                Specify some number
#        -a,--aux                   Another option, but without dest
#        -o                         Option with default
#        -h,--help                  Show this help message
#
# To use the library in your own script, copy it somewhere and include it in your
# script (.bash or .zsh depending on which shell you use):
#
# . options.bash
#
# New options are added with the addOption command. It scans its arguments for
# those beginning with a dash to get the short and long option syntax (one of them
# can be omitted). Additionally you can give these additional commands:
#
# + dest=VAR
#   Sets the destination of the variable. If not given, it defaults to
#   the long option name (see option --aux in the example above)
# + action=COMMAND
#   Calls command if the option is specified in the command line (usually this is
#   used for calling functions in the script, but it is not limited to it)
# + default=VALUE
#   Sets the default value for the option, if not given in the command line
# + required
#   Specifies that the option is required [I know, this is a contradiction of
#   terms ;-)]. The script will abort with an error message if the option is not
#   given in the command line
# + help=MESSAGE
#   Specifies the help message to be written in the output with the -h options
# + flagTrue/flagFalse
#   Specifies that the option is a boolean. flagTrue sets the default value to
#   false and turns it to true if the option is given in the command line. flagFalse
#   works the other way round. Note that you can use such variable directly in bash
#   constructs like if clauses, while loops, etc:
#
#       if $var; then
#               echo "var is set
#       fi
#
# + configFile
#   This option makes the script read an external file. Normally this is used as a
#   config file, where the values of variables are set, e.g.
#
#       input=file.in
#       output=file.out
#       iterations=3
#
#   Note that the file is included directly in bash, no fancy parsing is done.
#   This means among other things that no whitespace is allowed around = signs and
#   that command can be executed from within the "config file". Use with caution.
# + dontShow
#   Do not show the option in the output of -h. Useful if some options are thought
#   to be used only when calling the script from other script.
#
# Once you have defined the options for your script, use the command
#     parseOptions "$@"
# to parse the command line and set the appropriate variables. Additional command
# line arguments are stored in the $optArgv[] array, with $optArgc storing the
# number of actual arguments.
#
# The library follows the usual convention of supporting -- to separate options
# from command line arguments, e.g. in the call
#     ./example.sh -n 3 -a -- -b aaa
# the arguments are "-b" and "aaa".
#
# This library has been extensively used in the Jane statistical machine
# translation toolkit (http://www.hltpr.rwth-aachen.de/jane)
#
 
#function debug { $* > /dev/stderr; }
function debug { true; }
 
function setUsage() {
    __programUsage__="$*"
}
 
declare -a __shortOptions__
declare -a __longOptions__
declare -a __optionDests__
declare -a __optionActions__
declare -a __optionDefaults__
declare -a __optionRequired__
declare -a __optionFlag__
declare -a __optionHelp__
declare -a __dontShow__
 
declare -a optArgv
optArgc=0
__nOptions__=0;
__programUsage__="usage: `basename $0` [options]\n\nOptions:\n"
 
function addOption() {
    debug echo "Option #${__nOptions__}:"
    # These arrays must have the same length for the __searchInArray__ function to work
    __longOptions__[$__nOptions__]="___not_a_valid_option___"
    __shortOptions__[$__nOptions__]="___not_a_valid_option___"
    local i
    for i in "$@"; do
        if [[ "${i:0:2}" = -- ]]; then
            __longOptions__[$__nOptions__]=${i:2}
            debug echo -e "\tRegistered long option ${i:2}"
 
        elif [[ "${i:0:1}" = - ]]; then
            __shortOptions__[$__nOptions__]=${i:1}
            debug echo -e "\tRegistered short option ${i:1}"
 
        elif [[ "${i:0:5}" = dest= ]]; then
            __optionDests__[$__nOptions__]=${i:5}
            debug echo -e "\tOption dest is ${i:5}"
 
        elif [[ "${i:0:7}" = action= ]]; then
            __optionActions__[$__nOptions__]=${i:7}
            debug echo -e "\tOption action is ${i:7}"
 
        elif [[ "${i:0:8}" = default= ]]; then
            __optionDefaults__[$__nOptions__]="${i:8}"
            debug echo -e "\tOption default is ${i:8}"
 
        elif [[ "$i" = required ]]; then
            __optionRequired__[$__nOptions__]=1
            debug echo -e "\tOption required"
 
        elif [[ "${i:0:5}" = help= ]]; then
            __optionHelp__[$__nOptions__]=${i:5}
            debug echo -e "\tRegistered help \"${i:5}\""
 
        elif [[ "$i" = flagTrue ]]; then
            __optionFlag__[$__nOptions__]=1
            debug echo -e "\tOption is flag (true)"
 
        elif [[ "$i" = flagFalse ]]; then
            __optionFlag__[$__nOptions__]=0
            debug echo -e "\tOption is flag (false)"
 
        elif [[ "$i" = configFile ]]; then
            __configFile__=$__nOptions__
            debug echo -e "\tOption is a config file"
 
        elif [[ "$i" = dontShow ]]; then
            __dontShow__[$__nOptions__]=1
            debug echo -e "\tDon't show this option"
 
        else
            echo "Unknown parameter to registerOption: $i" > /dev/stderr
            exit 1
        fi
    done
 
    if [[ "${__optionDests__[$__nOptions__]}" = "" && "${__longOptions__[$__nOptions__]}" != "" ]]; then
        __optionDests__[$__nOptions__]=${__longOptions__[$__nOptions__]}
    fi
 
    ((++__nOptions__))
}
 
function __searchInArray__() {
    debug echo -e "\t__searchInArray__ $*"
    local searchFor=$1
    shift
    local i=0;
    while [[ "$1" != "" ]]; do
        if [ $1 = $searchFor ]; then
            debug echo -e "\tFound as option $i"
            echo $i
            return
        fi
        ((++i))
        shift
    done
}
 
function __searchOption__() {
    local pos
    if [[ "${1:0:2}" = -- ]]; then
        debug echo -e "\tIt's a long option"
        pos=`__searchInArray__ ${1:2} ${__longOptions__[*]}`
    elif [[ "${1:0:1}" = -  ]]; then
        debug echo -e "\tIt's a short option"
        pos=`__searchInArray__ ${1:1} ${__shortOptions__[*]}`
    fi
    debug echo -e "\tResulting pos: $pos"
    echo $pos
}
 
function __readConfig__() {
    if [[ "$__configFile__" != "" ]]; then
        local options=("$@")
        local i=0;
        while (($i < ${#options[*]})); do
            if [[ "${options[$i]}" = -${__shortOptions__[$__configFile__]} ||
                  "${options[$i]}" = "--${__longOptions__[$__configFile__]}" ]]; then
                . ${options[$((i+1))]}
                break
            fi
            if [[ "${options[$i]}" = "--" ]]; then
                break
            fi
            ((++i))
        done
    fi
}
 
function parseOptions() {
    # Set default values
    local i=0;
    local flag;
    while (($i < $__nOptions__)); do
        default="${__optionDefaults__[$i]}"
        if [[ "$default" != "" ]]; then
            eval ${__optionDests__[$i]}=\"$default\"
        elif [[ "${__optionFlag__[$i]}" != "" ]]; then
            flag=${__optionFlag__[$i]}
            if [[ $flag = 1 ]]; then
                eval ${__optionDests__[$i]}=false
            else
                eval ${__optionDests__[$i]}=true
            fi
        fi
        ((++i))
    done
 
    # Read a config file (if we have one)
    __readConfig__ "$@"
 
    # Parse the options
    local minusMinusSeen=false
    while (($# > 0)); do
        if ! $minusMinusSeen; then
            debug echo "Searching option $1"
            if [[ "$1" = "--" ]]; then
                minusMinusSeen=true
            else
                local pos=`__searchOption__ "$1"`
                if [[ "$pos" == "" ]]; then
                    if [[ "${1:0:1}" = "-" ]]; then
                        echo "Error: Unknown option $1" > /dev/stderr
                        exit 1
                    else
                        optArgv[optArgc]="$1"
                        ((++optArgc))
                    fi
                else
                    local dest=${__optionDests__[$pos]}
                    if [[ "$dest" != "" ]]; then
                        debug echo -e "\tOption has a dest"
                        local isFlag=${__optionFlag__[$pos]}
                        if [[ "$isFlag" != "" ]]; then
                            debug echo -e "\tOption $i is a flag"
                            if [[ $isFlag = 1 ]]; then
                                eval $dest=true
                            else
                                eval $dest=false
                            fi
 
                        else # It's not a flag
                            shift
                            value="$1"
                            eval $dest=\"$value\"
                        fi
                    fi
 
                    local action=${__optionActions__[$pos]}
                    if [[ "$action" != "" ]]; then
                        debug echo -e "\tOption has an Action"
                        eval ${__optionActions__[$pos]}
                    fi
                fi
            fi
        else # minusMinusSeen
            optArgv[optArgc]="$1"
            ((++optArgc))
        fi
 
        shift
    done
 
    # Check for required values
    i=0
    local -a missingOptions
    while (($i < $__nOptions__)); do
        debug echo "Checking option $i, required=\"${__optionRequired__[$i]}\", destValue=${!__optionDests__[$i]}"
        if [[ "${__optionRequired__[$i]}" != "" && "${!__optionDests__[$i]}" = "" ]]; then
            debug echo -e "\tMissing option"
            local optionName=${__shortOptions__[$i]}
            if [[ "$optionName" = "___not_a_valid_option___" ]]; then
                optionName="--"${__longOptions__[$i]}
            else
                optionName="-"$optionName
            fi
            missingOptions[${#missingOptions[*]}]=$optionName
        fi
        ((++i))
    done
    if (( ${#missingOptions[*]} > 0 )); then
        echo -n "Error: following mandatory options are missing: ${missingOptions[0]}" > /dev/stderr
        i=1
        while (($i < ${#missingOptions[*]})); do
            echo -n ",${missingOptions[$i]}" > /dev/stderr
            ((++i))
        done
        echo "" > /dev/stderr
        exit 1
    fi
}
 
function __printOptionHelp__() {
    local i=$1
    if [[ "${__dontShow__[$i]}" = 1 ]]; then
        return
    fi
    local optionId=${__shortOptions__[$i]}
    if [[ $optionId != ___not_a_valid_option___ ]]; then
        optionId=-$optionId
        if [[ ${__longOptions__[$i]} != ___not_a_valid_option___ ]]; then
            optionId=$optionId","
        fi
    else
        optionId=""
    fi
    if [[ ${__longOptions__[$i]} != ___not_a_valid_option___ ]]; then
        optionId=${optionId}"--"${__longOptions__[$i]}
    fi
    optionId="   "$optionId
    local firstIndentLine
    if ((${#optionId} < 30)); then
        echo -n "$optionId"
        local c
        for c in `seq ${#optionId} 29`; do
            echo -n " "
        done
        firstIndentLine=2
    else
        echo "$optionId"
        firstIndentLine=1
    fi
    local thirtySpaces="                              "
    echo "${__optionHelp__[$i]}" | fmt -w 50 | sed "$firstIndentLine,\$s/^/$thirtySpaces/"
}
 
function __showHelp__() {
    echo -e "$__programUsage__"
    local i=1 # -h is the first option
    while (($i < $__nOptions__)); do
        __printOptionHelp__ $i
        ((++i))
    done
    __printOptionHelp__ 0 # -h
    exit 0
}
 
addOption -h --help action=__showHelp__ help="Show this help message"
