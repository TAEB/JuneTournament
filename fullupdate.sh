#!/bin/bash

time perl trophies.pl
echo "Creating FAQ"
perl make_faq.pl faq.txt > faq.html
echo "Compressing all pages"
tar -jcf pages.tbz2 index.html faq.html player.css player clan trophy
echo "Uploading tarball"
scp pages.tbz2 katron.org:public_html/nh/07/
rm pages.tbz2
echo "Extracting tarball remotely"
ssh katron.org 'cd public_html/nh/07 && tar -jxf pages.tbz2 && rm pages.tbz2'

