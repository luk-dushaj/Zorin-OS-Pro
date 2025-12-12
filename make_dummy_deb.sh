#!/usr/bin/env bash
set -euo pipefail

# Minimal script to build a dummy package that satisfies a dependency
# without installing files.
# Requires: equivs (equivs-build)

usage() {
  echo "Usage: $0 -n package_name -v version -o output_dir" >&2
  echo "  -n  Package name to provide (required)" >&2
  echo "  -v  Version number (required)" >&2
  echo "  -o  Output directory for .deb (required)" >&2
}

PKG_NAME=""
PKG_VERSION=""
OUT_DIR=""

while getopts ":n:v:o:h" opt; do
  case "$opt" in
    n) PKG_NAME="$OPTARG" ;;
    v) PKG_VERSION="$OPTARG" ;;
    o) OUT_DIR="$OPTARG" ;;
    h) usage; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument" >&2; usage; exit 2 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$PKG_NAME" || -z "$PKG_VERSION" || -z "$OUT_DIR" ]]; then
  echo "Error: all options -n, -v, and -o are required." >&2
  usage
  exit 2
fi

if ! command -v equivs-build >/dev/null 2>&1; then
  echo "Installing 'equivs' (requires sudo)..."
  sudo apt-get update -y
  sudo apt-get install -y equivs
fi

mkdir -p "$OUT_DIR"

WORKDIR="$(mktemp -d)"
CONTROL="$WORKDIR/control"
ARCH="all"
MAINTAINER="Dummy <dummy@dummy.invalid>"
DESCRIPTION="Dummy package to satisfy dependency for $PKG_NAME."

cat > "$CONTROL" <<EOF
Section: misc
Priority: optional
Standards-Version: 3.9.2

Package: $PKG_NAME
Version: $PKG_VERSION
Maintainer: $MAINTAINER
Architecture: $ARCH
Provides: $PKG_NAME
Description: $DESCRIPTION
 This package intentionally contains no files. It only exists
 to satisfy dependencies on $PKG_NAME.
EOF

# Build the .deb
( cd "$WORKDIR" && equivs-build control )

# Move result to requested output directory
DEB_FILE=$(ls -1 "$WORKDIR"/*.deb | head -n1)
OUT_FILE="${PKG_NAME}_${PKG_VERSION}_${ARCH}.deb"
mv "$DEB_FILE" "$OUT_DIR/$OUT_FILE"

echo "Built dummy package: $OUT_DIR/$OUT_FILE"
echo "Install with: sudo apt install $OUT_DIR/$OUT_FILE"
