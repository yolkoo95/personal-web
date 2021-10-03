#!/bin/bash
# Program:
#     Add scroll spy to notepage.
#     1. add section-nav class to sidebar toc
#     2. add section and id to each h2, h3 and h4 using stack
#     Shell must be executed in webApp directory since working dir
#     uses absolute path. important!
# Usage:
#     ./codehome/lib/addScrollSpy.sh category topicName

category=$1
notename=$2

# TODO: Add section-nav class to sidebar toc
sidebarTableURL="$(pwd)/codehome/templates/codehome/code/${category}/${notename}/${notename}-table.html"

gsed -i "1i <nav class=\"section-nav\">" ${sidebarTableURL}
gsed -i '$a </nav>' ${sidebarTableURL}

# TODO: Add section and id to h2, h3 and h4

contentURL="$(pwd)/codehome/templates/codehome/code/${category}/${notename}/${notename}.html"
cat ${contentURL} | grep -n '.*' | egrep '\<(h2|h3|h4).*\>' | grep -v 'tableofcontent' > ./inputfile.txt
inputfile='./inputfile.txt'

cat ./inputfile.txt

declare -a stack
declare -i top=0
# when insert <section> the line number will change, so we use shift
# to fix it
declare -i shiftLine=0
declare -i realLineNum=0

while IFS= read -r line
do
    ## get line number
    declare -i lineNum=$(echo ${line} | cut -d ':' -f 1)
    
    ## get id
    id=${line#*id=\"}
    id=${id%\">*}

    ## get title level
    level=${line#*<h}
    level=${level%\ id=*}
    declare -i levelNum=${level}

    # echo ${id}
    # echo ${lineNum}
    # echo ${levelNum}

    # pop and insert /section if stack is not empty levelNum <= stack[top] by while loop
    while [ ${top} -gt 0 ] && [ ${levelNum} -le ${stack[$top]} ]
    do
        # insert /section
        realLineNum=${lineNum}+${shiftLine}
        gsed -i "${realLineNum}i </section>" ${contentURL}
        shiftLine=${shiftLine}+1
        # pop
        top=${top}-1
    done

    # push and insert section before that row if stack is empty 
    # or levelNum > stack[top]
    if [ ${top} -eq 0 ] || [ ${levelNum} -gt ${stack[$top]} ]; then
        top=$top+1
        stack[$top]=${levelNum}
        
        # insert section
        realLineNum=${lineNum}+${shiftLine}
        gsed -i "${realLineNum}i <section\tid=\"${id}\">" ${contentURL}
        shiftLine=${shiftLine}+1
        # delete id in <h> tag
        gsed -i "s/\ id=\"${id}\"//g" ${contentURL}
    fi

done < "${inputfile}"

# clear stack, aka add </section> for h* in stack at the end
declare -i endRow=$(cat ${contentURL} | grep -n '.*' | grep 'EndMarkdown' | cut -d ':' -f 1)
while [ ${top} -gt 0 ]
do
    gsed -i "${endRow}i </section>" ${contentURL}
    top=${top}-1
done

rm -rf ./inputfile.txt