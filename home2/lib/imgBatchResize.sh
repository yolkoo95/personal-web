#!/bin/bash
# Program:
# Program helps resize images in a directory
# directories to be processed must be in '/Users/Quminzhi/Documents/python/webApp/home2/static/home2/src/img/'
# Usage:
# ./home2/lib/imgBatchResize.sh originDIR destinationDIR width height
# Example:
# ./home2/lib/imgBatchResize.sh design portfolio 600 800
# PATH=/Users/Quminzhi/anaconda3/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin/:~/bin
# export PATH

ori=$1
des=$2
width=$3
height=$4

mkdir '/Users/Quminzhi/Documents/python/webApp/home2/static/home2/src/img/'${des}

for img in $(ls '/Users/Quminzhi/Documents/python/webApp/home2/static/home2/src/img/'${ori})
do
  python3 /Users/Quminzhi/Documents/python/webApp/home2/lib/imgResize.py ${ori}'/'${img} ${des}'/'${img} ${width} ${height}
done
