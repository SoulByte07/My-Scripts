#!/bin/bash
# Tiny 11 - Stable Virtio-FS Launch Script 

export GDK_BACKEND=wayland

DISK_IMG="/var/lib/libvirt/images/tiny11.qcow2"
SHARE_PATH="/home/soul/2_Resources/8_VM_Shared_Volume/Tiny11-VM"

# We use a dedicated folder to bypass the /tmp/ sticky bit restrictions
SOCK_DIR="/tmp/vfsd_env"
SOCKET_PATH="$SOCK_DIR/vfsd.sock"

# 1. Setup isolated directory with open permissions
sudo mkdir -p "$SOCK_DIR"
sudo chmod 777 "$SOCK_DIR"
sudo rm -f "$SOCKET_PATH"

# 2. Start the Virtio-FS daemon
sudo /usr/lib/virtiofsd \
    --socket-path="$SOCKET_PATH" \
    --shared-dir="$SHARE_PATH" \
    --sandbox none &
VFS_PID=$!

# 3. Wait for the socket to be ready
notify-send "Waiting for Virtio-FS socket..."
while [ ! -S "$SOCKET_PATH" ]; do
    sleep 0.5
done

sudo chown $USER "$SOCKET_PATH"

notify-send "Socket ready! Launching QEMU..."


# 4. Launch QEMU
# qemu-system-x86_64 \
#     -enable-kvm \
#     -machine q35,memory-backend=mem \
#     -cpu host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time,hv_vpindex,hv_synic,hv_stimer \
#     -m 8G \
#     -object memory-backend-memfd,id=mem,size=8G,share=on \
#     -smp 4,sockets=1,cores=4,threads=1 \
#     -rtc base=localtime \
#     -device virtio-vga-gl \
#     -display sdl,gl=on \
#     -device qemu-xhci,id=xhci -device usb-tablet \
#     -audiodev pa,id=snd0 -device intel-hda -device hda-output,audiodev=snd0 \
#     -drive file="$DISK_IMG",if=virtio,format=qcow2,cache=none,aio=io_uring \
#     -net nic,model=virtio -net user \
#     -chardev socket,id=char0,path="$SOCKET_PATH" \
#     -device vhost-user-fs-pci,queue-size=1024,chardev=char0,tag=hostshare


# Launch QEMU with GTK and proper GL settings
# qemu-system-x86_64 \
#     -enable-kvm \
#     -machine q35,memory-backend=mem \
#     -cpu host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time,hv_vpindex,hv_synic,hv_stimer \
#     -m 8G \
#     -object memory-backend-memfd,id=mem,size=8G,share=on \
#     -smp 4,sockets=1,cores=4,threads=1 \
#     -rtc base=localtime \
#     -device virtio-vga-gl \
#     -display gtk,gl=on,zoom-to-fit=off \
#     -device qemu-xhci,id=xhci -device usb-tablet \
#     -audiodev pa,id=snd0 -device intel-hda -device hda-output,audiodev=snd0 \
#     -drive file="$DISK_IMG",if=virtio,format=qcow2,cache=none,aio=io_uring \
#     -net nic,model=virtio -net user \
#     -chardev socket,id=char0,path="$SOCKET_PATH" \
#     -device vhost-user-fs-pci,queue-size=1024,chardev=char0,tag=hostshare

qemu-system-x86_64 \
    -enable-kvm \
    -machine q35,memory-backend=mem \
    -cpu host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time,hv_vpindex,hv_synic,hv_stimer \
    -m 8G \
    -object memory-backend-memfd,id=mem,size=8G,share=on \
    -smp 4,sockets=1,cores=4,threads=1 \
    -rtc base=localtime \
    -device virtio-vga-gl \
    -display sdl,gl=on \
    -device qemu-xhci,id=xhci -device usb-tablet \
    -audiodev pa,id=snd0 -device intel-hda -device hda-output,audiodev=snd0 \
    -drive file="$DISK_IMG",if=virtio,format=qcow2,cache=none,aio=io_uring \
    -net nic,model=virtio -net user \
    -chardev socket,id=char0,path="$SOCKET_PATH" \
    -device vhost-user-fs-pci,queue-size=1024,chardev=char0,tag=hostshare

# 5. Cleanup when QEMU exits
sudo kill $VFS_PID
sudo rm -rf "$SOCK_DIR"

