#!/usr/bin/env bash

cat > version.txt << EOF
{
  "commit_sha": "$COMMIT",
  "image": "nrgi/resourcedata.org:$BRANCH.$COMMIT"
}
EOF
