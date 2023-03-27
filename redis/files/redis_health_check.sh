#!/bin/bash

REDIS_HOST="localhost"
REDIS_PORT=6379

read request
request_path=$(echo $request | awk '{print $2}')

if [[ $request_path == "/redis-health" ]]; then
  echo "PING" | redis-cli -h $REDIS_HOST -p $REDIS_PORT | grep -q PONG
  if [[ $? -eq 0 ]]; then
    echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 2\r\n\r\nOK"
  else
    echo -e "HTTP/1.1 503 Service Unavailable\r\nContent-Type: text/plain\r\nContent-Length: 19\r\n\r\nService Unavailable"
  fi
else
  echo -e "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\nContent-Length: 9\r\n\r\nNot Found"
fi

