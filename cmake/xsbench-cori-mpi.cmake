set(CMAKE_BUILD_TYPE "Release" CACHE STRING "")

set(CMAKE_C_COMPILER "/opt/cray/pe/craype/2.6.2/bin/cc"   CACHE PATH "")
set(CMAKE_CXX_COMPILER "/opt/cray/pe/craype/2.6.2/bin/CC" CACHE PATH "")

set(XSBENCH_CUDA      Off CACHE BOOL "")
set(XSBENCH_MPI       On  CACHE BOOL "")
