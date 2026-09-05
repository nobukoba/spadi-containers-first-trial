#!/usr/bin/env bash
set -euo pipefail

kind="${1:-${SPADI_IMAGE_KIND:-}}"
if [[ "$kind" != "user" && "$kind" != "devel" ]]; then
  echo "usage: smoke-test-fee.sh {user|devel}" >&2
  exit 2
fi

echo "=== SPADI environment ==="
test "${SPADI_ROOT:-}" = "/opt/spadi"
test -d /workspace
test -w /workspace
test "$PATH" = "/opt/spadi/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
test "${LD_LIBRARY_PATH:-}" = "/opt/spadi/lib:/opt/spadi/lib64"
test "${CMAKE_PREFIX_PATH:-}" = "/opt/spadi"
test "${PKG_CONFIG_PATH:-}" = "/opt/spadi/lib/pkgconfig:/opt/spadi/lib64/pkgconfig"

case ":${PATH}:" in
  *:/home/*|*:/Users/*) echo "ERROR: host-like path leaked into PATH" >&2; exit 1 ;;
esac
case ":${LD_LIBRARY_PATH:-}:" in
  *:/home/*|*:/Users/*) echo "ERROR: host-like path leaked into LD_LIBRARY_PATH" >&2; exit 1 ;;
esac

echo "=== FEE commands ==="
command -v openFPGALoader
openFPGALoader --version
command -v mpc-mpcx-ip-writer
command -v mpc-mpcx-ip-reader
command -v mpc-mpcx-ip-command
command -v sitcp-sitcpxg-ip-writer
command -v sitcp-sitcpxg-ip-reader

test -x /opt/spadi/bin/get_version
test -x /opt/spadi/StrHRTDC/bin/get_version_hrtdc
find /opt/spadi -name HulCoreConfig.cmake -print -quit | grep -q .

echo "=== Network diagnostics ==="
command -v ip
command -v ss
command -v ping
command -v netstat
command -v dig
command -v nslookup
command -v traceroute
command -v tcpdump
command -v nc
command -v curl
command -v lsof

echo "=== Shared libraries ==="
while IFS= read -r exe; do
  ldd "$exe" | (! grep -q 'not found')
done < <(find /opt/spadi/bin /opt/spadi/StrHRTDC/bin -maxdepth 1 -type f -perm -111 2>/dev/null)

if [[ "$kind" == "user" ]]; then
  echo "=== User image policy ==="
  ! command -v gcc
  ! command -v g++
  ! command -v cmake
  ! command -v make
  ! command -v git
  test ! -d /opt/spadi/src
  test ! -d /opt/spadi/include
else
  echo "=== Development image policy ==="
  command -v gcc
  command -v g++
  command -v cmake
  command -v make
  command -v git
  test -d /opt/spadi/src/hul-common-lib
  test -d /opt/spadi/src/amaneq-soft
  test -d /opt/spadi/src/openFPGALoader
  test -d /opt/spadi/src/sitcp-sitcpxg-mpc-mpcx-ip-utility-first-trial
  test -d /opt/spadi/include
fi

echo "FEE ${kind} container check passed."
