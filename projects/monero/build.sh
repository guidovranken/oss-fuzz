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

export BUILD_TYPE="Release"
export MONERO_PATH="$SRC/monero"
export MONERO_FUZZERS_PATH="$SRC/monero-fuzzers"
export LIBFUZZER_A_PATH="$LIB_FUZZING_ENGINE"
export CXXFLAGS="$CXXFLAGS -D_GLIBCXX_DEBUG"

# Install fuzzing headers
cd $SRC/fuzzing-headers
./install.sh

# Compile Boost
cd $SRC/

tar zxf boost_1_71_0.tar.gz

mkdir boost-install
export BOOST_PATH="$SRC/boost-install"

cd boost_1_71_0/
./bootstrap.sh --with-toolset=clang
./b2 toolset=clang cxxflags="$CXXFLAGS" linkflags="$CXXFLAGS" install --prefix=$BOOST_PATH -j$(nproc)

# Compile Monero
cd $SRC/monero/
mkdir build
cd build/
cmake -DBOOST_ROOT="$BOOST_PATH" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" ..
make -j$(nproc)

cd $SRC/monero-fuzzers/
echo export CC=\"$CC\" >>variables.sh
echo export CXX=\"$CXX\" >>variables.sh
echo export CXXFLAGS=\"$CXXFLAGS\" >>variables.sh
echo export BOOST_PATH=\"$BOOST_PATH\" >>variables.sh
echo export LIBFUZZER_A_PATH=\"$LIBFUZZER_A_PATH\" >>variables.sh
echo export MONERO_PATH=\"$MONERO_PATH\" >>variables.sh
echo export BUILD_TYPE=\"$BUILD_TYPE\" >>variables.sh
echo export MONERO_FUZZERS_PATH=\"$MONERO_FUZZERS_PATH\" >>variables.sh
make all

find -name 'fuzzer-*' -type f -executable -exec cp {} $OUT/ \;
