# SPADI Containers — First Trial

Pre-built Docker/OCI and Apptainer SIF environments for SPADI FEE, NestDAQ, and ARTEMIS software.

## Quick Start

| Purpose | User image | Development image |
|---|---|---|
| FEE control | `spadi-user-fee` | `spadi-devel-fee` |
| NestDAQ | `spadi-user-daq` | `spadi-devel-daq` |
| ARTEMIS | `spadi-user-artemis` | `spadi-devel-artemis` |
| Everything | `spadi-user-full` | `spadi-devel-full` |

Use `spadi-user-*` for normal operation and `spadi-devel-*` when compilers, headers, CMake, and source trees are needed.

## Apptainer

```bash
curl -L -O \
  https://github.com/nobukoba/spadi-containers-first-trial/releases/download/latest/spadi-user-fee.sif

apptainer shell --cleanenv spadi-user-fee.sif
```

The other SIF images use the same naming scheme: `spadi-user-daq.sif`, `spadi-user-artemis.sif`, and `spadi-user-full.sif`.

## Docker

The images target `linux/amd64` with generic x86-64 compatibility.

On an x86-64 Linux host:

```bash
docker pull ghcr.io/nobukoba/spadi-containers-first-trial/spadi-user-fee:latest

docker run --rm -it \
  -v "$PWD:/workspace" \
  ghcr.io/nobukoba/spadi-containers-first-trial/spadi-user-fee:latest
```

On an Apple Silicon Mac (`arm64`), explicitly select the x86-64 image so Docker Desktop runs it through amd64 emulation:

```bash
docker pull --platform linux/amd64 \
  ghcr.io/nobukoba/spadi-containers-first-trial/spadi-user-fee:latest

docker run --rm -it \
  --platform linux/amd64 \
  -v "$PWD:/workspace" \
  ghcr.io/nobukoba/spadi-containers-first-trial/spadi-user-fee:latest
```

Without `--platform linux/amd64`, Docker on Apple Silicon reports `no matching manifest for linux/arm64/v8` because these images intentionally do not publish a native ARM64 variant.

If you want `linux/amd64` to be the default for the current shell session:

```bash
export DOCKER_DEFAULT_PLATFORM=linux/amd64
```

After that, the normal `docker pull` and `docker run` commands above can be used without repeating `--platform`.

## Image Structure

```text
FEE ──> DAQ ──┐
              ├──> FULL
ARTEMIS ──────┘
```

- `DAQ = FEE + NestDAQ`
- `FULL = DAQ + ARTEMIS`

## Container Directory Structure

All installed SPADI software uses the single prefix `/opt/spadi`.

```text
/opt/spadi/
├── bin/                    # Installed executables
├── lib/                    # Installed libraries
├── lib64/                  # Installed libraries
├── include/                # Installed headers
├── share/                  # Shared data/resources
├── etc/                    # Package configuration, when needed
├── src/                    # Source trees (devel images only)
│   ├── hul-common-lib/
│   ├── amaneq-soft/
│   ├── nestdaq/
│   ├── nestdaq-user-impl/
│   ├── root/
│   └── artemis/
└── scripts/
    ├── exp-config/         # Experiment configurations
    └── local/              # User/local scripts

/workspace/                 # User working directory
```

The basic rule is:

```text
source  -> /opt/spadi/src/<project>
install -> /opt/spadi
work    -> /workspace
```

User images normally do not contain `/opt/spadi/src`. Development images retain source trees.

## Environment Isolation

SPADI environment variables are defined by the container and must not depend on host software environments. Apptainer examples therefore use `--cleanenv`.

## Image Tags

Successful builds use both `latest` and a UTC timestamp tag:

```text
latest
YYYYMMDD-HHMMutc
```

## For Developers

The repository is intentionally organized so that Dockerfiles, helper scripts, tests, and GitHub Actions remain understandable to humans. Common logic should be shared where useful, but important build behavior should not be hidden behind excessive abstraction.

Validation follows:

```text
Build image
    ↓
Test Docker image
    ↓
Create Apptainer SIF
    ↓
Test SIF with a clean environment
    ↓
Publish
```

A successful Docker build alone is not sufficient validation.

### Repository Structure

```text
spadi-containers-first-trial/
├── README.md
├── AGENTS.md
├── containers/
│   ├── fee/
│   ├── daq/
│   ├── artemis/
│   └── full/
├── scripts/
└── .github/
    └── workflows/
```

### Reference Implementations

- `nobukoba/container-hul-common-lib-amaneq-soft-first-trial` — FEE environment
- `nobukoba/container-interfacing-nestdaq-eicrecon` — NestDAQ build/runtime environment
- `nobukoba/container-artemis-first-trial` — ROOT/ARTEMIS and Docker/GHCR/SIF workflow

README writing follows `nobukoba/nobuyuki-kobayashi-instructions-for-ai`.

## Status

This repository is an experimental first-trial implementation. Paths and build details may change while the eight images are being validated.
