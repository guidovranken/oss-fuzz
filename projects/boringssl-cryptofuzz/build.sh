#!/bin/bash -eu
# Copyright 2021 Google LLC
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

export LIBFUZZER_LINK="$LIB_FUZZING_ENGINE"

# Install Boost headers
cd $SRC/
tar jxf boost_1_74_0.tar.bz2
cd boost_1_74_0/
CFLAGS="" CXXFLAGS="" ./bootstrap.sh
CFLAGS="" CXXFLAGS="" ./b2 headers
cp -R boost/ /usr/include/

# Prevent Boost compilation error with -std=c++17
export CXXFLAGS="$CXXFLAGS -D_LIBCPP_ENABLE_CXX17_REMOVED_AUTO_PTR"

# Build Botan
cd $SRC/botan
if [[ $CFLAGS != *-m32* ]]
then
    ./configure.py --cc-bin=$CXX --cc-abi-flags="$CXXFLAGS" --disable-shared --disable-modules=locking_allocator --build-targets=static --without-documentation
else
    ./configure.py --cpu=x86_32 --cc-bin=$CXX --cc-abi-flags="$CXXFLAGS" --disable-shared --disable-modules=locking_allocator --build-targets=static --without-documentation
fi
make -j$(nproc)
export CXXFLAGS="$CXXFLAGS -DCRYPTOFUZZ_BOTAN"
export LIBBOTAN_A_PATH="$SRC/botan/libbotan-3.a"
export BOTAN_INCLUDE_PATH="$SRC/botan/build/include"

if [[ $CFLAGS != *sanitize=memory* ]]
then
    # Build BoringSSL (with assembly)
    cd $SRC/boringssl
    rm -rf build ; mkdir build
    cd build
    if [[ $CFLAGS = *-m32* ]]
    then
        setarch i386 cmake -DCMAKE_CXX_FLAGS="$CXXFLAGS" -DCMAKE_C_FLAGS="$CFLAGS" -DBORINGSSL_ALLOW_CXX_RUNTIME=1 -DCMAKE_ASM_FLAGS="-m32" ..
    else
        cmake -DCMAKE_CXX_FLAGS="$CXXFLAGS" -DCMAKE_C_FLAGS="$CFLAGS" -DBORINGSSL_ALLOW_CXX_RUNTIME=1 ..
    fi
    make -j$(nproc) crypto
    export OPENSSL_INCLUDE_PATH="$SRC/boringssl/include"
    export OPENSSL_LIBCRYPTO_A_PATH="$SRC/boringssl/build/crypto/libcrypto.a"
    export CXXFLAGS="$CXXFLAGS -DCRYPTOFUZZ_BORINGSSL"
    export CXXFLAGS="$CXXFLAGS -I $OPENSSL_INCLUDE_PATH"

    # Build Cryptofuzz
    cd $SRC/cryptofuzz
    python gen_repository.py
    rm extra_options.h
    echo -n '"' >>extra_options.h
    echo -n '--force-module=openssl ' >>extra_options.h
    echo -n '"' >>extra_options.h
    cd modules/openssl/
    make -B -j$(nproc)
    cd ../botan/
    make -B -j$(nproc)
    cd ../../
    make -B -j$(nproc)

    cp cryptofuzz $OUT/cryptofuzz-boringssl-asm
fi

# Build BoringSSL (without assembly)
cd $SRC/boringssl
rm -rf build ; mkdir build
cd build
cmake -DCMAKE_CXX_FLAGS="$CXXFLAGS" -DCMAKE_C_FLAGS="$CFLAGS" -DBORINGSSL_ALLOW_CXX_RUNTIME=1 -DOPENSSL_NO_ASM=1 ..
make -j$(nproc) crypto
export OPENSSL_INCLUDE_PATH="$SRC/boringssl/include"
export OPENSSL_LIBCRYPTO_A_PATH="$SRC/boringssl/build/crypto/libcrypto.a"
export CXXFLAGS="$CXXFLAGS -DCRYPTOFUZZ_BORINGSSL"
export CXXFLAGS="$CXXFLAGS -I $OPENSSL_INCLUDE_PATH"

# Build Cryptofuzz
cd $SRC/cryptofuzz
python gen_repository.py
rm extra_options.h
echo -n '"' >>extra_options.h
echo -n '--force-module=openssl ' >>extra_options.h
echo -n '"' >>extra_options.h
cd modules/openssl/
make -B -j$(nproc)
cd ../botan/
make -B -j$(nproc)
cd ../../
make -B -j$(nproc)

cp cryptofuzz $OUT/cryptofuzz-boringssl-no-asm
