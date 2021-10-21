#!/usr/bin/env sh

echo $DOCUSIGN_PRIVATE_KEY | base64 -d > "$DOCUSIGN_PRIVATE_KEY_PATH"
bin/velocity start