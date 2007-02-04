#!/bin/bash

perl trophies.pl
tar -jcf pages.tbz2 player.css player/* clan/* trophy/*
scp pages.tbz2 katron.org:public_html/nh/07/
rm pages.tbz2
ssh katron.org 'cd public_html/nh/07 && tar -jxf pages.tbz2 && rm pages.tbz2'

