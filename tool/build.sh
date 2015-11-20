#!/usr/bin/env bash
set -e
rm -rf build
pub get
pub build
cd build/
mv web www
cat > dslink.json <<EOF
{
  "name": "dslink-dart-html5",
  "version": "1.0.1",
  "description": "HTML5 DSLink",
  "main": "www",
  "served": true,
  "configs": {
    "path": {
      "type": "string",
      "default": "/links/html5"
    }
  }
}
EOF
zip -r  ../../../files/dslink-dart-html5.zip .
cd ..
