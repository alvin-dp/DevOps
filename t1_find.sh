#!/bin/bash

LOG_DIR=/var/log
DAYS=13

if [ -n "$1" ]
then
	days=$1
  else  
	days=$DAYS
fi

find $LOG_DIR -type f -mtime +$days
