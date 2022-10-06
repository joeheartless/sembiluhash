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
	init=$(date +%s | cut -c 7-10) 
	if [[ "$1" == "-e" ]]; then
        	showtk=`echo $2$init | md5sum | cut -c 1-6`
		sleep 1
		touch .$showtk.key
        	echo $showtk $2 | base64 > .$showtk.key
		plintir=`cat .$showtk.key | tr '[a-z]' '[n-zd-n]'`
		echo $plintir > .$showtk.key
        	echo "[Hashed text:] $showtk"
	else
		if [[ "$1" == "-d" ]]; then
			unplintir=`cat .$2.key 2>/dev/null | tr '[n-zd-n]' '[a-z]'`
			echo $unplintir > .$2.key
			token=`cat .$2.key 2>/dev/null`
			check=`echo "$token" | base64 --decode 2>/dev/null | awk {'print $1'}`
			decu=`echo "$token" | base64 --decode 2>/dev/null | cut -d ' ' -f2-`
			if [ "$2" == "$check" ]; then
		                echo "[Plaintext:] $decu"
				rm -rf .$2.key
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
