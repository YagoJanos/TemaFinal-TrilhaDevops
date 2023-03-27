#!/bin/bash
for file in destroy/*/*/JenkinsFile; do
    cat ./TerraformDestroy >> "$file"
done

