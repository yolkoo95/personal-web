# Added reference number
# Read table content from /tmp/tmp.txt and solve it.
# Usage:
# python3 codehome/lib/addTableToMarkdown.py

with open('/tmp/processed.txt', 'r') as f:
    lines = f.readlines()
    frontTable = open('/tmp/frontTable.txt', 'w')
    for line in lines:
        # get rid of '\n'
        line = line.rstrip()

        # for frontTable
        index = line.find('-')
        # set format of reference, get rid of blankspace and '''
        reference = line[index+2:].lower().replace(' ', '').replace('\'', '');
        newLine = f"{line[0:index+2]}[{line[index+2:]}](#{reference})\n"
        frontTable.write(newLine)

    frontTable.close()
