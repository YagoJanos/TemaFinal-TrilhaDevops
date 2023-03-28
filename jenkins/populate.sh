#!/bin/bash

find . -type f -name "JenkinsFile" | while read file; do
    dir=$(dirname "$file")
    mv "$file" "${dir}/Jenkinsfile"
done

