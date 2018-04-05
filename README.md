# Scripts

A collection of general purpose scripts.

_**Remember! Always read a script before executing it.**_


### multi_tail.sh

This is a bash script that generates and executes a multitail command with several -l arguments.

The commands are a combination of ssh and tail so that you can tail logs remotely by sshing through a jumpbox.

All the logs are aggregated per box to reduce the number of open terminals.

For this reason, every log line is prefixed with the filename it originates from, using awk.

Notes:

1. I would NOT recommend using anything like this in production. Use a dedicated software. That's why they exist out there.
2. The script is not efficient as it performs multiple ssh commands to identify the logs before it actually starts tailing.
3. I am not a security expert so always be aware when executing remote commands!
4. Trim the script to your needs. i.e if you don't need to ssh through a jumpbox just remove it.

### Authors

Chris Liontos