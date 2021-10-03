#!/bin/bash
# Program:
#     Program helps add table into markdown file:
#     The script must be executed in Webapp working directory
# Usage:
#     ./codehome/lib/addTableToMarkdownForNewMarked2.sh [category] [topic]
#     eg:
#     ./codehome/lib/addTableToMarkdownForNewMarked2.sh cpp basic

category=$1
topic=$2

relURL='/codehome/static/codehome/src/'${category}'/'${topic}'.md'
webAppURL=$(pwd)
mdURL=${webAppURL}${relURL}

echo ${mdURL}

# save raw text into tmp.txt and get rid of ##### or more and Table of Contents
grep '^##\{1,3\}' ${mdURL} | grep -v '^##\{4,6\}' | grep -v 'Table of Contents'> /tmp/raw.txt

# translate '##' into '-', '###' into '    -' ...
# noting that \t does not mean a tab token in gsed, printf '\t' works
cat /tmp/raw.txt | gsed "s/^####/$(printf '\t')$(printf '\t')-/g" | gsed "s/^###/$(printf '\t')-/g" | gsed "s/^##/-/g" > /tmp/processed.txt

# add referrence with python
# at last, insert frontTable into markdown file
touch /tmp/frontTable.txt
python3 codehome/lib/addTableToMarkdownForNewMarked2.py && echo -e "\n<TableEndMark>" >> /tmp/frontTable.txt && gsed -i "/Table of Contents/r /tmp/frontTable.txt" ${mdURL} || echo -e "Failure in process frontTable.txt\n"

# clear buffer
rm -rf /tmp/raw.txt
rm -rf /tmp/processed.txt
cat /tmp/frontTable.txt
rm -rf /tmp/frontTable.txt