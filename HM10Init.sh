#!/bin/sh

# 19.02.2020 - pesca1@gmx.ch
# connects with BLE devices with name XC-Tracer
# settings: baudrate 115200
#
# debug: check HM10Init.log
#        run with XC-Tracer switched off, check the log if module found
#        rerun with XC-Tracer switched on, it may need more than one go
# 
# inspired by the script Bluetooth-HM10-Initialize

allports="/dev/ttymxc0 /dev/ttymxc1 /dev/ttymxc2"

echo "##################################################" | tee -a HM10Init.log
echo `date` | tee -a HM10Init.log

echo "searching HM-10/HM-11 module on ports $allports" | tee -a HM10Init.log
echo "important: modules with software version below V605 won't work!" | tee -a HM10Init.log

# send AT command to $DEV
ATcom() {
	printf "AT+$1" > $DEV
	sleep 0.5
}

# test all ports and baud rates to find HM10/HM11 module
for DEV in $allports
do
	stty -F $DEV raw -echo -echoe -echok
	for baud in 9600 19200 38400 57600 115200
	do
        echo "testing $DEV at $baud baud" | tee -a HM10Init.log
		stty -F $DEV $baud min 0 time 1
		printf "AT" > $DEV
		sleep 0.5
		ATcom IMME1
		ATcom RENEW
		ATcom RESET
		sleep 1
	done
	stty -F $DEV 9600 min 0 time 1
	garbage=`cat < $DEV`
	ATcom VERS?
	vers=`cat < $DEV`
	ATcom NAME?
	name=`grep NAME: < $DEV`
	if [ $? -eq 0 ]; then
		module=`echo $name | sed -n 's/OK+NAME://p'`
		echo "found $module on port $DEV" | tee -a HM10Init.log
		echo "software version: $vers" | tee -a HM10Init.log
		break
	fi
	if [ "$module" != "" ]; then
		break
	fi
done
if [ "$module" == "" ]; then
	exit 1
fi

echo "change baudrate to 115200" | tee -a HM10Init.log
ATcom BAUD4
ATcom RESET
sleep 1
stty -F $DEV 115200 min 0 time 1

echo "apply settings" | tee -a HM10Init.log
ATcom IMME1
ATcom NAMEkoboXCSoar
ATcom SHOW1
ATcom COMP1
ATcom NOTI1
ATcom 128B0
ATcom UUID0xFFE1
ATcom CHAR0xFFE1
ATcom ROLE1

echo "run scan for BLE devices" | tee -a HM10Init.log
garbage=`cat < $DEV`
sleep 1
ATcom DISC?
sleep 10
xctracer=`grep XC-Tracer < $DEV`
if [ $? -eq 0 ]; then
	echo "$xctracer" | tee -a HM10Init.log
	# strip garbage from mac address
	macaddr=$xctracer
	macaddr=`echo "$macaddr" | sed 's/OK+DISCS//'`
	macaddr=`echo "$macaddr" | sed 's/OK+NAME:XC-Tracer//'`
	macaddr=`echo "$macaddr" | sed 's/OK+DISC://'`
	macaddr=`echo "$macaddr" | sed 's/OK+DISN://'`
	macaddr=`echo "$macaddr" | sed 's/OK+DIS0://'`
	macaddr=`echo "$macaddr" | sed 's/OK+DIS1://'`
	macaddr=`echo "$macaddr" | sed 's/OK+DIS2://'`
	macaddr=`echo "$macaddr" | sed 's/\r//'`
	echo "found XC-Tracer with mac address: $macaddr" | tee -a HM10Init.log
	ATcom IMME0
	printf "AT+CO1%s" $macaddr > $DEV
	sleep 5
	answer=`grep OK+CONN < $DEV`
	if [ $? -eq 0 ]; then
		echo "connected to the XC-Tracer" | tee -a HM10Init.log
	else
		echo "couldn't connect to XC-Tracer" | tee -a HM10Init.log
		echo "try rerun script" | tee -a HM10Init.log
	fi
else
	echo "no XC-Tracer found to connect to" | tee -a HM10Init.log
fi