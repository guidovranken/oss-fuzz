First build the base image manually:

```
docker build -t gcr.io/oss-fuzz-base/base-builder infra/base-images/base-builder/
```

Then build the project:

```
infra/helper.py build_fuzzers <project> --engine=libfuzzer-gv
```
