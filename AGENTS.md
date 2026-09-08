# Instructions for AI and Developers

This repository provides unified SPADI container images. Keep the implementation practical, reproducible, and easy for humans to understand and maintain.

## Working method and knowledge capture

Treat `AGENTS.md` as the persistent engineering knowledge base for this repository, not only as a static style guide.

Before making a design decision or answering a question about repository policy, inspect the current repository state and this `AGENTS.md` rather than relying on memory or assumptions when the answer can be verified directly.

Whenever a build, CI, Docker, Apptainer, dependency, runtime, or hardware-related error is investigated and the investigation reveals a reusable rule, constraint, compatibility issue, failure mode, or non-obvious fix, update `AGENTS.md` in the same development cycle. Record the reason for the rule, not only the final workaround, so that future AI sessions and developers do not repeat the same failure.

In particular, after fixing an error:

1. identify what was actually wrong from the relevant source, configuration, or logs;
2. make the smallest maintainable implementation fix;
3. add the reusable lesson to `AGENTS.md` when it can prevent recurrence;
4. keep validation or smoke tests that detect the failure automatically when practical;
5. verify the repository state after the change instead of assuming that the intended edit or CI result exists.

Do not add transient one-off log details to `AGENTS.md`; capture the general engineering knowledge learned from them.

When investigating GitHub Actions failures, do not fetch, read, or process the complete workflow log by default. Large ROOT/ARTEMIS/FULL build logs can be very large, and reading the whole log can make an AI/tool session slow, stall, or fail before the useful error is reached. First inspect the workflow/job/step status, identify the most recent failed step, and retrieve only the latest relevant error output or a small tail/context around that failure. Expand to earlier or larger log sections only when the latest error does not contain enough information to diagnose the cause. Do not repeatedly re-read successful build output. For long-running jobs with no failure yet, inspect status, timestamps, and the latest available activity rather than downloading the full log.

When transferring dependency build recipes from a reference repository, verify exact upstream repository URLs, tags, and versions against the working reference instead of retyping them from memory. A one-character owner/repository typo can waste an entire long container build before the dependency-clone step is reached. In particular, redis-plus-plus is hosted at `https://github.com/sewenew/redis-plus-plus.git`.

Explicit new corrections from Nobuyuki Kobayashi should also be incorporated into `AGENTS.md` when they establish a reusable repository rule.

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

For ROOT, use `gnuinstall=OFF`. `/opt/spadi` is a self-contained SPADI software prefix rather than a system `/usr`-style installation. ROOT should therefore use its native prefix layout so that its `bin`, `lib`, and `include` directories integrate directly with the common `/opt/spadi` environment. Do not change ROOT to `gnuinstall=ON` unless the overall SPADI installation layout is intentionally redesigned.

User images should not normally contain `/opt/spadi/src`. Development images retain source trees.

ROOT/Cling is an exception to the general preference to omit compiler-related runtime content. When ROOT is built against the system GCC toolchain, Cling invokes a `c++` compiler driver to discover the standard-library include paths and also requires installed ROOT headers such as `/opt/spadi/include/ROOT.modulemap` at runtime. ARTEMIS and FULL user images that include this ROOT build must therefore retain `/opt/spadi/include` and provide `gcc-c++` (or an equivalent `c++` driver plus matching standard C++ headers). They should still omit `/opt/spadi/src`, CMake, Git, and unrelated development tools unless another runtime component genuinely requires them. On AlmaLinux 9, installing `gcc-c++` may also install `make` as a package dependency; do not treat the mere presence of `make` as a runtime-image failure when it is pulled in this way. Smoke tests must launch ROOT and verify both `c++` and `ROOT.modulemap` so this failure is caught before SIF publication.

## Environment isolation

Do not make the container runtime depend on software environment variables inherited from the host.

Define the SPADI runtime environment explicitly. Do not initialize `PATH`, `LD_LIBRARY_PATH`, `CMAKE_PREFIX_PATH`, `PKG_CONFIG_PATH`, ROOT, ARTEMIS, or NestDAQ environments by blindly appending host values.

Apptainer runtime tests must use a clean environment (`--cleanenv`) and verify that the resulting container environment is sufficient by itself. Do not assume Docker `ENV` values will always appear unchanged in an Apptainer `--cleanenv` invocation. For CI smoke tests, set host sentinel variables to detect leakage, then explicitly pass the intended SPADI runtime variables with Apptainer `--env`. This tests both host isolation and the actual required runtime environment instead of failing before the software itself is exercised.

## CPU compatibility

Target `linux/amd64` and generic x86-64 compatibility, including older x86-64 machines.

Never use `-march=native` for NestDAQ, nestdaq-user-impl, or other SPADI software. Do not require `x86-64-v2`, AVX, or AVX2 unless explicitly requested.

Prefer `-march=x86-64 -mtune=generic`; use explicit non-AVX flags where necessary. NestDAQ and nestdaq-user-impl currently contain upstream Release flags using `-march=native`; these must be neutralized and the resulting binaries checked for unintended AVX instructions.

