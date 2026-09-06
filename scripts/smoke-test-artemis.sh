#!/usr/bin/env bash
set -euo pipefail

kind="${1:-${SPADI_IMAGE_KIND:-}}"
if [[ "$kind" != "user" && "$kind" != "devel" ]]; then
  echo "usage: smoke-test-artemis.sh {user|devel}" >&2
  exit 2
fi

echo "=== SPADI / ROOT / ARTEMIS environment ==="
test "${SPADI_ROOT:-}" = "/opt/spadi"
test "${ROOTSYS:-}" = "/opt/spadi"
test "${ARTEMIS_ROOT:-}" = "/opt/spadi"
test "${TARTSYS:-}" = "/opt/spadi"
test -d /workspace
test -w /workspace

test -r /opt/spadi/bin/thisroot.sh
test -r /opt/spadi/bin/thisartemis.sh

command -v root-config
root-config --version
command -v root
root -b -q -e 'gSystem->Exit(0);'
command -v artemis

# The executable may print help and return a non-zero code depending on the
# upstream version. The important smoke check is that it starts and resolves
# all required shared libraries.
artemis --help >/tmp/artemis-help.txt 2>&1 || true

for exe in "$(command -v root)" "$(command -v artemis)"; do
  ldd "$exe" | (! grep -q 'not found')
done

find /opt/spadi -path '*/cmake/artemis/artemis-config.cmake' -print -quit | grep -q .

if [[ "$kind" == "user" ]]; then
  echo "=== User image policy ==="
  # ROOT/Cling built with the system GCC toolchain needs a C++ compiler driver,
  # the standard C++ headers, and ROOT.modulemap even in a runtime image.
  command -v c++
  test -r /opt/spadi/include/ROOT.modulemap
  ! command -v cmake
  ! command -v make
  ! command -v git
  test ! -d /opt/spadi/src
else
  echo "=== Development image policy ==="
  command -v gcc
  command -v g++
  command -v cmake
  command -v make
  command -v git
  test -d /opt/spadi/src/root
  test -d /opt/spadi/src/artemis
  test -d /opt/spadi/include
fi

echo "ARTEMIS ${kind} container check passed."
