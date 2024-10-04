#!/bin/bash
if [[ "$1" == "-h" ]]; then 
	echo "HELP OPTION"
	echo "----------SEMBILU HASH-----------"
	echo "AUTHOR"
	echo "   Written by Joe Heartless"
	echo ""
	echo "[OPTION]"
	echo "-e = encoding {string} "	
	echo "-d = decoding {hash}"
        echo ""
	echo "example:"
	echo "sembiluhash [OPTION] [ARGS]..."
	echo "sembiluhash -e foo"
	echo "sembiluhash -d b44arr"
	echo "just that, just like that."
        echo "++++++++++++++eof++++++++++++++++"
else
	init=$(shuf -i 1000-9999 -n 1) 
	if [[ "$1" == "-e" ]]; then
        	showtk=`echo $2$init | md5sum | cut -c 1-6`
		sleep 1
		touch .$showtk.key
        	echo $showtk ${@} | base64 > .$showtk.key
		plintir=`cat .$showtk.key | tr '[a-z]' '[n-zd-n]'`
		echo $plintir > .$showtk.key
        	echo "[Hashed text:] ${showtk^^}"
	else
		if [[ "$1" == "-d" ]]; then
			low=${2,,}
			unplintir=`cat .$low.key 2>/dev/null | tr '[n-zd-n]' '[a-z]'`
			echo $unplintir > .$low.key
			token=`cat .$low.key 2>/dev/null`
			check=`echo "$token" | base64 --decode 2>/dev/null | awk {'print $1'}`
			decu=`echo "$token" | base64 --decode 2>/dev/null | cut -d ' ' -f2-`
			if [ "${2,,}" == "$check" ]; then
		                echo "[Plaintext:] $decu"
				rm -rf .$low.key
		        else
        		        sleep 1
                		echo "[hash unrecognized!]"
        		fi
        		sleep 1

		else 
			echo "Invalid option! -h for option."
		fi
	fi
fi
