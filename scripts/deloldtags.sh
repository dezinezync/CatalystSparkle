#!/bin/bash

TAGS=$(git tag -l | sort -V)
DELETED_TAGS=()

for value in $TAGS
do
    IFS='/' read -ra ADDR <<< "$value"
	for i in "${ADDR[@]}"; do
	    
		if [ $i -gt 45 ]
		then
			echo $(git tag -d $value)
			DELETED_TAGS+=("$value")
		fi

	done

done

echo $(git push --delete origin "${DELETED_TAGS[@]}")
