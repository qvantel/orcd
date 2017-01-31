#!/bin/bash

case "$1" in
"ssh")
	k=$(cp .sshgitmodules .gitmodules 2>&1)

	if [ -z "$k" ]
	then
		git submodule sync
		echo "Successfully made ssh the pull strategy"
	else 
		echo "$k"
	fi
;;
"https")
	k=$(cp .httpsgitmodules .gitmodules 2>&1)
	if [ -z "$k" ]
	then
		git submodule sync
		echo "Successfully made https the pull strategy"
	else 
		echo "$k"
	fi
;;
*)
	echo -e "Usage: \n	ssh\n	https"
;;
esac

