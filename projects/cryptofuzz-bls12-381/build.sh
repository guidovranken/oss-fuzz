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

# This enables runtime checks for C++-specific undefined behaviour.
export CXXFLAGS="$CXXFLAGS -D_GLIBCXX_DEBUG"

# Prevent Boost compilation error with -std=c++17
export CXXFLAGS="$CXXFLAGS -D_LIBCPP_ENABLE_CXX17_REMOVED_AUTO_PTR"

if [[ $CFLAGS = *sanitize=memory* ]]
then
    export CXXFLAGS="$CXXFLAGS -DMSAN"
    export MSAN_OPTIONS="halt_on_error=0:exitcode=0:report_umrs=0"
fi

cd $SRC/
tar xvf OpenSSL_1_1_1d.tar.gz
cd openssl-OpenSSL_1_1_1d/
./config
if [[ $CFLAGS = *-m32* ]]
then
    setarch i386 ./config
elif [[ $CFLAGS = *sanitize=memory* ]]
then
    ./config no-asm
else
    ./config
fi
make -j$(nproc)
make install

cd $SRC/
lzip -d gmp-6.1.2.tar.lz
tar xvf gmp-6.1.2.tar
cd gmp-6.1.2/
autoreconf -ivf
if [[ $CFLAGS = *-m32* ]]
then
    ABI=32 CXXFLAGS="$CXXFLAGS -lpthread" ./configure --enable-cxx=yes
elif [[ $CFLAGS = *sanitize=memory* ]]
then
    CXXFLAGS="$CXXFLAGS -lpthread" ./configure --enable-cxx=yes --disable-assembly
else
    CXXFLAGS="$CXXFLAGS -lpthread" ./configure --enable-cxx=yes
fi
make -j$(nproc)
make install

cd $SRC/mcl
mkdir build
cd build
if [[ $CFLAGS = *-m32* ]]
then
    cmake -DUSE_ASM=off ..
elif [[ $CFLAGS = *sanitize=memory* ]]
then
    cmake -DUSE_ASM=off ..
else
    cmake ..
fi
make -j$(nproc)
cd ../
export MCL_LIBMCL_A_PATH=$(realpath build/lib/libmcl.a)
export MCL_INCLUDE_PATH=$(realpath include/)
export CXXFLAGS="$CXXFLAGS -DCRYPTOFUZZ_MCL"

if [[ $CFLAGS != *-m32* ]]
then
    cd $SRC/bls-signatures
    sed -i 's/private://g' src/publickey.hpp # Cryptofuzz needs access to the 'q' variable
    mkdir build
    cd build
    cmake ..
    make -j$(nproc)
    cd ../
    export CHIA_BLS_LIBBLS_A_PATH=$(realpath build/libbls.a)
    export CHIA_BLS_INCLUDE_PATH=$(realpath src/)
    export CHIA_BLS_RELIC_INCLUDE_PATH_1=$(realpath build/contrib/relic/include)
    export CHIA_BLS_RELIC_INCLUDE_PATH_2=$(realpath contrib/relic/include)
    export CXXFLAGS="$CXXFLAGS -DCRYPTOFUZZ_CHIA_BLS"
fi

export CXXFLAGS="$CXXFLAGS -DCRYPTOFUZZ_NO_OPENSSL"
export LINK_FLAGS="-lgmp -lcrypto"
export LIBFUZZER_LINK="$LIB_FUZZING_ENGINE"

cd $SRC/cryptofuzz
git checkout BLS12-381
python gen_repository.py

cd $SRC/cryptofuzz/modules/mcl
make -B

if [[ $CFLAGS != *-m32* ]]
then
    cd $SRC/cryptofuzz/modules/chia_bls
    make -B
fi

cd $SRC/cryptofuzz
make -B

cp ./cryptofuzz $OUT/
