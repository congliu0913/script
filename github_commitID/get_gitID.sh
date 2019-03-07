#!/bin/bash

pwd
echo "======================================================"
echo "======================================================"
cd src
for x in `ls` 
do
	cd $x 
	for y in `ls` 
	do
		cd $y 
		echo $x/$y
		number=`sed -n "/$x\/$y:/"= ~/ropo_test/ros2.repos`
		if test $number  
		then
			echo $number "+++++++++++++++++++++++++++++++++"
			number=$(($number+2))
			echo $number
			commitID=`git rev-parse HEAD`
			sed -i "${number}a\    version: $commitID" ~/ropo_test/ros2.repos
			number=$(($number+2))
			sed -i "${number}d" ~/ropo_test/ros2.repos
			echo "**************************************************"
		else
			echo "could not find "$x"/"$y "in file"
		fi
		cd ../
	done
	cd ../
done
