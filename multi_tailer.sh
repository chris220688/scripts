#!/bin/sh

#
# This is a bash script that generates and executes a multitail command
# with several -l arguments. The commands are a combination of ssh and
# tail so that you can tail logs remotely by sshing through a jumpbox.
#
# All the logs are aggregated per box to reduce the number of open
# terminals. For this reason, every log line is prefixed with the
# filename it originates from, using awk.
# 
# You can tail remotely multiple logs in multiple boxes as long as:
#
#         1. multitail program installed
#         2. Your ssh key is in the remote boxes
#         3. You have added the log patterns in get_log_pattern
#
# Example usage:
#
#         ./multi_tailer.sh "box1 app_1 app_3" "box2 app_2"
#
# The output command will look something like:
#
#         multitail -l "ssh -t jumpbox ssh username@box1.domain 'tail -f /log_dir/app_1/app_1.log.20180405_14 /log_dir/app_3/app_3.log.20180405_14'" \
#                   -l "ssh -t jumpbox ssh username@box2.domain 'tail -f /log_dir/app_2/app_2.log.20180405_14'"
#         
# Arguments:
#
#         Space separated lists inside double quotes
#         Each quoted list contains the box as the first
#         element and a number of applications following
#

# SSH username
username="your_username"
# SSH domain
domain="your_domain"
# Jump box
jump_box="your_jumpbox"
# Log directory
log_dir="/your_log_dir"

#
# Function that returns the log pattern of an application.
# Make sure you add one log pattern for every application
# you need to tail.
#
# Example usage:
#           get_log_pattern app_1
#
# Arguments:
#           app: A string indicating the name of the application
#
get_log_pattern () {

	app=$1

	log_pattern=""

	# Work out the log_pattern
	case "$app" in
		app_1)
			log_pattern="${log_dir}/app_1/app_1.log*";;
		app_3)
			log_pattern="${log_dir}/app_3/app_3.log*";;
		app_2)
			log_pattern="${log_dir}/app_2/app_2.log*";;
		*)
			exit 1
	esac

	echo "$log_pattern"
}

#
# Function that performs an ssh to a box and returns
# a list of the last modified logs per application
#
# Example usage:
#           get_logs box "app_1 app_2"
#
# Arguments:
#           box:  A string indicating the name of the box
#           apps: A list of applications inside double quotes
#
get_logs () {

	box=$1
	apps=$2

	# A list of log files
	logs=""

	# For each app
	for app in $apps
	do
		# Get the log_pattern of the application	
		log_pattern=$(get_log_pattern $app)

		# Work out the last modified log that matches the log_pattern
		log=`ssh -q -t ${jump_box} ssh -q ${username}@${box}.${domain} "ls -p -t ${log_pattern} | head -1"`

		# Append the log file to the list of logs
		logs="${logs} $log"
	done

	# Remove \r carriage returns
	logs=`echo "${logs}" | tr '\r' ' '`

	# Return the logs list
	echo "$logs"
}

#
# Function that generates a -l multitail command for each one of the boxes
#
# Example usage:
#
#           generate_box_command box_1 "app_1 app_3"
#
# Arguments:
#           box:  A string indicating the name of the box
#           apps: A list of applications inside double quotes
#
generate_box_command () {

	box=$1
	apps=$2

	# Final command to execute
	cmd=""

	# Get a list of the last modified logs of each application
	logs=$(get_logs $box "$apps")

	# Generate a -l multitail argument for the box
	# The awk command will append the filenames to each line in the logs
	cmd="${cmd} -l "\""ssh -t ${jump_box} ssh ${username}@${box}.${domain} 'tail -f ${logs} | awk '\''/^==> / {a=substr(\\\$0, 5, length-8); next} {print a\\\":\\\"\\\$0}'\'' '"\"""

	# Return the command
	echo "$cmd"
}

#
# Function that prints a usage description (-h or --help)
#
usage () {
	echo "usage: multi_tailer [\"box app app ...\" \"box app app ...\"]"
	echo "Where:"
	echo "      Every list is inside double quotes and contains"
	echo "      a box name followed by a list of apllications"
}



if [[ $1 == "-h" || $1 == "--help" ]]
then
	usage
	exit 0
fi

# Initialise the final multitail command
multitail_command="multitail"

# Each set contains a box and a list of applications
# For each set generate a -l multitail command
for set in "$@"
do
	set -- $set

	# First element is the box
	box=$1

	shift

	# The rest of the elements is a list of applications
	apps=$@

	# Generate a -l multitail command for the box
	cmd=$(generate_box_command $box "$apps")

	# Append the -l arguments to the multitail command
	multitail_command="$multitail_command $cmd"
done

# Execute the final command
eval "$multitail_command"
