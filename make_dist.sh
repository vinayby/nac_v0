#! /bin/sh
#
mkdir dist
pyinstaller --workpath .build_nac --distpath .dist_nac nac.spec

export PATH=/home/vinay/opt/pyinstaller2.7/home/vinay/.local/bin/:$PATH
pyinstaller --workpath .build_nafitter --distpath .dist_nafitter nafitter.spec
cp .dist_*/* dist

