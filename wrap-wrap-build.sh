#!/bin/sh -e

fqbns="arduino:sam:arduino_due_x arduino:avr:uno"
for i in $(find . -name '*.ino')
do
    inopaths="${inopaths} "$(dirname ${i})
done

echo "fqbns: ${fqbns}"
echo "inopaths: ${inopaths}"

for inopath in ${inopaths}
do
    for fqbn in ${fqbns}
    do
        ./wrap-build.sh "${inopath}" "${fqbn}"
    done
done
