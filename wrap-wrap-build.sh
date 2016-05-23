#!/bin/sh -e

fqbns="arduino:sam:arduino_due_x arduino:avr:uno"
for i in $(find . -name '*.ino')
do
    inopaths="${inopaths} "$(dirname ${i})
done

echo "fqbns: ${fqbns}"
echo "inopaths: ${inopaths}"

some_failed=0
for inopath in ${inopaths}
do
    for fqbn in ${fqbns}
    do
        # Run the test, and let us know if it failed.
        if ! ./wrap-build.sh "${inopath}" "${fqbn}"
        then
            some_failed=1
        fi
    done
done

# Exit with an error if at least one test failed.
if [ ${some_failed} -ne 0 ]
then
    exit 1
fi
exit 0
