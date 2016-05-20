#!/bin/sh -e

inopath=$1
shift

fqbn=$1
shift

#fqbn=arduino:sam:arduino_due_x
#fqbn=arduino:avr:uno
#inopath=01.Basics/AnalogReadSerial

cbout=/tmp/cb.bin
arduino_logfile=/tmp/arduino-log.txt
logfmt="%-30s  %30s  %s\n"

cmd="arduino --verify --board ${fqbn} --verbose --preserve-temp-files ${inopath}"
#echo "cmd: $cmd/*.ino"

if ! ${cmd}/*.ino 2> /dev/null > "${arduino_logfile}"
then
    printf "${logfmt}" "ARDUINO FAILURE" "${fqbn}" "${inopath}"
    rm "${arduino_logfile}"
    exit 0
fi
objtxt=$(grep '/tmp/build' "${arduino_logfile}" | tail -n 1 | rev)
rm -f "${arduino_logfile}"

binfile=$(echo "${objtxt}" | awk '{print $1}' | rev | cut -d'"' -f2)
elffile=$(echo "${objtxt}" | awk '{print $2}' | rev | cut -d'"' -f2)
tmppath=$(echo "${elffile}" | cut -d'"' -f2 | rev | cut -f1 -d/ --complement | rev)

#echo "objtxt: ${objtxt}"
#echo "tmppath: ${tmppath}"
#echo "elffile: ${elffile}"
#echo "binfile: ${binfile}"

./test-dir.sh ${inopath} ${fqbn} 2> /dev/null | jq .output | cut -d'"' -f2 | perl -ne 's/\\n/\n/g; print' | perl -ne 's/\\r/\r/g; print' > "${cbout}"
if base64 -d < "${cbout}" > "${cbout}".bin 2> /dev/null
then
    mv "${cbout}".bin "${cbout}"
fi

if [ -e "${binfile}" ] && [ -e "${cbout}" ] && diff -wB -q "${binfile}" "${cbout}" > /dev/null
then
    printf "${logfmt}" "OK" "${fqbn}" "${inopath}"
else
    printf "${logfmt}" "DIFFER" "${fqbn}" "${inopath}"
fi
