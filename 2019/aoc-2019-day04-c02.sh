#!/bin/sh

CHALLENGE=aoc-2019-day04-c02

do_build()
{
    exe_filename=${CHALLENGE}
    source_filename=${exe_filename}.S
    build_command="gcc -O0 -no-pie -Wall -nostdlib ${source_filename} -o ${exe_filename}"
    if [ ! -e ${exe_filename} ]
    then
        echo ${build_command}
        ${build_command}
    else
        source_timestamp=$(stat --printf=%Y ${source_filename})
        exe_timestamp=$(stat --printf=%Y ${exe_filename})
        if [ ${exe_timestamp} -lt ${source_timestamp} ]
        then
            echo ${build_command}
            ${build_command}
        fi
    fi
}

do_clean()
{
    if [ -e ${CHALLENGE} ]
    then
        rm -v ${CHALLENGE}
    fi
}

do_run()
{
    ./${CHALLENGE} "${1}"
}

do_test()
{
    expected="$(($1))"
    str="${2}"
    value=$(./${CHALLENGE} "${str}")
    error_code=$?

    if [ $error_code -ne 0 ]
    then
        echo "KO: '${str}'"
        echo "program error code: $error_code"
        exit 1
    fi

    if [ "$expected" -eq "$value" ]
    then
        echo "OK: '${str}'"
    else
        echo "KO: '${str}'"
        echo "expected: ${expected}, got: ${value}"
        exit 1
    fi
}

do_test_batch()
{
    do_test "1" "112233-112233"
    do_test "0" "123444-123444"
    do_test "1" "111122-111122"

    do_test "1" "112345-112345"
    do_test "1" "122345-122345"
    do_test "1" "123345-123345"
    do_test "1" "123445-123445"
    do_test "1" "123455-123455"
    do_test "1" "112222-112222"
    do_test "1" "111122-111122"
    do_test "0" "121233-121233"
    do_test "0" "111234-111234"
    do_test "0" "111134-111134"
    do_test "0" "111114-111114"
    do_test "0" "111111-111111"
    do_test "0" "111134-111134"
    do_test "1" "111122-111122"
    do_test "2" "111122-111133"
    do_test "0" "199999-200000"
    do_test "0" "111234-111234"
    do_test "0" "111231-111231"
    do_test "1" "112233-112233"
    do_test "0" "122224-122224"
    do_test "1" "112345-112345"

    do_test "299" "372037-905157"
}

if [ $# -eq 0 ]
then
    do_build
    do_test_batch
elif [ "$1" = "clean" ]
then
    do_clean
else
    do_build
    for i in "$@"
    do
        do_run "$i"
    done
fi
