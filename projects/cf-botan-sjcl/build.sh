#!/bin/bash -eu
# Copyright 2020 Google Inc.
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

cd $SRC/cryptofuzz
git checkout sjcl
python gen_repository.py

export CXXFLAGS="$CXXFLAGS -DCRYPTOFUZZ_NO_OPENSSL"
export LIBFUZZER_LINK="$LIB_FUZZING_ENGINE"

# Prevent Boost compilation error with -std=c++17
export CXXFLAGS="$CXXFLAGS -D_LIBCPP_ENABLE_CXX17_REMOVED_AUTO_PTR"

cd $SRC/
tar zxf boost_1_72_0.tar.gz
cd boost_1_72_0/
cp -R boost/ /usr/include

cd $SRC/cryptofuzz/modules/sjcl
echo "#include <string>" >tmp.cpp
cat generate_ids.cpp >>tmp.cpp
cp tmp.cpp generate_ids.cpp

# Build libfuzzer-js
cd $SRC/libfuzzer-js
sed -i 's/clang++/\$(CXX) \$(CXXFLAGS)/g' Makefile
cat Makefile
cd quickjs
make libquickjs.a
cd ..
make js.o to_bytecode
export LIBFUZZER_JS_PATH=$(realpath .)

# Build sjcl
cd $SRC/sjcl
./configure --with-sha1 --with-sha512 --with-ripemd160 --with-bn --with-scrypt --with-ecc --with-ctr --with-cbc
make
export SJCL_PATH=$(realpath .)
export CXXFLAGS="$CXXFLAGS -DCRYPTOFUZZ_SJCL"

# Build Cryptofuzz SJCL module
cd $SRC/cryptofuzz/modules/sjcl
make

# Build Botan
cd $SRC/botan
./configure.py --cc-bin=$CXX --cc-abi-flags="$CXXFLAGS" --disable-shared --disable-modules=locking_allocator
make -j$(nproc)
export CXXFLAGS="$CXXFLAGS -DCRYPTOFUZZ_BOTAN"
export LIBBOTAN_A_PATH=`realpath libbotan-2.a`
export BOTAN_INCLUDE_PATH=`realpath build/include`

# Build Cryptofuzz Botan module
cd $SRC/cryptofuzz/modules/botan
make

# Build Cryptofuzz
cd $SRC/cryptofuzz
make

cp $SRC/cryptofuzz/cryptofuzz $OUT/
