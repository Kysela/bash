#!/usr/bin/bash

#variables with prefix CT_ are default globals
CT_SCRIPT_GENERATOR_VERSION="1.0";
#Set to true for debugging
CT_SCRIPT_DEBUG_MODE="true";
CT_SCRIPT_LOCAL_PATH="$0";
CT_DT_VENDOR="omni";

usage() {
	echo -e "\Pterodon Recovery device tree build engine V${CT_SCRIPT_GENERATOR_VERSION}" 
	echo -e "\Created by ATG Droid @xda" 
	echo -e "\nUsage:\n $CT_SCRIPT_LOCAL_PATH [options..]\n"
	echo -e "Options:\n"
	echo -e "-c | --codename <codename> - set a device code name for device tree\n"
	echo -e "-i | --info <device tree path> - get a bunch of informations from device tree by its path\n"
	echo -e "-m | --maintainer <maintainer name> - set maintainer of this device tree\n"
	echo -e "-u | --update <folder path> - update device tree by path to folder\n"
	echo -e "-h | --help - Display usage instructions.\n" 
	exit 0;
}

print() {
echo -e "$@" >&2;
}

contains() {
case $1 in
*"$2"*) 
return 0; ;;
*)
return 1; ;;
esac
}

startswith() {
case $1 in
"$2"*) 
return 0; ;;
*)
return 1; ;;
esac
}

endswith() {
case $1 in
*"$2") 
return 0; ;;
*)
return 1; ;;
esac
}

parse_args() {
parse_args_get_complete_counter() {
if [ "$parse_args_long_arguments" ] && [ "$parse_args_argument_position" ]; then
return $((parse_args_argument_position - parse_args_long_arguments))
elif [ "$parse_args_argument_position" ]; then
return $parse_args_argument_position;
else
return 0;
fi
}
if [ -z "$1" ]; then
parse_args_argument_position=0;
parse_args_long_arguments=0;
return 1;
fi;
if [ -z "$parse_args_long_arguments" ]; then
for argument in "$@"; do
(( parse_args_long_arguments++ ))
done
parse_args_long_arguments=$(( $parse_args_long_arguments - $# ));
fi
local tmp_arg_pos;
local require_arg_value=false;
parse_args_value="";
parse_args_key="";
if [ "$parse_args_argument_position" ]; then
tmp_arg_pos=$parse_args_argument_position;
else
tmp_arg_pos=0;
fi;
for argument in "$@"; do
if ((tmp_arg_pos > 0)); then
(( tmp_arg_pos-- ))
continue;
fi;
(( parse_args_argument_position++ ))
local arg_size=${#argument}
if (( arg_size == 2 )); then
if [[ "$argument" == "-"* ]]; then
if $require_arg_value; then
(( parse_args_argument_position-- ))
return 0;
fi
parse_args_key="${argument#?}";
parse_args_get_complete_counter;
if [ "$#" -eq $? ]; then
parse_args_value="";
return 0;
fi
require_arg_value=true;
continue;
fi
elif (( arg_size >= 3 )) && [[ "$argument" == "--"* ]]; then
if $require_arg_value; then
(( parse_args_argument_position-- ))
return 0;
fi
parse_args_key="${argument#??}";
parse_args_get_complete_counter;
if [ "$#" -eq $? ]; then
parse_args_value="";
return 0;
fi
require_arg_value=true;
continue;
fi
if $require_arg_value; then
if [ "$parse_args_value" ]; then
parse_args_value="$parse_args_value $argument";
else
parse_args_value="$argument";
fi
parse_args_get_complete_counter;
if [ "$#" -eq $? ]; then
return 0;
fi
continue;
fi
done;
parse_args_argument_position=0;
parse_args_long_arguments=0;
return 1;
}

parse_args_get_full_key() {
local parse_args_key_size=${#parse_args_key}
local full_argument;
if (( parse_args_key_size == 1 )); then
full_argument="-${parse_args_key}";
elif (( parse_args_key_size > 1 )); then
full_argument="--${parse_args_key}";
fi
if (( parse_args_key_size >= 1 )); then
   echo "\"$full_argument\"";
else
   echo "$parse_args_key";
fi
}

parse_args_ensure_argument() {
if [ -z "$parse_args_value" ]; then
   print "Please specify value for `parse_args_get_full_key`\nUse --help if needed.";
   exit 1;
 fi
}

while parse_args "$@"; do
case $parse_args_key in
		c | codename)
		    parse_args_ensure_argument
			CT_DEVICE_CODENAME="$parse_args_value";
			;;
		i | info)
		    parse_args_ensure_argument
			CT_INFO_PATH="$parse_args_value";
			;;
	    m | maintainer)
		    parse_args_ensure_argument;
			CT_MAINTAINER="$parse_args_value";
			;;
		u | update)
		    parse_args_ensure_argument;
			CT_UPDATE_PATH="$parse_args_value";
			;;
		h | help)
			usage
			;;
		 *)
			print "Unsupported argument: `parse_args_get_full_key`\nUse --help if needed.";
			exit 1;
			;;
	esac
done

