# A Caliper Tutorial

This repository contains tutorial materials for 
[Caliper](https://github.com/LLNL/Caliper), a performance instrumentation and
profiling library.

The repository contains submodules. Clone with `--recursive` to check out all 
submodules:

    $ git clone --recursive https://github.com/daboehme/caliper-tutorial

## Setting up the tutorial environment

Use the `build.sh` or `setup-env.sh` scripts to build Caliper and the tutorial 
examples. 

Build requirements:

* A C++ compiler
* CMake 3.17+
* MPI (optional)

Sourcing `setup-env.sh` builds the tutorial examples, if they have not been 
built yet, and put them in `$PATH`:

    $ . setup-env.sh
    [...]
    Done! /home/example/caliper-tutorial/install/default/bin added to PATH

There are different build configurations to support optional features: 
*default* is a basic version without optional dependencies, and *mpi* builds
versions with MPI support. You can select a build configuration with an
argument to `setup-env.sh`, e.g.:

    $ . setup-env.sh mpi

to build the *mpi* build config.

## Tutorial contents

Follow the tutorial contents in [tutorial/README.md](tutorial/README.md).

# Release

This material is part of Caliper. See 
[LICENSE](https://github.com/LLNL/Caliper/blob/master/LICENSE) 
for details.

``LLNL-CODE-678900``