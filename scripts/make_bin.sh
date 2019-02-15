#! /bin/sh
OUT=/tmp/nac_binary/
mkdir /tmp/nac_binary/
cp -r utils $OUT
cp dist/nac $OUT
cp ../naap18/example1/ -r $OUT
