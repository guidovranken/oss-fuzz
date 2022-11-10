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
sed -i 's#github.com/ethereum/go-ethereum/#github.com/ava-labs/coreth/#g' runtime_fuzz.go
mkdir $GOPATH/src/github.com/ava-labs/coreth/fuzzers
mv runtime_fuzz.go $GOPATH/src/github.com/ava-labs/coreth/fuzzers
compile_go_fuzzer github.com/ava-labs/coreth/fuzzers Fuzz fuzz_Runtime
ls -l $OUT/
