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

FROM gcr.io/oss-fuzz-base/base-builder
MAINTAINER guidovranken@gmail.com
RUN apt-get update && apt-get install -y make autoconf automake libtool cmake wget lzip libpython3.5-dev python libboost-all-dev wget
RUN git clone https://github.com/guidovranken/cryptofuzz.git
RUN git clone --recursive --depth 1 https://github.com/Chia-Network/bls-signatures.git
RUN git clone --depth 1 https://github.com/herumi/mcl.git
RUN wget https://gmplib.org/download/gmp/gmp-6.1.2.tar.lz
RUN wget https://github.com/openssl/openssl/archive/OpenSSL_1_1_1d.tar.gz
COPY build.sh $SRC/
