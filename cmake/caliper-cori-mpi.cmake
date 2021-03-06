set(CMAKE_BUILD_TYPE "Release" CACHE STRING "")

set(CMAKE_C_COMPILER "/opt/cray/pe/craype/2.6.2/bin/cc"   CACHE PATH "")
set(CMAKE_CXX_COMPILER "/opt/cray/pe/craype/2.6.2/bin/CC" CACHE PATH "")

set(BUILD_SHARED_LIBS Off CACHE BOOL "")

set(WITH_FORTRAN   Off CACHE BOOL "")
set(WITH_ADIAK     On  CACHE BOOL "")
set(WITH_LIBUNWIND Off CACHE BOOL "")
set(WITH_NVTX      Off CACHE BOOL "")
set(WITH_CUPTI     Off CACHE BOOL "")
set(WITH_PAPI      Off CACHE BOOL "")
set(WITH_LIBDW     Off CACHE BOOL "")
set(WITH_LIBPFM    Off CACHE BOOL "")
set(WITH_SAMPLER   Off CACHE BOOL "")
set(WITH_MPI       On  CACHE BOOL "")
set(WITH_GOTCHA    On  CACHE BOOL "")
set(WITH_VTUNE     Off CACHE BOOL "")
set(WITH_PCP       Off CACHE BOOL "")

set(WITH_DOCS      Off CACHE BOOL "")
set(BUILD_TESTING  Off CACHE BOOL "")
