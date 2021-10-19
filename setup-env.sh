#!/bin/bash -e

SCRIPT_DIR=$(dirname ${BASH_SOURCE[0]})
ROOT_DIR=$(bash -c "cd ${SCRIPT_DIR} && pwd")

_build_config="${1:-default}"
_install_dir=${INSTALL_DIR:-"${ROOT_DIR}/install/${_build_config}"}

echo "Build config:      ${_build_config}"
echo "Root directory:    ${ROOT_DIR}"
echo "Install directory: ${_install_dir}"

if [ ! -d "${_install_dir}/bin" ] ; then
    BUILD_CONFIG=${_build_config} INSTALL_DIR=${_install_dir} ${ROOT_DIR}/build.sh
fi

export PATH=${_install_dir}/bin:${PATH}
export CMAKE_PREFIX_PATH="${_install_dir};${CMAKE_PREFIX_PATH}"
