#!/bin/bash
# Program:
#     Program helps move html produced by Mark2 into templates directory, and
#     changes img src, and add pre and next, and add scroll spy tools.
# Usage:
#     ./codehome/lib/markdown.sh category noteName
#     Example:
#     ./codehome/lib/markdown.sh leetcode 3Sum

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin/:~/bin
export PATH

category=$1 # to specify the location where the file will be saved
noteName=$2

web=$(pwd)
workingDirURL=${web}/codehome/templates/codehome/code/${category}/${noteName}
mv ~/Desktop/${noteName}.html ${workingDirURL}'/'${noteName}'.html'
touch ${workingDirURL}'/'${noteName}'-table.html'

htmlURL=${workingDirURL}'/'${noteName}'.html'
tableURL=${workingDirURL}'/'${noteName}'-table.html'

# TODO: remove addtional contents of tags except those of body
## remove the content before <body> tag
declare -i rowNumberForBodyTag=$(grep -n '<body>' ${htmlURL} | cut -d ':' -f 1)
gsed -i "1,${rowNumberForBodyTag}d" ${htmlURL}

## remove the content after END mark
declare -i rowNumberForLineAfterMark=$(grep -n 'EndMarkdown' ${htmlURL} | cut -d ':' -f 1)+1
declare -i rowNumberForLastLine=$(grep -n '</html>' ${htmlURL} | cut -d ':' -f 1)
gsed -i "${rowNumberForLineAfterMark},${rowNumberForLastLine}d" ${htmlURL}

## add {% load static %} to the file
gsed -i "1i {% load static %}" ${htmlURL}

## add {% static '
gsed -i "s/codehome\/src\/img/{% static 'codehome\/src\/img/g" ${htmlURL}

## add %}
gsed -i "s/.png/.png' %}/g" ${htmlURL}
gsed -i "s/.gif/.gif' %}/g" ${htmlURL}
gsed -i "s/.jpg/.jpg' %}/g" ${htmlURL}
gsed -i "s/.jpeg/.jpeg' %}/g" ${htmlURL}

# TODO: copy table of content to html-table file
declare -i firstLineOfTable=$(grep -n 'tableofcontents' ${htmlURL} | cut -d ':' -f 1)
declare -i lastLineOfTable=$(grep -n 'TableEndMark' ${htmlURL} | cut -d ':' -f 1)-1
gsed -n "${firstLineOfTable},${lastLineOfTable}p" ${htmlURL} >> ${tableURL}

# add pre and next
./codehome/lib/addPreAndNext.sh ${category} ${noteName}
./codehome/lib/addScrollSpy.sh ${category} ${noteName}