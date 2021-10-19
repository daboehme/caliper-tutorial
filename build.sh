#!/bin/bash -e

run-verbose()
{
    echo -e "\n#### Executing \"$@\"... ####\n"
    eval $@ || exit 1
}

SCRIPT_DIR=$(dirname ${BASH_SOURCE[0]})
ROOT_DIR=$(bash -c "cd ${SCRIPT_DIR} && pwd")

: ${BUILD_CONFIG:="default"}
: ${BUILD_DIR:="${ROOT_DIR}/build"}
: ${INSTALL_DIR:="${ROOT_DIR}/install/${BUILD_CONFIG}"}

echo "Build config:      ${BUILD_CONFIG}"
echo "Root directory:    ${ROOT_DIR}"
echo "Build directory:   ${BUILD_DIR}"
echo "Install directory: ${INSTALL_DIR}"

export CMAKE_PREFIX_PATH="${INSTALL_DIR};${CMAKE_PREFIX_PATH}"

( cd ${ROOT_DIR} ; git submodule update --init --recursive )

mkdir -p "$BUILD_DIR" || exit 1

build()
{
    echo -e "\n#### Building $1 ####\n"

    lcname=$(basename ${1,,})
    cmake_bindir="${BUILD_DIR}/build-${lcname}-${BUILD_CONFIG}"

    run-verbose cmake -B "${cmake_bindir}" \
        -C "${ROOT_DIR}/cmake/${lcname}-${BUILD_CONFIG}.cmake" \
        -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
        -S "${ROOT_DIR}/$1"

    run-verbose cmake --build   "${cmake_bindir}" --parallel 4
    run-verbose cmake --install "${cmake_bindir}"
}

for target in ${@:-"Adiak" "Caliper" "apps/LULESH"}
do
    build ${target}
done
