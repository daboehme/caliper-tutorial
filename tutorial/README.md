# Caliper Tutorial

Caliper is an instrumentation and performance profiling library for C, C++, and
Fortran that lets you integrate performance measurement capabilities directly
into your code. It is primarily designed for HPC codes, with support for MPI,
OpenMP, CUDA, and HIP programming models.

Caliper is great for:

* **Lightweight always-on performance profiling:** Enable profiling within the
  application, for example to create a simple performance report for every
  execution
* **Analyzing MPI and GPU activities:** Track time in MPI communication,
  host<->device memory copies, and GPU kernels. For MPI programs, Caliper
  automatically collects and aggregates performance data from all ranks.
* **Automated performance data collection and analysis:** Easy scripting
  makes Caliper ideal for automated data collection workflows. Caliper is
  the measurement backend for [Thicket](https://github.com/LLNL/thicket)
  and TreeScape, two powerful frameworks for exploratory analysis of
  performance data in Python.
* **Application instrumentation for third-party tools:** Caliper provides
  connectors to forward Caliper instrumentation to third-party tools
  like NVidia NSight or AMD rocprof. This way, Caliper can serve as a
  common instrumentation API.
* **Custom analyses:** Caliper provides a set of modular building blocks
  and APIs to create highly specialized performance analysis solutions.

This tutorial provides an overview of Caliper's region instrumentation,
run metadata collection, and built-in performance profiling capabilities.
It also demonstrates how to collect data for Thicket and TreeScape.
The [full documentation](https://software.llnl.gov/Caliper/index.html)
has more information about specific features like MPI profiling, Fortran
support, region filtering, and many more.

## Getting started

This tutorial repository comes with a copy of Caliper and three example
applications, as well as scripts to set up the tutorial environment - see
the [tutorial setup](#tutorial-setup) section below.

Generally, you can download and install Caliper either with the
[spack](https://github.com/spack/spack) package manager, or directly from the
[Caliper](https://github.com/LLNL/Caliper) github repository.
With spack, just run `spack install`:

    spack install caliper

To build and install Caliper manually, clone the repository from Github and
and run CMake:

    git clone https://github.com/LLNL/Caliper
    mkdir build && cd build
    cmake -DCMAKE_INSTALL_PREFIX=<installation directory> ..
    make install

There are many build options, some of which require additional
dependencies. See the
[build instructions](https://software.llnl.gov/Caliper/build.html)
in the main documentation to learn more.

### Tutorial setup

To set up the tutorial environment, clone the tutorial repository, then source
`setup-env.sh` to build the tutorial examples:

    git clone --recursive https://github.com/daboehme/caliper-tutorial
    cd caliper-tutorial
    . setup-env.sh

This builds the tutorial examples and puts them in `$PATH`:

    [...]
    Done! /home/example/caliper-tutorial/install/default/bin added to PATH
    $ which lulesh2.0
    /home/example/caliper-tutorial/install/default/bin/lulesh2.0

There are different build configurations to support optional features:
*default* is a basic version without optional dependencies, and *mpi* builds
versions with MPI support. You can select a build configuration with an
argument to `setup-env.sh`, e.g.:

    . setup-env.sh mpi

to build the *mpi* build config. The available configurations are:

| Config   | Description                                                     |
|----------|-----------------------------------------------------------------|
| default  | Base configuration without MPI or CUDA support                  |
| mpi      | Adds MPI support for Caliper and builds LULESH MPI version      |
| cuda     | Adds CUDA support for Caliper and builds XSBench CUDA version   |

### Example applications

The tutorial uses three Caliper-instrumented example applications to
demonstrate various Caliper capabilities:

* [Basic example](../apps/basic_example/)

    A simple example program demonstrating Caliper source-code instrumentation
    and the ConfigManager API.

* [LULESH](https://github.com/daboehme/LULESH/tree/adiak-caliper-support)

    A C++ HPC proxy app demonstrating Caliper with an MPI code.

* [XSBench](https://github.com/daboehme/XSBench/tree/caliper-support)

    A CUDA proxy application for demonstrating the use of Caliper with GPUs.

Let's get started with the first tutorial chapter - [region profiling](region_profiling.md)!

## Tutorial contents

* [Region profiling](region_profiling.md) covers source-code instrumentation and performance profiling with Caliper.

* [Recording metadata](recording_metadata.md) covers automatic program metadata recording with the Adiak library.

* [The ConfigManager API](configmanager.md) covers the ConfigManager profiling control API.

* [Recording data for Thicket](recording_for_thicket.md) shows how to record data for the Python performance data analysis frameworks [Thicket](https://github.com/LLNL/thicket), [Hatchet](https://github.com/LLNL/hatchet), and TreeScape.

* [Analyzing data with cali-query](analysis_with_caliquery.md) demonstrates the *cali-query* tool for processing Caliper data.

* [Profiling MPI programs](profiling_mpi.md) covers performance profiling of MPI programs.

* [Profiling CUDA codes](profiling_cuda.md) shows options to profile CUDA programs with Caliper.

## Additional resources

You can find the Caliper Github repository here:
<https://github.com/LLNL/Caliper>.

The main Caliper documentation site is here:
<https://software.llnl.gov/Caliper/index.html>.

For general *questions and comments*, please use the Github discussion page:
<https://github.com/LLNL/Caliper/discussions>.

For *bug reports*, please use the Github issue tracker:
<https://github.com/LLNL/Caliper/issues>.
