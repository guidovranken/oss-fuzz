#!/bin/bash -eu
# Copyright 2018 Google Inc.
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
cp $SRC/go-ethereum/crypto/secp256k1/scalar_mult_cgo.go /root/go/pkg/mod/github.com/ledgerwatch/secp256k1@v1.0.0/scalar_mult_cgo.go
sed -i 's#crypto.EcrecoverWithContext(context,#crypto.Ecrecover(#g' $GOPATH/src/github.com/ledgerwatch/erigon/core/types/transaction_signing.go
compile_go_fuzzer github.com/ledgerwatch/erigon/tests/fuzzers/runtime Fuzz fuzz_Runtime
