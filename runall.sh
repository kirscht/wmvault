#!/usr/bin/env bash

set -ev

. usr/local/bin/functions.sh

echo "SORTEDPODLIST $(SORTEDPODLIST)"

for item in $(SORTEDPODLIST)
do

    RUNONPOD "$(echo ${item} | awk -F ':' '{print $1}')" "${@}"

done