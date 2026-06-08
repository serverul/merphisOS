# MerphisOS Kernel Custom — Plan Detaliat (v0.4-beta)

## Obiectiv

Compilare kernel Linux 6.12.x custom cu:
- Module critice isofs/squashfs/loop/overlay ca BUILT-IN (nu modules)
- Module minim pentru desktop
- Hardening patches (Landlock, KASLR, init_on_alloc/free, etc.)
- BBRv3 congestion control
- Optimizări pentru desktop
- KSM disabled
- Stripped debug overhead

## Arhitectură

### Base Kernel
- Source: linux-6.12.90 vanilla (kernel.org)
- Config: bazat pe Debian 6.12.90 (bootabil garantat)
- Patches: linux-hardened subset

### Module Strategy
- Built-in (=y): isofs, squashfs, overlay, loop, virtio_*, vt
- Module (=m): USB, Bluetooth, sound, network drivers
- Disabled: telephony, ISDN, Amateur Radio

### Build Process
1. wget linux-6.12.90.tar.xz
2. make defconfig (sau copy from Debian)
3. Apply MerphisOS customizations
4. make -j$(nproc) bzImage modules
5. Install modules
6. Copy kernel binary to output

### Config Customizations
- isofs/squashfs/overlay/loop = y (built-in)
- Landlock = y
- KASLR = y
- Stack protector strong = y
- Init on alloc/free = y
- BBR = y
- KSM = n

### Estimated Build Time
- First: 30-90 min (8 cores)
- Incremental: 5-15 min
- Kernel size: 10-15 MB
- ISO size impact: +5-10 MB

## Success Criteria
- [ ] Compile clean
- [ ] ISO booteaza in QEMU
- [ ] Live boot complet (login → desktop)
- [ ] isofs/squashfs/overlay verificate built-in
- [ ] ISO size < 2.2 GB

## Files
- build-kernel.sh (NEW)
- kernel-config-merphisos (NEW, full .config)
- Dockerfile.merphisos-rootfs (MODIFY)
- build-iso.sh (MODIFY — kernel path)
- merphisos-build.sh (MODIFY — kernel build step)
