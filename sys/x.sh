#!/bin/bash

KEEP=NO

case $1 in
	# clean built files
	"clean")
		rm -rf iso *.o *.bin *.log *.iso
		exit 0
		;;
	# run the binary file without grub
	"run-bin")
		command -v qemu-system-x86_64 > /dev/null || printf "You need qemu to test!\n"
		qemu-system-x86_64 -kernel finfetch.bin
		exit 0
		;;
	# run the CDROM with grub
	"run")
		command -v qemu-system-x86_64 > /dev/null || printf "You need qemu to test!\n"
		qemu-system-x86_64 -cdrom fnftch.iso
		exit 0
		;;
	# keep files
	"keep")
		KEEP=YES
		;;
esac

printf "Building..."
zig build-exe src/main.zig -target i386-freestanding --linker-script sys/linker.ld --name ./finfetch.bin || exit 1
printf "OK\n"

printf "Checking for multiboot..."
grub-file --is-x86-multiboot finfetch.bin || exit 1
printf "OK\n"

if [ -d iso ]; then
	printf "Removing old ROM directory..."
	rm -rf iso
	printf "OK\n"
fi

printf "Setting up ROM directory..."
mkdir -p iso/boot/grub
mkdir -p iso/usr/src
mkdir iso/usr/include
cp -r src iso/usr/src/kernel
cp finfetch.bin iso/boot/finfetch.bin
cp sys/grub.cfg iso/boot/grub/grub.cfg
printf "OK\n"

printf "Making ISO..."
grub-mkrescue iso -o fnftch.iso &> build.log || exit 1
printf "OK\n"

# remove useless files if "keep" is not passed
case $KEEP in
	"NO")
		printf "Removing trash files and logs (to keep, pass 'keep')..."
		rm -f *.log *.o
		printf "OK\n"
		;;
esac

echo "----------------------------------------------------"
echo "|  Done! To use, run 'x.sh run' or 'x.sh run-bin'  |"
echo "----------------------------------------------------"
