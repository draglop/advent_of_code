#!/bin/sh

CHALLENGE=aoc-2019-day05-c02

do_build()
{
    exe_filename=${CHALLENGE}
    source_filename=${exe_filename}.S
    build_command="gcc -O0 -no-pie -Wall -nostdlib ${source_filename} -o ${exe_filename}"
    error_code=0
    if [ ! -e ${exe_filename} ]
    then
        echo ${build_command}
        ${build_command}
        error_code=$?
    else
        source_timestamp=$(stat --printf=%Y ${source_filename})
        exe_timestamp=$(stat --printf=%Y ${exe_filename})
        if [ ${exe_timestamp} -lt ${source_timestamp} ]
        then
            echo ${build_command}
            ${build_command}
            error_code=$?
        fi
    fi

    if [ $error_code -ne 0 ]
    then
        echo "failed to build"
        exit 1
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
    expected="${1}"
    str="${2}"
    if [ "${3}" != "" ]
    then
        str="${str} ${3}"
    fi
    cmd="./${CHALLENGE} ${str}"
    value=$($cmd)
    error_code=$?

    if [ $error_code -ne 0 ]
    then
        echo "KO: '${str}'"
        echo "program error code: $error_code"
        exit 1
    fi

    if [ "$expected" = "$value" ]
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
    # part 1 unit tests
    do_test "000000004" "4,0,99"
    do_test "000001002" "1002,6,3,6,4,0,33"
    do_test "000001002" "1002,6,-3,6,4,0,-33"
    do_test "000001001" "1001,6,3,6,4,0,96"
    do_test "000000001" "3,0,4,0,99"
    do_test "$(echo 000000004\\n000000004)" "4,0,4,0,99"
    # for extra testing we allow an optional 3rd argument that will override program input default value
    do_test "000000042" "3,0,4,0,99" "42"

    # part 1 challgenge
    do_test "$(echo 000000000\\n000000000\\n000000000\\n000000000\\n000000000\\n000000000\\n000000000\\n000000000\\n000000000\\n016574641)" "3,225,1,225,6,6,1100,1,238,225,104,0,1101,61,45,225,102,94,66,224,101,-3854,224,224,4,224,102,8,223,223,1001,224,7,224,1,223,224,223,1101,31,30,225,1102,39,44,224,1001,224,-1716,224,4,224,102,8,223,223,1001,224,7,224,1,224,223,223,1101,92,41,225,101,90,40,224,1001,224,-120,224,4,224,102,8,223,223,1001,224,1,224,1,223,224,223,1101,51,78,224,101,-129,224,224,4,224,1002,223,8,223,1001,224,6,224,1,224,223,223,1,170,13,224,101,-140,224,224,4,224,102,8,223,223,1001,224,4,224,1,223,224,223,1101,14,58,225,1102,58,29,225,1102,68,70,225,1002,217,87,224,101,-783,224,224,4,224,102,8,223,223,101,2,224,224,1,224,223,223,1101,19,79,225,1001,135,42,224,1001,224,-56,224,4,224,102,8,223,223,1001,224,6,224,1,224,223,223,2,139,144,224,1001,224,-4060,224,4,224,102,8,223,223,101,1,224,224,1,223,224,223,1102,9,51,225,4,223,99,0,0,0,677,0,0,0,0,0,0,0,0,0,0,0,1105,0,99999,1105,227,247,1105,1,99999,1005,227,99999,1005,0,256,1105,1,99999,1106,227,99999,1106,0,265,1105,1,99999,1006,0,99999,1006,227,274,1105,1,99999,1105,1,280,1105,1,99999,1,225,225,225,1101,294,0,0,105,1,0,1105,1,99999,1106,0,300,1105,1,99999,1,225,225,225,1101,314,0,0,106,0,0,1105,1,99999,1008,677,226,224,102,2,223,223,1006,224,329,101,1,223,223,108,677,677,224,102,2,223,223,1005,224,344,101,1,223,223,107,677,677,224,1002,223,2,223,1005,224,359,101,1,223,223,1107,226,677,224,1002,223,2,223,1005,224,374,1001,223,1,223,1008,677,677,224,102,2,223,223,1006,224,389,1001,223,1,223,1007,677,677,224,1002,223,2,223,1006,224,404,1001,223,1,223,8,677,226,224,102,2,223,223,1005,224,419,1001,223,1,223,8,226,226,224,102,2,223,223,1006,224,434,101,1,223,223,1107,226,226,224,1002,223,2,223,1006,224,449,101,1,223,223,1107,677,226,224,102,2,223,223,1005,224,464,101,1,223,223,1108,226,226,224,102,2,223,223,1006,224,479,1001,223,1,223,7,677,677,224,1002,223,2,223,1006,224,494,101,1,223,223,7,677,226,224,102,2,223,223,1005,224,509,101,1,223,223,1108,226,677,224,1002,223,2,223,1006,224,524,101,1,223,223,8,226,677,224,1002,223,2,223,1005,224,539,101,1,223,223,1007,226,226,224,102,2,223,223,1006,224,554,1001,223,1,223,108,226,226,224,1002,223,2,223,1006,224,569,1001,223,1,223,1108,677,226,224,102,2,223,223,1005,224,584,101,1,223,223,108,226,677,224,102,2,223,223,1005,224,599,101,1,223,223,1007,226,677,224,102,2,223,223,1006,224,614,1001,223,1,223,1008,226,226,224,1002,223,2,223,1006,224,629,1001,223,1,223,107,226,226,224,1002,223,2,223,1006,224,644,101,1,223,223,7,226,677,224,102,2,223,223,1005,224,659,1001,223,1,223,107,677,226,224,102,2,223,223,1005,224,674,1001,223,1,223,4,223,99,226"

    ## part 2 unit tests
    do_test "000000000" "3,9,8,9,10,9,4,9,99,-1,8"
    do_test "000000000" "3,9,8,9,10,9,4,9,99,-1,8 7"
    do_test "000000001" "3,9,8,9,10,9,4,9,99,-1,8 8"
    do_test "000000000" "3,9,8,9,10,9,4,9,99,-1,8 88"
    do_test "000000001" "3,9,7,9,10,9,4,9,99,-1,8 0"
    do_test "000000001" "3,9,7,9,10,9,4,9,99,-1,8 2"
    do_test "000000001" "3,9,7,9,10,9,4,9,99,-1,8 4"
    do_test "000000001" "3,9,7,9,10,9,4,9,99,-1,8 6"
    do_test "000000000" "3,9,7,9,10,9,4,9,99,-1,8 8"
    do_test "000000000" "3,9,7,9,10,9,4,9,99,-1,8 10"
    do_test "000000000" "3,3,1108,-1,8,3,4,3,99 0"
    do_test "000000000" "3,3,1108,-1,8,3,4,3,99 2"
    do_test "000000000" "3,3,1108,-1,8,3,4,3,99 4"
    do_test "000000000" "3,3,1108,-1,8,3,4,3,99 6"
    do_test "000000001" "3,3,1108,-1,8,3,4,3,99 8"
    do_test "000000000" "3,3,1108,-1,8,3,4,3,99 9"
    do_test "000000001" "3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9"
    do_test "000000000" "3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9 0"
    do_test "000000001" "3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9 1"
    do_test "000000001" "3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9 2"
    do_test "000000001" "3,3,1105,-1,9,1101,0,0,12,4,12,99,1"
    do_test "000000000" "3,3,1105,-1,9,1101,0,0,12,4,12,99,1 0"
    do_test "000000001" "3,3,1105,-1,9,1101,0,0,12,4,12,99,1 1"
    do_test "000000001" "3,3,1105,-1,9,1101,0,0,12,4,12,99,1 2"
    do_test "000000999" "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99"
    do_test "000000999" "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99 7"
    do_test "000001000" "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99 8"
    do_test "000001001" "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99 9"

    # part 2 challgenge
    do_test "015163975" "3,225,1,225,6,6,1100,1,238,225,104,0,1101,61,45,225,102,94,66,224,101,-3854,224,224,4,224,102,8,223,223,1001,224,7,224,1,223,224,223,1101,31,30,225,1102,39,44,224,1001,224,-1716,224,4,224,102,8,223,223,1001,224,7,224,1,224,223,223,1101,92,41,225,101,90,40,224,1001,224,-120,224,4,224,102,8,223,223,1001,224,1,224,1,223,224,223,1101,51,78,224,101,-129,224,224,4,224,1002,223,8,223,1001,224,6,224,1,224,223,223,1,170,13,224,101,-140,224,224,4,224,102,8,223,223,1001,224,4,224,1,223,224,223,1101,14,58,225,1102,58,29,225,1102,68,70,225,1002,217,87,224,101,-783,224,224,4,224,102,8,223,223,101,2,224,224,1,224,223,223,1101,19,79,225,1001,135,42,224,1001,224,-56,224,4,224,102,8,223,223,1001,224,6,224,1,224,223,223,2,139,144,224,1001,224,-4060,224,4,224,102,8,223,223,101,1,224,224,1,223,224,223,1102,9,51,225,4,223,99,0,0,0,677,0,0,0,0,0,0,0,0,0,0,0,1105,0,99999,1105,227,247,1105,1,99999,1005,227,99999,1005,0,256,1105,1,99999,1106,227,99999,1106,0,265,1105,1,99999,1006,0,99999,1006,227,274,1105,1,99999,1105,1,280,1105,1,99999,1,225,225,225,1101,294,0,0,105,1,0,1105,1,99999,1106,0,300,1105,1,99999,1,225,225,225,1101,314,0,0,106,0,0,1105,1,99999,1008,677,226,224,102,2,223,223,1006,224,329,101,1,223,223,108,677,677,224,102,2,223,223,1005,224,344,101,1,223,223,107,677,677,224,1002,223,2,223,1005,224,359,101,1,223,223,1107,226,677,224,1002,223,2,223,1005,224,374,1001,223,1,223,1008,677,677,224,102,2,223,223,1006,224,389,1001,223,1,223,1007,677,677,224,1002,223,2,223,1006,224,404,1001,223,1,223,8,677,226,224,102,2,223,223,1005,224,419,1001,223,1,223,8,226,226,224,102,2,223,223,1006,224,434,101,1,223,223,1107,226,226,224,1002,223,2,223,1006,224,449,101,1,223,223,1107,677,226,224,102,2,223,223,1005,224,464,101,1,223,223,1108,226,226,224,102,2,223,223,1006,224,479,1001,223,1,223,7,677,677,224,1002,223,2,223,1006,224,494,101,1,223,223,7,677,226,224,102,2,223,223,1005,224,509,101,1,223,223,1108,226,677,224,1002,223,2,223,1006,224,524,101,1,223,223,8,226,677,224,1002,223,2,223,1005,224,539,101,1,223,223,1007,226,226,224,102,2,223,223,1006,224,554,1001,223,1,223,108,226,226,224,1002,223,2,223,1006,224,569,1001,223,1,223,1108,677,226,224,102,2,223,223,1005,224,584,101,1,223,223,108,226,677,224,102,2,223,223,1005,224,599,101,1,223,223,1007,226,677,224,102,2,223,223,1006,224,614,1001,223,1,223,1008,226,226,224,1002,223,2,223,1006,224,629,1001,223,1,223,107,226,226,224,1002,223,2,223,1006,224,644,101,1,223,223,7,226,677,224,102,2,223,223,1005,224,659,1001,223,1,223,107,677,226,224,102,2,223,223,1005,224,674,1001,223,1,223,4,223,99,226 5"
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
