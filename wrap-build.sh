#!/bin/sh -e

. ./test-config.sh
test_dir() {
    dir=$1
    fqbn=$2
    curl -X POST -H "Accept: application/json" -d "$(./dir-to-json.pl \"${dir}\" \${fqbn}\")" ${compiler_url}
}

inopath=$1
shift || true

fqbn=$1
shift || true

if [ -z "${fqbn}" ]
then
    echo "Usage: $0 [path-to-ino-directory] [fqbn name]"
    echo "For example: $0 arduino:sam:arduino_due_x arduino:avr:uno"
    exit 1
fi

# Strip off leading dots
inopath=$(readlink -f "${inopath}" | sed "s|$(pwd)/||g")/

cbout=/tmp/cb.bin
arduino_logfile=/tmp/arduino-log.txt
arduino_err_logfile=/tmp/arduino-err-log.txt
cb_logfile=/tmp/cb-log.txt
cb_err_logfile=/tmp/cb-err-log.txt
logfmt="%-30s  %30s  %s\n"

arduino_pass=1
codebender_pass=1
diff_ok=0

cmd="arduino --verify --board ${fqbn} --verbose --preserve-temp-files ${inopath}"

if ! ${cmd}/*.ino > "${arduino_logfile}" 2> "${arduino_err_logfile}"
then
    arduino_pass=0
    sed -i '1,5d' "${arduino_err_logfile}"
    sed -i '$d' "${arduino_err_logfile}"
    sed -i "s|$(pwd)/${inopath}||g" "${arduino_err_logfile}"
    sketchname=$(basename ${inopath})
    sed -i "s/${sketchname}/(sketch file) ${sketchname}.ino/g" "${arduino_err_logfile}"
    sed -i 's/\.ino\.ino/.ino/g' "${arduino_err_logfile}"
fi
objtxt=$(grep '/tmp/build' "${arduino_logfile}" | tail -n 1 | rev)
rm -f "${arduino_logfile}"

binfile=$(echo "${objtxt}" | awk '{print $1}' | rev | cut -d'"' -f2)
elffile=$(echo "${objtxt}" | awk '{print $2}' | rev | cut -d'"' -f2)
tmppath=$(echo "${elffile}" | cut -d'"' -f2 | rev | cut -f1 -d/ --complement | rev)

./test-dir.sh "${inopath}" "${fqbn}" 2> /dev/null > "${cb_logfile}"

if [ "$(jq .output < "${cb_logfile}")" = "null" ] || [ -z "${binfile}" ] || [ -z "${elffile}" ]
then
    codebender_pass=0
    jq .message < "${cb_logfile}" | sed 's/^.//' | sed 's/.$//g' | perl -ne 's/\\n/\n/g; print' | perl -ne 's/\\r/\r/g; print' > "${cb_err_logfile}"
else
    jq .output < "${cb_logfile}" | sed 's/^.//' | sed 's/.$//g' | perl -ne 's/\\n/\n/g; print' | perl -ne 's/\\r/\r/g; print' > "${cbout}"

    # Convert from base64 to binary, if necessary
    if base64 -d < "${cbout}" > "${cbout}".bin 2> /dev/null
    then
        mv "${cbout}".bin "${cbout}"
    fi

    if [ -e "${binfile}" ] && [ -e "${cbout}" ] && diff -wBq "${binfile}" "${cbout}" > /dev/null
    then
        diff_ok=1
    fi
fi

if [ ${diff_ok} -eq 1 ]
then
    printf "${logfmt}" "OK" "${fqbn}" "${inopath}"
    exit 0
elif [ ${arduino_pass} -eq 1 -a ${codebender_pass} -eq 1 ]
then
    printf "${logfmt}" "DIFFERENT OUTPUT" "${fqbn}" "${inopath}"
    exit 1
elif [ ${arduino_pass} -eq 0 -a ${codebender_pass} -eq 0 ]
then
    if [ -e "${arduino_err_logfile}" -a -e "${cb_err_logfile}" ] && diff -wBq "${arduino_err_logfile}" "${cb_err_logfile}" > /dev/null
    then
        printf "${logfmt}" "OK (BOTH FAILED)" "${fqbn}" "${inopath}"
        exit 0
    else
        printf "${logfmt}" "BOTH FAILED, DIFFERENTLY" "${fqbn}" "${inopath}"
        exit 1
    fi
elif [ ${arduino_pass} -eq 0 ]
then
    printf "${logfmt}" "ARDUINO FAILED" "${fqbn}" "${inopath}"
    exit 1
else
    printf "${logfmt}" "CODEBENDER FAILED" "${fqbn}" "${inopath}"
    exit 1
fi
