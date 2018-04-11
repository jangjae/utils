#!/bin/bash
# 6: old 7: new

DIFF="vim -d"
LEFT=${6}
RIGHT=${7}
## vertical splits
# $DIFF $LEFT $RIGHT -c "wincmd l"

## horizontal splits
# $DIFF -o $LEFT $RIGHT \
    # -c "doautocmd filetypedetect BufRead $RIGHT" \
    # -c "doautocmd filetypedetect BufNewFile $RIGHT" \
    # -c "wincmd j"


$DIFF -O $RIGHT $LEFT \
    -c "doautocmd filetypedetect BufRead $RIGHT" \
    -c "doautocmd filetypedetect BufNewFile $RIGHT"
