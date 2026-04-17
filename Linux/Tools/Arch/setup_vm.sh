#!/bin/bash
# Tiny 11 QEMU - Optimized for Arch/Hyprland (BTRFS)

# --- Variables ---
DISK_IMG="/var/lib/libvirt/images/tiny11.raw"
ISO_IMG="/home/soul/97_Archive/ISO/tiny-11-NTDEV/tiny11 23H2 x64.iso"
VIRTIO_ISO="/home/soul/97_Archive/ISO/tiny-11-NTDEV/virtio-win.iso"

# --- 1. Disk Management (BTRFS Optimization) ---
if [ ! -f "$DISK_IMG" ]; then
    echo "[INFO] Disk not found. Creating a 40GB raw disk with CoW disabled..."
    sudo touch "$DISK_IMG"
    sudo chattr +C "$DISK_IMG"
    sudo fallocate -l 40G "$DISK_IMG"
    # Ensure your user owns the file so QEMU can write to it without sudo
    sudo chown $USER:$USER "$DISK_IMG"
fi

# --- 2. QEMU Arguments Array ---
QEMU_ARGS=(
    -enable-kvm
    -machine q35,accel=kvm
    # Hyper-V enlightenments speed up Windows VMs significantly
    -cpu host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time,hv_synic,hv_stimer
    # Giving 6 cores to the VM (leaves enough for your i5-12450H host)
    -smp 6,sockets=1,cores=6,threads=1
    -m 8G
    
    # Windows expects local time, Linux uses UTC. This fixes clock drift.
    -rtc base=localtime

    # Graphics (SDL works great natively on Wayland)
    -device virtio-vga-gl
    -display sdl,gl=on

    # Storage: cache=none prevents double-caching with the host OS
    -drive file="$DISK_IMG",format=raw,if=virtio,cache=none,aio=io_uring,discard=unmap
    
    # Installation Media (Remove these two lines after Windows is installed)
    -cdrom "$ISO_IMG"
    -drive file="$VIRTIO_ISO",media=cdrom
    
    # Networking
    -net nic,model=virtio 
    -net user
    
    # Quality of Life: Seamless mouse integration and Audio
    -usb -device usb-tablet
    -audiodev pipewire,id=snd0 -device ich9-intel-hda -device hda-micro,audiodev=snd0
)

# --- 3. Execution ---
echo "[INFO] Launching Tiny 11..."
qemu-system-x86_64 "${QEMU_ARGS[@]}"
