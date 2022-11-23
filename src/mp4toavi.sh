#!/usr/bin/env bash

# https://opensharing.fr/ffmpeg-commandes-utiles

# $1 no necessary (default current dir: .)
DIR=${1:-"."}

# create list of file
mapfile -t FILES < <(find "${DIR}" -maxdepth 1 -name '*.mp4')

for f in "${FILES[@]}"; do
    # suppress entension .mp4 
    y=${f%.mp4}

    # convert to .avi
    ffmpeg -y -i "$y.mp4" -q:a 0 -q:v 10 "$y.avi"
done
