# Instructions for AI and Developers

This repository provides unified SPADI container images. Keep the implementation practical, reproducible, and easy for humans to understand and maintain.

## Paths

All SPADI-related software uses the single installation prefix `/opt/spadi`.

- Source trees: `/opt/spadi/src/<project>`
- Installed executables: `/opt/spadi/bin`
- Installed libraries: `/opt/spadi/lib` and `/opt/spadi/lib64`
- Installed headers: `/opt/spadi/include`
- Scripts: `/opt/spadi/scripts`
- Experiment configuration: `/opt/spadi/scripts/exp-config`
- User/local scripts: `/opt/spadi/scripts/local`
- User working directory: `/workspace`

Do not use `/work`.

ROOT and ARTEMIS sources also belong below `/opt/spadi/src`. Prefer installing ROOT, ARTEMIS, NestDAQ, FEE software, and their dependencies directly into the common `/opt/spadi` prefix when the software supports it.

User images should not normally contain `/opt/spadi/src`. Development images retain source trees.

## Environment isolation

Do not make the container runtime depend on software environment variables inherited from the host.

Define the SPADI runtime environment explicitly. Do not initialize `PATH`, `LD_LIBRARY_PATH`, `CMAKE_PREFIX_PATH`, `PKG_CONFIG_PATH`, ROOT, ARTEMIS, or NestDAQ environments by blindly appending host values.

Apptainer runtime tests must use a clean environment (`--cleanenv`) and verify that the resulting container environment is sufficient by itself.

## CPU compatibility

Target `linux/amd64` and generic x86-64 compatibility, including older x86-64 machines.

Never use `-march=native` for NestDAQ, nestdaq-user-impl, or other SPADI software. Do not require `x86-64-v2`, AVX, or AVX2 unless explicitly requested.

Prefer `-march=x86-64 -mtune=generic`; use explicit non-AVX flags where necessary. NestDAQ and nestdaq-user-impl currently contain upstream Release flags using `-march=native`; these must be neutralized and the resulting binaries checked for unintended AVX instructions.

## Images

The supported image names are:

- `spadi-user-fee`
- `spadi-devel-fee`
- `spadi-user-daq`
- `spadi-devel-daq`
- `spadi-user-artemis`
- `spadi-devel-artemis`
- `spadi-user-full`
- `spadi-devel-full`

`DAQ = FEE + NestDAQ` and `FULL = DAQ + ARTEMIS`.

User images are runtime images. Do not add compilers, CMake, development headers, source trees, or unrelated development tools unless required at runtime.

Development images provide the corresponding runtime environment plus source and build tools.

## Dockerfiles and scripts

Write Dockerfiles, helper scripts, and workflows for human readability.

- Prefer clear code over clever or overly compact code.
- Keep FEE, DAQ, ARTEMIS, and FULL responsibilities visible.
- Avoid copying the same installation procedure into eight independent Dockerfiles.
- Share common logic where useful, but do not hide important behavior behind excessive abstraction.
- Use descriptive multi-stage build names.
- Put long shell procedures in readable scripts rather than embedding large shell programs in workflow YAML.
- Comment non-obvious compatibility patches and explain why they exist.

## Validation

A successful Docker build is not sufficient validation.

The normal pipeline is:

```text
Build image
    ↓
Test Docker image
    ↓
Create Apptainer SIF
    ↓
Test SIF with --cleanenv
    ↓
Publish
```

Use shared smoke-test scripts for Docker and SIF where practical.

Tests should verify at least:

- expected executables exist and start;
- runtime shared libraries resolve;
- `/workspace` exists and is usable;
- environment variables do not contain unintended host software paths;
- user images do not contain source/build environments unnecessarily;
- devel images contain the expected source/build environment;
- NestDAQ binaries do not accidentally contain AVX instructions introduced by `-march=native`.

Hardware-dependent tests (JTAG, Digilent HS3, SiTCP hardware, real DAQ networks) are separate from container-only smoke tests.

## GitHub Actions

Keep workflows readable from top to bottom. Build, Docker test, SIF creation, SIF test, and publishing should be visibly separate operations.

Support individual manual targets as well as `all`:

```text
all
user-fee
devel-fee
user-daq
devel-daq
user-artemis
devel-artemis
user-full
devel-full
```

Use `latest` and UTC timestamp tags in `YYYYMMDD-HHMMutc` format, following the existing Kobayashi container repositories.

## README

Before creating or revising `README.md`, read and follow `nobukoba/nobuyuki-kobayashi-instructions-for-ai`, especially `styles/nobuyuki-kobayashi-github-readme.md`.

Organize the README around what a user actually needs to do. Keep download and run commands copy-pasteable, include concrete URLs and paths, document the container directory structure, and keep documentation consistent with the actual implementation.

Explicit new corrections from Nobuyuki Kobayashi take precedence over this file and should be incorporated here when they establish a reusable repository rule.

## Reference repositories

Use these existing implementations as references rather than guessing their behavior:

- `nobukoba/container-hul-common-lib-amaneq-soft-first-trial`
- `nobukoba/container-interfacing-nestdaq-eicrecon`
- `nobukoba/container-artemis-first-trial`
