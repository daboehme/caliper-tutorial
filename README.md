# A Caliper Tutorial

This repository contains tutorial materials for 
[Caliper](https://github.com/LLNL/Caliper), a performance instrumentation and
profiling library.

**In the RADIUSS AWS tutorial environment**, run setup-env.sh to set up the
tutorial environment.

    cd /opt/caliper-tutorial
    . setup-env.sh

**Otherwise**, follow the regular instructions:
The repository contains submodules. Clone with `--recursive` to check out all 
submodules, then source `setup-env.sh` to build the codes and examples:

    git clone --recursive https://github.com/daboehme/caliper-tutorial.git
    cd caliper-tutorial
    . setup-env.sh

Build requirements:

* A C++ compiler
* Python interpreter
* CMake 3.15+
* MPI (optional)
* CUDA (optional)

Follow the tutorial contents in [tutorial/README.md](tutorial/README.md).

## Release

This material is part of Caliper. See 
[LICENSE](https://github.com/LLNL/Caliper/blob/master/LICENSE) 
for details.

``LLNL-CODE-678900``
