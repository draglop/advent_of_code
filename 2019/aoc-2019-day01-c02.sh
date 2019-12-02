#!/bin/sh

CHALLENGE=aoc-2019-day01-c02

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
    do_test "2" "12"
    do_test "2" "14"
    do_test "966" "1969"
    do_test "50346" "100756"

    do_test "2" "$(echo 12\\n)"
    do_test "968" "$(echo 1969\\n14)"
    do_test "968" "$(echo 1969\\n14\\n)"

    do_test "4928963" "$(echo 73910\\n57084\\n102852\\n134452\\n108006\\n134228\\n102765\\n60642\\n64819\\n54335\\n82480\\n135119\\n73027\\n107087\\n108254\\n111944\\n83790\\n128585\\n52889\\n53870\\n145120\\n96863\\n57105\\n97702\\n75324\\n70566\\n120914\\n95808\\n86568\\n143498\\n125093\\n71370\\n122889\\n67808\\n133643\\n52806\\n103532\\n126487\\n54807\\n121402\\n57580\\n75759\\n84225\\n102232\\n112367\\n95635\\n132871\\n102903\\n51997\\n74565\\n63674\\n97410\\n96965\\n55711\\n53547\\n117482\\n107957\\n108175\\n136622\\n144235\\n80407\\n78670\\n114870\\n145967\\n148646\\n75955\\n84293\\n129590\\n144067\\n142192\\n79117\\n123861\\n68546\\n148675\\n88932\\n91493\\n127808\\n96517\\n130687\\n137822\\n77726\\n110502\\n130509\\n98370\\n136008\\n142920\\n81358\\n112950\\n101057\\n86547\\n128714\\n135401\\n55903\\n66606\\n105404\\n55276\\n57427\\n101556\\n91111\\n79585\\n)"
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
