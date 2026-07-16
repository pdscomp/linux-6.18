#!/usr/bin/env bash
# Generate Yocto Linux patches from the current cosmos-linux-6.18.y branch.
#
# This script regenerates the patch files that meta-opencentauri applies to
# upstream Linux 6.18. Each git diff slice matches one existing patch so the
# Yocto layer stays in sync with the sandbox branch.

set -euo pipefail

LINUX_DIR="${LINUX_DIR:-/home/paul/sandbox/linux-6.18}"
PATCH_DIR="${PATCH_DIR:-/home/paul/carbon/cosmos/meta-opencentauri/recipes-kernel/linux/linux-mainline}"
BASE="${BASE:-85076e4654cc673e2563864afa878b04c12059ef}"
BRANCH="${BRANCH:-cosmos-linux-6.18.y}"

cd "$LINUX_DIR"

merge_base=$(git merge-base "$BRANCH" "$BASE")

echo "merge-base: $merge_base"
echo "branch:     $(git rev-parse --short HEAD)"

git diff "$merge_base..HEAD" -- \
    arch/arm/boot/dts/allwinner/Makefile \
    arch/arm/boot/dts/allwinner/elegoo-centauri-carbon1.dts \
    arch/arm/boot/dts/allwinner/elegoo-centauri-carbon2.dts \
    > "$PATCH_DIR/0001-Add-elegoo-centauri-carbon.dts.patch"

git diff "$merge_base..HEAD" -- \
    drivers/mailbox/Kconfig \
    drivers/mailbox/Makefile \
    drivers/remoteproc/Kconfig \
    drivers/remoteproc/Makefile \
    drivers/mailbox/sunxi-r528-msgbox.c \
    drivers/remoteproc/sunxi_r528_remoteproc.c \
    > "$PATCH_DIR/0001-Add-support-for-r528-msgbox-and-remoteproc.patch"

git diff "$merge_base..HEAD" -- \
    drivers/gpu/drm/panel/panel-sitronix-st77922.c \
    > "$PATCH_DIR/0004-drm-panel-add-sitronix-st77922.patch"

git diff "$merge_base..HEAD" -- \
    drivers/gpu/drm/panel/Kconfig \
    drivers/gpu/drm/panel/Makefile \
    > "$PATCH_DIR/0002-drm-add-RB-channel-swap-support-for-panels-with-swap.patch"

# 0005 and PWM patches are already clean upstream commits in this branch.
# They are included here for completeness if the Yocto layer ever needs them
# regenerated, but are usually taken directly from the Linux 6.18 stable tree.

git diff "$merge_base..HEAD" -- \
    drivers/gpu/drm/sun4i/sun4i_tcon.h \
    drivers/gpu/drm/sun4i/sun8i_tcon_top.c \
    > "$PATCH_DIR/0005-drm-sun4i-tcon-top-register-clocks-in-probe.patch"

git diff "$merge_base..HEAD" -- \
    Documentation/devicetree/bindings/pwm/allwinner,sun20i-pwm.yaml \
    drivers/pwm/pwm-sun20i.c \
    drivers/pwm/Kconfig \
    drivers/pwm/Makefile \
    > "$PATCH_DIR/0002-pwm-Add-Allwinner-s-D1-T113-S3-R329-SoCs-PWM-support.patch"

git diff "$merge_base..HEAD" -- \
    arch/riscv/boot/dts/allwinner/sunxi-d1s-t113.dtsi \
    > "$PATCH_DIR/0003-riscv-dts-allwinner-d1-Add-pwm-node.patch"

for f in \
    "$PATCH_DIR/0001-Add-elegoo-centauri-carbon.dts.patch" \
    "$PATCH_DIR/0001-Add-support-for-r528-msgbox-and-remoteproc.patch" \
    "$PATCH_DIR/0004-drm-panel-add-sitronix-st77922.patch" \
    "$PATCH_DIR/0002-drm-add-RB-channel-swap-support-for-panels-with-swap.patch" \
    "$PATCH_DIR/0005-drm-sun4i-tcon-top-register-clocks-in-probe.patch" \
    "$PATCH_DIR/0002-pwm-Add-Allwinner-s-D1-T113-S3-R329-SoCs-PWM-support.patch" \
    "$PATCH_DIR/0003-riscv-dts-allwinner-d1-Add-pwm-node.patch"; do
    [ -f "$f" ] || continue
    printf "%-60s %8d bytes\n" "$(basename "$f")" "$(stat -c%s "$f")"
done

echo "done."
