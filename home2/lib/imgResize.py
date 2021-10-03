# This program will resize a photo
# Usage:
# python3 imgResize.py origin destination width height
# Example:
# python3 imgResize.py design/design4.jpg portfolio/design4.jpg 600 800
from PIL import Image
import sys

origin = sys.argv[1]
destination = sys.argv[2]
width = int(sys.argv[3])
height = int(sys.argv[4])

img = Image.open('./home2/static/home2/src/img/' + origin)
img = img.resize((width, height), Image.ANTIALIAS)
img.save('./home2/static/home2/src/img/' + destination)