#!/bin/sh

while true; do eval "$(cat /mnt/USER_SPACE/pipe/mypipe)" &> /mnt/USER_SPACE/pipe/output.txt; done