Current `nestdaq-user-impl` may fail against the pinned FairMQ build because `TimeFrameBuilder.cxx` passes a `const fair::mq::Parts` through an API whose `operator[]` is not const-qualified, producing `passing 'const fair::mq::Parts' as 'this' argument discards qualifiers`. For the container build, intentionally add `-fpermissive` to the patched `nestdaq-user-impl` Release flags rather than carrying a local source-level const-signature modification. Keep this workaround scoped to `nestdaq-user-impl`; do not add `-fpermissive` globally to unrelated SPADI dependencies. Re-evaluate and remove it when upstream `nestdaq-user-impl` or FairMQ resolves the const mismatch. FULL restores the upstream `nestdaq-user-impl/CMakeLists.txt` before rebuilding with ROOT, so the FULL build must explicitly reapply this same scoped `-fpermissive` workaround after the checkout; otherwise the known const-qualification failure is reintroduced even when DAQ itself builds successfully.

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

Canonical component Dockerfiles are the shared build definitions. FULL and DAQ CI must reuse `containers/fee/Dockerfile`, `containers/daq/Dockerfile`, and `containers/artemis/Dockerfile` rather than duplicating their installation recipes in workflow YAML or a second FULL-only implementation.

On AlmaLinux 9, the FULL development stage must enable the CRB repository before installing ARTEMIS/ROOT development packages that live there, such as `giflib-devel`. The canonical ARTEMIS build already enables CRB; when FULL reconstructs the development environment on top of the DAQ development image, do not assume the repository enablement state was inherited. Enable CRB explicitly before installing those development dependencies.

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

When asserting that a command must be absent, do not rely on a bare `! command -v ...` under `set -e`; commands used in an inverted conditional context are exempt from normal `errexit` behavior and can make an intended policy check ineffective. Use an explicit helper or `if command -v ...; then exit 1; fi` so the failure is unambiguous.

Hardware-dependent tests (JTAG, Digilent HS3, SiTCP hardware, real DAQ networks) are separate from container-only smoke tests.

## GitHub Actions

Keep workflows readable from top to bottom. Build, Docker test, SIF creation, SIF test, and publishing should be visibly separate operations.

The automatic push build has a single source of truth: `.github/workflows/build-all.yml`. It must launch all eight supported image targets (`user` and `devel` for FEE, DAQ, ARTEMIS, and FULL) from one matrix with `max-parallel: 8`, so the eight top-level target jobs can start concurrently. Do not reintroduce separate push-triggered `build-fee.yml`, `build-daq.yml`, `build-artemis.yml`, or `build-full.yml` workflows, and do not add cross-target `needs:` relationships that serialize these eight jobs. Individual targets may still perform their own intrinsic prerequisite work inside their own runner.

FEE, DAQ, ARTEMIS, and FULL builds must be independently startable and must not require a sibling target or workflow to finish first. In particular, do not use a mutable sibling `:latest` image as the source of truth for a DAQ or FULL build. When DAQ or FULL needs prerequisite layers, build commit-local prerequisite images from the canonical component Dockerfiles and pass those immutable commit-specific tags as Docker build arguments. This deliberately trades additional CI compute for shorter wall-clock time, deterministic source consistency, and true top-level parallelism.

Inside FULL, the independent ROOT/ARTEMIS build should start in parallel with the FEE-to-DAQ chain. Only the intrinsic composition step waits for its own commit-local prerequisites; the standalone FEE, DAQ, ARTEMIS, and FULL targets themselves should all be able to run concurrently.

ARTEMIS images are expected to take substantially longer to build than FEE or DAQ images because the Docker build compiles ROOT and ARTEMIS from source. Do not classify an ARTEMIS Docker build as hung merely because it has remained in the `Build and push Docker image` step for a few hours. In the reference repository `nobukoba/container-artemis-first-trial`, a known successful GitHub Actions build (run `33737118485`, 2026-09-02) took about 2 hours 50 minutes for the job. Use this as a practical baseline: investigate a suspected hang using job timestamps, runner activity, logs, or an actual timeout/failure rather than elapsed time alone.

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

Use `latest` and UTC timestamp tags in `YYYYMMDD-HHMMutc` format, following the existing Kobayashi container repositories. Commit-local prerequisite tags used only inside CI are allowed and should be clearly prefixed (for example `ci-...`) so they cannot be confused with published user-facing releases.

## README

Before creating or revising `README.md`, read and follow `nobukoba/nobuyuki-kobayashi-instructions-for-ai`, especially `styles/nobuyuki-kobayashi-github-readme.md`.

Organize the README around what a user actually needs to do. Keep download and run commands copy-pasteable, include concrete URLs and paths, document the container directory structure, and keep documentation consistent with the actual implementation.

Explicit new corrections from Nobuyuki Kobayashi take precedence over this file and should be incorporated here when they establish a reusable repository rule.

## Reference repositories

Use these existing implementations as references rather than guessing their behavior:

- `nobukoba/container-hul-common-lib-amaneq-soft-first-trial`
- `nobukoba/container-interfacing-nestdaq-eicrecon`
- `nobukoba/container-artemis-first-trial`
