This provides a Docker environment for the BLS12-381 differential fuzzer, that currently has modules for herumi mcl and Chia Network bls-signatures.

Build using:

```sh
infra/helper.py build_fuzzers cryptofuzz-bls12-381 --sanitizer=address
```

or

```sh
infra/helper.py build_fuzzers cryptofuzz-bls12-381 --sanitizer=undefined
```

depending on which sanitizer you want to use.

After building, the path of the fuzzer binary is ```build/out/cryptofuzz-bls12-381/cryptofuzz```.
