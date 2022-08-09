# Caliper Tutorial

Caliper is an instrumentation and performance profiling library for C, C++, and
Fortran that lets you integrate performance measurement capabilities directly
into your code. It is primarily designed for HPC codes, with support for MPI,
OpenMP, CUDA, and HIP programming models.

## Caliper use cases

Caliper is great for:

### Lightweight always-on profiling

You can enable profiling within the application, for example to create a
simple performance report every time your program runs:

    Path                                       Time (E) Time (I) Time % (E) Time % (I)
    main                                       0.008341 1.024472   0.812121  99.747630
      lulesh.cycle                             0.000055 1.016131   0.005355  98.935509
        LagrangeLeapFrog                       0.000053 1.016066   0.005160  98.929181
          CalcTimeConstraintsForElems          0.001533 0.001533   0.149260   0.149260
          LagrangeElements                     0.000256 0.155134   0.024925  15.104609
            ApplyMaterialPropertiesForElems    0.001004 0.087512   0.097754   8.520599
              EvalEOSForElems                  0.030174 0.086508   2.937889   8.422844
                CalcEnergyForElems             0.056334 0.056334   5.484955   5.484955
            CalcQForElems                      0.020190 0.029334   1.965798   2.856102
              CalcMonotonicQForElems           0.009144 0.009144   0.890305   0.890305
            CalcLagrangeElements               0.000825 0.038032   0.080326   3.702982
              CalcKinematicsForElems           0.037207 0.037207   3.622656   3.622656
          LagrangeNodal                        0.003753 0.859346   0.365411  83.670151
            CalcForceForNodes                  0.000642 0.855593   0.062508  83.304741
              CalcVolumeForceForElems          0.001580 0.854951   0.153837  83.242232
                CalcHourglassControlForElems   0.772238 0.820102  75.188888  79.849162
                  CalcFBHourglassForceForElems 0.047864 0.047864   4.660274   4.660274
                IntegrateStressForElems        0.033269 0.033269   3.239233   3.239233
        TimeIncrement                          0.000010 0.000010   0.000974   0.000974

### Analyzing MPI transfers and GPU activities

Caliper's MPI and CPU measurement functionality lets you track
MPI functions, host<->device memory copies, and GPU kernels. For MPI
programs, Caliper automatically collects and aggregates performance data
from all ranks.

### Automated performance data collection and analysis

Caliper performance measurements are easily scriptable, which makes it
ideally suited for automated performance data collection workflows.
Moreover, Caliper can automatically record custom program metadata describing
each run, enabling performance comparisons across large collections of runs -
ideal for performance regression testing, scalability studies, or exploring
different program configurations.

Caliper can write a variety of machine-readable output formats that allow
you to create custom analysis scripts in Python, for example with the
[Hatchet](https://github.com/LLNL/hatchet) call-path analysis framework:

![Analyzing Caliper data in Hatchet](img/hatchet_screenshot.png)

### User instrumentation for third-party tools

Caliper provides connectors to forward Caliper instrumentation to third-party
tools like NVidia NSight or AMD rocprof. This way, Caliper can serve as a
common instrumentation API.

### Custom analyses

Caliper provides highly flexible instrumentation APIs and measurement
building blocks to create highly specialized performance analysis
solutions. However, this is beyond the scope of this tutorial - here, we'll
focus on Caliper's high-level source-code instrumentation API and built-in
turnkey measurement recipes.

## Getting started

This tutorial repository comes with a copy of Caliper and scripts to configure
and build Caliper and the tutorial examples - see the
[tutorial setup](#tutorial-setup) instructions below.

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
in the documentation to learn more.

### Tutorial setup

Clone the tutorial repository, then source `setup-env.sh` to build the tutorial
examples:

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

## Resources

You can find the Caliper Github repository here:
<https://github.com/LLNL/Caliper>.

The main Caliper documentation site is here:
<https://software.llnl.gov/Caliper/index.html>.

For general *questions and comments*, please use the Github discussion page:
<https://github.com/LLNL/Caliper/discussions>.

For *bug reports*, please use the Github issue tracker:
<https://github.com/LLNL/Caliper/issues>.

## Tutorial contents

* [Region profiling](region_profiling.md) covers basic source-code instrumentation and performance profiling with Caliper.

* [Profiling MPI programs](profiling_mpi.md) covers performance profiling of MPI programs.

* [Recording metadata](recording_metadata.md) covers automatic program metadata recording with the Adiak library.

* [The ConfigManager API](configmanager.md) covers the ConfigManager profiling control API.

* [Analyzing data with Hatchet](recording_hatchet.md) shows how to record data for custom analyses with [Hatchet](https://github.com/LLNL/hatchet).

* [Analyzing CUDA codes](analyzing_cuda_codes.md) shows options to profile CUDA programs with Caliper.