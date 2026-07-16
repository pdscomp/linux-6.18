#!/usr/bin/env bash
# Generate Yocto Linux patches from the current cosmos-linux-6.18.y branch.
#
# These patches are intentionally *wiring-only* (Makefile/Kconfig additions),
# matching the way meta-opencentauri consumes them. The source files themselves
# are added to the build via SRC_URI in the linux-mainline_%.bbappend recipe.

set -euo pipefail

LINUX_DIR="${LINUX_DIR:-/home/paul/sandbox/linux-6.18}"
PATCH_DIR="${PATCH_DIR:-/home/paul/carbon/cosmos/meta-opencentauri/recipes-kernel/linux/linux-mainline}"
BASE="${BASE:-0c503cf3dde2e53614f05261ece12f9d3d4c3c20}"
BRANCH="${BRANCH:-cosmos-linux-6.18.y}"

cd "$LINUX_DIR"

merge_base=$(git merge-base "$BRANCH" "$BASE")

echo "merge-base: $merge_base"
echo "branch:     $(git rev-parse --short HEAD)"

# Output patch files mapped to the commit(s) that introduce the wiring change.
# Each value is a colon-separated list of commits that will be concatenated
# into a single patch. Most patches come from one commit; the DTS Makefile
# change is a separate historical commit from the .dts source files.

declare -A PATCHES=(
    ["$PATCH_DIR/0001-Add-elegoo-centauri-carbon.dts.patch"]="ad809961da3953779c4b85ad2a7d935feee329a8"
    ["$PATCH_DIR/0001-Add-support-for-r528-msgbox-and-remoteproc.patch"]="55f462f5260a37f9db2dc1d83c027b965729e10f"
    ["$PATCH_DIR/0004-drm-panel-add-sitronix-st77922.patch"]="84831df3de65193d800c6a053152568ee5cbd361"
    ["$PATCH_DIR/0002-drm-add-RB-channel-swap-support-for-panels-with-swap.patch"]="f361627575319cc4f9ca3b08c9e39e0df53c9b39"
    ["$PATCH_DIR/0005-drm-sun4i-tcon-top-register-clocks-in-probe.patch"]="8f82f0e0d593b73c7b4baf95abdfe9e84a4a06cb"
    ["$PATCH_DIR/0002-pwm-Add-Allwinner-s-D1-T113-S3-R329-SoCs-PWM-support.patch"]="adcdbd3cc2487ac1fcb2dcd1470b845cb4c44140"
    ["$PATCH_DIR/0003-riscv-dts-allwinner-d1-Add-pwm-node.patch"]="85076e4654cc673e2563864afa878b04c12059ef"
)

for out in "${!PATCHES[@]}"; do
    commits=$(echo "${PATCHES[$out]}" | tr ':' ' ')
    tmpdir=$(mktemp -d)
    first=1
    for commit in $commits; do
        git format-patch --no-numbered --no-cover-letter -o "$tmpdir" "$commit^..$commit" >/dev/null
        seg=$(ls "$tmpdir"/*.patch)
        if [ "$first" -eq 1 ]; then
            # Keep the first patch header and drop the trailing "--" footer.
            sed '/^-- $/,/^$/d' "$seg" > "$out"
            first=0
        else
            # Append only the diff body of subsequent patches.
            awk '/^diff --git /{body=1} body' "$seg" >> "$out"
        fi
        rm -f "$seg"
    done
    rm -rf "$tmpdir"
    printf "%-60s %8d bytes\n" "$(basename "$out")" "$(stat -c%s "$out")"
done

echo "done."
