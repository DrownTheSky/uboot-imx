# environment
export ARCH=arm
export CROSS_COMPILE=arm-none-linux-gnueabihf-
export PATH=$PATH:/home/weidong/tools/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf/bin

# build
make distclean
make mx6ull_14x14_evk_defconfig
make -j24

# cmd
printenv
ping 172.20.10.2

run findfdt
run netboot

# unable to work
tftp 80000000 hello_world.bin
go 80000000
