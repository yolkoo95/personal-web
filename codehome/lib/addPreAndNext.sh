#!/bin/bash
# Program:
#     Program helps add pre and next at the end of notepage
# 
#     Shell must be executed in webApp directory since working dir
#     uses absolute path. important!
# Usage:
#     ./codehome/lib/addPreAndNext.sh category topicName
#     eg:
#     ./codehome/lib/addPreAndNext.sh tutorial git 
#     ./codehome/lib/addPreAndNext.sh cpp basic 
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin/:~/bin
export PATH

category=$1
noteName=$2
fileURL=codehome/templates/codehome/code/${category}/${noteName}/${noteName}.html
codehomeURL=codehome/templates/codehome/codehome.html

# catch link, grep -n '.*' for add line number
cat "$(pwd)/${codehomeURL}" | grep "${category}" | grep "href" | grep -n ".*" | grep -B 1 -A 1 "${noteName}" > ./tmp.txt

curURL=$(cat tmp.txt | grep "${noteName}")
curRawURL=${curURL}
curNum=$(echo ${curURL} | cut -d ':' -f 1)
curURL=${curURL#${curNum}*href=\"}
curName=${curURL} # backup
curURL=${curURL%\"*ong>}
curName=${curName#\{%*\">}
curName=${curName%%<*ong>}

preURL=$(cat tmp.txt | head -n 1)
# if cur is the first article
if [ "${preURL}" == "${curRawURL}" ]; then
    preNum=${curNum}
    preName=""
    preURL=""
else
    preNum=$(echo ${preURL} | cut -d ':' -f 1)
    preURL=${preURL#${preNum}*href=\"}
    preName=${preURL} # backup
    preURL=${preURL%\"*ong>}
    preName=${preName#\{%*\">}
    preName=${preName%%<*ong>}
fi

# if cur is the last article
nextURL=$(cat tmp.txt | tail -n 1)
if [ "${nextURL}" == "${curRawURL}" ]; then
    nextNum=${curNum}
    nextName=""
    nextURL=""
else
    nextNum=$(echo ${nextURL} | cut -d ':' -f 1)
    nextURL=${nextURL#${nextNum}*href=\"}
    nextName=${nextURL} # backup
    nextURL=${nextURL%\"*ong>}
    nextName=${nextName#\{%*\">}
    nextName=${nextName%%<*ong>}
fi

rm -rf ./tmp.txt

# get the line number to be inserted
declare -i row=$(grep -n 'EndMarkdown' ./${fileURL} | cut -d ':' -f 1)

# insert at target location
## if there is only one article
if [ "${curNum}" == "1" ] && [ "${nextNum}" == "1" ]; then
    gsed -i "${row}a \ \n \
        <!-- pre and next --> \n \
        <div class=\"row\"> \n \
            <div class=\"col-md-12 prenextstyle\"> \n \
                <ul class=\"pagination justify-content-center\"> \n \
                    <li><span class=\"button\">${curNum}. ${curName}</span></li> \n \
                </ul> \n \
            </div> \n \
        </div>
    " ${fileURL}
fi

## if it is the first article
if [ "${curNum}" == "1" ]; then
    gsed -i "${row}a \ \n \
        <!-- pre and next --> \n \
        <div class=\"row\"> \n \
            <div class=\"col-md-12 prenextstyle\"> \n \
                <ul class=\"pagination justify-content-center\"> \n \
                    <li><span class=\"button\">${curNum}. ${curName}</span></li> \n \
                    <li><a href=\"${nextURL}\" class=\"button primary icon solid fa-forward\">Next: ${nextNum}. ${nextName}</a></li> \n \
                </ul> \n \
            </div> \n \
        </div>
    " ${fileURL}
# if it is the last article
elif [ "${curNum}" == "${nextNum}" ]; then
    gsed -i "${row}a \ \n \
        <!-- pre and next --> \n \
        <div class=\"row\"> \n \
            <div class=\"col-md-12 prenextstyle\"> \n \
                <ul class=\"pagination justify-content-center\"> \n \
                    <li><a href=\"${preURL}\" class=\"button primary icon solid fa-backward\">Back: ${preNum}. ${preName}</a></li> \n \
                    <li><span class=\"button\">${curNum}. ${curName}</span></li> \n \
                </ul> \n \
            </div> \n \
        </div>
    " ${fileURL}
else
    gsed -i "${row}a \ \n \
        <!-- pre and next --> \n \
        <div class=\"row\"> \n \
            <div class=\"col-md-12 prenextstyle\"> \n \
                <ul class=\"pagination justify-content-center\"> \n \
                    <li><a href=\"${preURL}\" class=\"button primary icon solid fa-backward\">Back: ${preNum}. ${preName}</a></li> \n \
                    <li><span class=\"button\">${curNum}. ${curName}</span></li> \n \
                    <li><a href=\"${nextURL}\" class=\"button primary icon solid fa-forward\">Next: ${nextNum}. ${nextName}</a></li> \n \
                </ul> \n \
            </div> \n \
        </div>
    " ${fileURL}   
fi