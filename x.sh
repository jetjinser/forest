#!/usr/bin/env bash

xmls=($(find output/ -type f -name '*.xml'))
stylesheet="output/default.xsl"

for xml in "${xmls[@]}"
do
  printf "${xml} => ${xml/xml/html}\n"
  xsltproc -o "${xml/xml/html}" "${stylesheet}" "${xml}"
done
