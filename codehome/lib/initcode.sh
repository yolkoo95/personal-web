#!/bin/bash
# Program:
# Program helps initiate code files:
#     1. topicName.md in static directory, you must finish problem description in md file.
#     2. cpp.html or other-language.html in templates directory
#     Shell must be executed in webApp directory. important!
#     3. update pre and next of last note
# Usage:
#     ./codehome/lib/initcode.sh category topicName description [notepage]
#     eg:
#     ./codehome/lib/initcode.sh tutorial git 'foo'
#     ./codehome/lib/initcode.sh cpp basic 'blabla'
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin/:~/bin
export PATH

category=$1
topicName=$2
description=$3
type='notepage'

# make directory in templates
relPath='/codehome/templates/codehome/code'
urlforFiles=$(pwd)${relPath}
mkdir -p ${urlforFiles}'/'${category}'/'${topicName}

# make directory in static and touch problem.md
relPath='/codehome/static/codehome/src'
urlforFiles=$(pwd)${relPath}
mkdir -p ${urlforFiles}'/'${category}
touch ${urlforFiles}'/'${category}'/'${topicName}'.md'

# set toc and EndMark in md files
cat codehome/lib/markdownTemplate.md >> ${urlforFiles}'/'${category}'/'${topicName}'.md'

# add related code into codehome.html
## get row number of flag in </ul> tag, noting that ${category}'End' is predefined flag
## for each category in codehome.html
declare -i row=$(grep -n ${category}'End' codehome/templates/codehome/codehome.html | cut -d ':' -f 1)

## get color from python script
color=$(python3 codehome/lib/color.py)

## capitalized the first character
topicNameNoCap=${topicName}
topicName=$(echo ${topicName:0:1} | tr '[a-z]' '[A-Z]')${topicName:1}

## insert template into codehome.html
relPath='/codehome/templates/codehome/codehome.html'
urlforFiles=$(pwd)${relPath}
gsed -i "${row}i \ \n \
         <!-- ${topicName} -->\n \
         <li>\n \
           <div class=\"media text-muted pt-3\">\n \
             <svg\n \
               class=\"bd-placeholder-img mr-2 rounded\"\n \
               width=\"32\"\n \
               height=\"32\"\n \
               xmlns=\"http://www.w3.org/2000/svg\"\n \
               preserveAspectRatio=\"xMidYMid slice\"\n \
               focusable=\"false\"\n \
               role=\"img\"\n \
               aria-label=\"3Sum: 32x32\"\n \
             >\n \
               <title>${topicName}</title>\n \
               <rect width=\"100%\" height=\"100%\" fill=\"${color}\" />\n \
               <text x=\"50%\" y=\"50%\" fill=\"${color}\" dy=\".3em\">32x32</text>\n \
             </svg>\n \
             <p\n \
               class=\"media-body pb-3 mb-0 small lh-125 border-bottom border-gray\"\n \
             >\n \
               <strong class=\"d-block text-gray-dark\"><a href=\"{% url '${type}' '${category}' '${topicNameNoCap}' %}\">${topicName}</a></strong>\n \
                 <!-- description -->\n \
                 ${description}\n \
             </p>\n \
           </div>\n \
         </li>
" ${urlforFiles}

## update next and pre of last article
codehomeURL=codehome/templates/codehome/codehome.html
lastNote=$(cat "$(pwd)/${codehomeURL}" | grep "${category}" | grep "href" \
| tail -n 2 | head -n 1)
lastNote=${lastNote##*\ \'} # cut prefix
lastNote=${lastNote%\'\ *}  # cut suffix

### clear old next and pre
lastnoteURL="./codehome/templates/codehome/code/${category}/${lastNote}/${lastNote}.html"
declare -i row=$(cat ${lastnoteURL} | grep -n '.*' | grep 'pre and next' | cut -d ':' -f 1)
declare -i end=${row}+9
gsed -i "${row},${end}d" ${lastnoteURL}

### update new next and pre
./codehome/lib/addPreAndNext.sh ${category} ${lastNote}