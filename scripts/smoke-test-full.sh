#!/usr/bin/env bash
set -euo pipefail

kind="${1:-${SPADI_IMAGE_KIND:-}}"
if [[ "$kind" != "user" && "$kind" != "devel" ]]; then
  echo "usage: smoke-test-full.sh {user|devel}" >&2
  exit 2
fi

assert_command_absent() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: unexpected command in runtime image: $cmd ($(command -v "$cmd"))" >&2
    return 1
  fi
}

echo "=== Unified environment ==="
test "${SPADI_ROOT:-}" = "/opt/spadi"
test "${ROOTSYS:-}" = "/opt/spadi"
test "${ARTEMIS_ROOT:-}" = "/opt/spadi"
test "${TARTSYS:-}" = "/opt/spadi"
test "${EXP_CONFIG_ROOT:-}" = "/opt/spadi/scripts/exp-config"
test -d /workspace
test -w /workspace

echo "=== FEE ==="
command -v openFPGALoader
command -v mpc-mpcx-ip-writer
command -v sitcp-sitcpxg-ip-reader

echo "=== DAQ ==="
command -v daq-webctl
command -v TimeFrameBuilder
command -v STFBFilePlayer
test -r /opt/spadi/lib/redistimeseries.so
test -d /opt/spadi/scripts/exp-config

echo "=== ROOT / ARTEMIS ==="
command -v root-config
root-config --version
command -v root
root -b -q -e 'gSystem->Exit(0);'
command -v artemis
test -r /opt/spadi/bin/thisroot.sh
test -r /opt/spadi/bin/thisartemis.sh
artemis --help >/tmp/artemis-help.txt 2>&1 || true

for exe in \
  "$(command -v openFPGALoader)" \
  "$(command -v daq-webctl)" \
  "$(command -v TimeFrameBuilder)" \
  "$(command -v root)" \
  "$(command -v artemis)"; do
  if ldd "$exe" | grep -q 'not found'; then
    echo "ERROR: unresolved shared library for $exe" >&2
    exit 1
  fi
done

command -v TriggerView >/dev/null 2>&1 || {
  echo "ERROR: ROOT-dependent TriggerView was not installed in FULL image" >&2
  exit 1
}

if [[ "$kind" == "user" ]]; then
  echo "=== User image policy ==="
  command -v c++
  test -r /opt/spadi/include/ROOT.modulemap
  assert_command_absent cmake
  assert_command_absent git
  test ! -d /opt/spadi/src
else
  echo "=== Development image policy ==="
  command -v gcc
  command -v g++
  command -v cmake
  command -v make
  command -v git
  test -d /opt/spadi/src/nestdaq
  test -d /opt/spadi/src/nestdaq-user-impl
  test -d /opt/spadi/src/root
  test -d /opt/spadi/src/artemis
  test -d /opt/spadi/include
fi

echo "FULL ${kind} container check passed."
