#!/bin/bash
set -eo pipefail
mkdir package package/python package/python/lib
cp -r bin package/python/.
pip install --target package/python/lib/. -r requirements.txt