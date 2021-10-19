#!/bin/bash -e

run-verbose()
{
    echo -e "\n#### Executing \"$@\"... ####\n"
    eval $@ || exit 1
}

SCRIPT_DIR=$(dirname ${BASH_SOURCE[0]})
ROOT_DIR=$(bash -c "cd ${SCRIPT_DIR} && pwd")

: ${BUILD_DIR:="${ROOT_DIR}/build"}
: ${INSTALL_DIR:="${ROOT_DIR}/install"}
: ${BUILD_CONFIG:="default"}

echo "Build config:      ${BUILD_CONFIG}"
echo "Root directory:    ${ROOT_DIR}"
echo "Build directory:   "
echo "Install directory: ${INSTALL_DIR}"

export CMAKE_PREFIX_PATH="${INSTALL_DIR};${CMAKE_PREFIX_PATH}"

git submodule update --init --recursive

mkdir -p "$BUILD_DIR" || exit 1

build()
{
    echo "#### Building $1 ####"

    lcname=$(basename ${1,,})
    cmake_bindir="${BUILD_DIR}/build-${lcname}-${BUILD_CONFIG}"

    # Build and install Adiak
    run-verbose cmake -B "${cmake_bindir}" \
        -C "${ROOT_DIR}/cmake/${lcname}-${BUILD_CONFIG}.cmake" \
        -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
        -S "${ROOT_DIR}/$1"

    run-verbose cmake --build   "${cmake_bindir}" --parallel 4
    run-verbose cmake --install "${cmake_bindir}"
}

build Adiak
build Caliper
build apps/LULESH
