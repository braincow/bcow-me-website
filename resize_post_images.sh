#!/bin/bash

DIR="./assets/post_images/"
WIDTHPX="480"

rm -fv $DIR/cover_*

for IMAGE in $DIR/*; do
    IMAGENAME=$(basename $IMAGE)
    if [[ "$IMAGENAME" =~ ^cover_.* ]]; then
        continue
    fi
    COVERNAME="cover_$IMAGENAME"
    echo -n "$IMAGENAME..."
    convert -geometry ${WIDTHPX}x $DIR/$IMAGENAME $DIR/$COVERNAME
    echo "resized"
done

# eof