#!/bin/bash

rm -rf build/
python2 setup.py build
sudo python2 setup.py install
generate_library --input=src/googleapis/codegen/testdata/drive.json \
                --language=d --output_dir=gdrive_client
