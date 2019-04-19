#!/bin/bash
total=$(grep 'sda$' /proc/partitions |awk '{print $3}');
used=0
for i in $(grep 'sda[[:digit:]]\+$' /proc/partitions |awk '{print $3}' |xargs)
do
used=$(( used + i ));
done
echo "总硬盘大小:" $(( total / (1024*1024) )) "GB"
echo "未分区硬盘大小:" $((( total - used ) / (1024*1024) )) "GB"