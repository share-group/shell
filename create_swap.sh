#创建磁盘交换区

swapfile='/home/swap'

dd if=/dev/zero of=$swapfile bs=64M count=32
mkswap $swapfile
swapon $swapfile

echo 'create swap success...'

#swapoff $swapfile
#rm -rf $swapfile