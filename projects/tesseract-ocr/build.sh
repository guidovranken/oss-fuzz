#!/bin/bash -eu
# Copyright 2019 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

cd $SRC
tar zxvf jbigkit-2.1.tar.gz
cd $SRC/jbigkit-2.1/libjbig

# Patch the Makefile because it uses hardcoded CC, CFLAGS
sed -i 's/^CC = .*$//g' Makefile
sed -i 's/^CFLAGS = .*$//g' Makefile

make -j$(nproc)

mkdir -p $SRC/libjpeg-turbo/build
cd $SRC/libjpeg-turbo/build
cmake -G"Unix Makefiles" -DWITH_SIMD=0 ..
make -j$(nproc)
make install
ldconfig

cd $SRC/zlib
./configure
make -j$(nproc)
make install
ldconfig

cd $SRC/libtiff
./autogen.sh
./configure
make -j$(nproc)
make install
ldconfig

cd $SRC
tar zxvf xz-5.2.4.tar.gz
cd $SRC/xz-5.2.4
./configure
make -j$(nproc)
make install
ldconfig

cd $SRC/leptonica
./autogen.sh
./configure
make -j$(nproc)
make install
ldconfig

cd $SRC/libpng
CPPFLAGS="-I $SRC/zlib" LDFLAGS="-L$SRC/zlib" ./configure
make -j$(nproc)
make install
ldconfig

cd $SRC/tesseract
./autogen.sh
CXXFLAGS="$CXXFLAGS -D_GLIBCXX_DEBUG" ./configure --disable-graphics --disable-shared
make -j$(nproc)

cd $SRC/tesseract-ocr-fuzzers

cp -R $SRC/tessdata $OUT

$CXX $CXXFLAGS \
    -I $SRC/tesseract/src/api \
    -I $SRC/tesseract/src/ccstruct \
    -I $SRC/tesseract/src/ccmain \
    -I $SRC/tesseract/src/ccutil \
     $SRC/tesseract-ocr-fuzzers/fuzzer-api.cpp -o $OUT/fuzzer-api \
     $SRC/tesseract/src/api/.libs/libtesseract.a \
     /usr/local/lib/liblept.a \
     $SRC/libtiff/libtiff/.libs/libtiff.a \
     $SRC/libpng/.libs/libpng16.a \
     $SRC/libjpeg-turbo/build/libjpeg.a \
     $SRC/jbigkit-2.1/libjbig/libjbig.a \
     $SRC/xz-5.2.4/src/liblzma/.libs/liblzma.a \
     $SRC/zlib/libz.a \
     -lFuzzingEngine
