#!/usr/bin/env python3

import argparse
from xml.etree import ElementTree as ET

parser = argparse.ArgumentParser()
parser.add_argument('file', help='results.xml file')
args = parser.parse_args()

tree = ET.parse(args.file)
for failure in tree.iter("failure"):
    exit(1)
