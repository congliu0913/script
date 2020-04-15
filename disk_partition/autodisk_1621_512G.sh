#!/bin/bash
#2017-12-26
#Auto scan and mount useless disk 
#Version: 1.0

function USERSELECT {
	echo -e "\033[44;37m Do you want to partition $1 (Y/n) Default 'Y' \033[0m"
	read -p "" User_Select
	case ${User_select} in
		[Yy]*)
			echo -e "Found Disk: $1  - \033[32mUseless\033[0m" | tee -a /tmp/mount.log
			;;
		[Nn]*)
			echo -e "Found Disk: $1  - \033[32mUsed\033[0m" | tee -a /tmp/mount.log
			;;
		*)
			echo -e "Found Disk: $1  - \033[32mUseless\033[0m" | tee -a /tmp/mount.log
			;;
	esac
}

function SCAN {
	echo -e "\033[44;37mScaning...\033[0m"
	sleep 1
	> /tmp/mount.log
#	ALL_DISK=`fdisk -l | grep -Ev "mapper|root|swap|docker|loop" |grep ^"Disk /"|cut -d ' ' -f2 |cut -d: -f1`
	ALL_DISK=`parted -l | grep "/dev/sd[a-z]"|cut -d ' ' -f2 |cut -d: -f1`
	for i in ${ALL_DISK}
	do
#		df -Th | grep ${i} &> /dev/null
		umount /media/*/*
		df -Th | grep ${i}
		if [ $? -eq 0 ];then
			echo -e "Found Disk: ${i}  - \033[31mUsed\033[0m" | tee -a /tmp/mount.log
		else
			USERSELECT ${i}
			#echo -e "Found Disk: ${i}  - \033[32mUseless\033[0m" | tee -a /tmp/mount.log
		fi
	done
	Used_Disk=`cat /tmp/mount.log | grep Used | cut -d ' ' -f3`
	Useless_Disk=`cat /tmp/mount.log | grep Useless | cut -d ' ' -f3`
}
function PART {
	for i in ${Useless_Disk}
	do
		echo -e "\033[36mFormating ${i}....\033]0m"
	sleep 1
	PARTED=`which parted`
	j=`echo "${i}" | cut -d \/ -f 3`
#    OPTIMAL=`cat /sys/block/${j}/queue/optimal_io_size`
#    ALIGNMENT=`cat /sys/block/${j}/alignment_offset`
#    PHYSICAL=`cat /sys/block/${j}/queue/physical_block_size`
#    IO=$(((OPTIMAL+ALIGNMENT)/PHYSICAL))
        ${PARTED} -s ${i} mklabel gpt
	${PARTED} ${i} rm 1
        ${PARTED} ${i} mkpart primary 1 351 << EOF
i
EOF
        ${PARTED} ${i} mkpart primary 351 32.4GB << EOF
i
EOF	
	${PARTED} ${i} mkpart primary 32.4GB 40.6GB << EOF
i
EOF
	${PARTED} ${i} mkpart primary 40.6GB 48.8GB << EOF
i
EOF
	${PARTED} ${i} mkpart primary 48.8GB 57GB << EOF
i
EOF
	${PARTED} ${i} mkpart primary 57GB 100%
	echo -e "\033[32mDone\033[0m"
	done
}
function MKFS {
	for i in ${Useless_Disk}
	do
		partprobe
		sleep 5
		echo -e "\033[36mMkfs ${i}....\033]0m"
		mkfs.ext3 -F -T largefile ${i}1
		mkfs.ext4 -F -T largefile ${i}2 -N 400000
		mkfs.ext4 -F -T largefile ${i}3 -N 10240000
		mkfs.ext4 -F -T largefile ${i}4 -N 81920
		mkfs.ext4 -F -T largefile ${i}5 -N 81920
		mkfs.ext4 -F -T largefile ${i}6 -N 204800000
		echo -e "\033[32mDone\033[0m"
	done
}
function LABEL {
	for i in ${Useless_Disk}
	do
		echo -e "\033[36mLabel ${i}....\033]0m"
	e2label  ${i}1 /boot
	e2label  ${i}2 /sys
	e2label  ${i}3 /com
	e2label  ${i}4 /conf
	e2label  ${i}5 /audit
	e2label  ${i}6 /data    

		echo -e "\033[32mDone\033[0m"
		sleep 1
	done
}
#function MOUNT {
#	for i in ${Useless_Disk}
#	do
#		if [ ! -d /data ];then
#			mkdir /data
#			UUID_NUM=`blkid | grep "${i}1" | cut -d ' ' -f2`
#			echo "${UUID_NUM} /data	ext4	defaults 0 0" >> /etc/fstab
#			mount -a
#			[ $? -eq 0 ] && echo "${i} Mount Finished." 
#		else
#			read -p "/data in uesd,Input new mount point:" NEW_POINT
#			if [ -d ${NEW_POINT} ];then
#				read -p "${NEW_POINT} in uesd,Input new mount point again:" NEW_POINT
#				mkdir ${NEW_POINT}
#				UUID_NUM=`blkid | grep "${i}1" | cut -d ' ' -f2`
#				echo "${UUID_NUM} ${NEW_POINT}	ext4	defaults 0 0" >> /etc/fstab
#				mount -a
#				[ $? -eq 0 ] && echo "${i} Mount Finished." 
#			else
#				mkdir ${NEW_POINT}
#				UUID_NUM=`blkid | grep "${i}1" | cut -d ' ' -f2`
#				echo "${UUID_NUM} ${NEW_POINT}	ext4	defaults 0 0" >> /etc/fstab
#				mount -a
#				[ $? -eq 0 ] && echo "${i} Mount Finished." 
#			fi
#		fi
#	done
#}
function MAIN {
	SCAN
	if [ -z "${Useless_Disk}" ];then
		echo -e "\033[31mNot Fount Useless Disk.Exited...\033[0m" && exit 2
	fi
	PART
	MKFS
	LABEL
#	MOUNT
	rm -fr /tmp/mount.log
}
MAIN
