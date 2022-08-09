# Region Profiling

Here, you'll learn how to instrument source code and how to use Caliper's
built-in performance measurement recipes.

## Region instrumentation

Much of Caliper's functionality is built around region instrumentation. We
mark source-code regions to be measured by adding region markers to the code.
Caliper provides a high-level instrumentation API using C and C++ macros
(and Fortran functions) to mark various code constructs.

The [apps/basic_example/basic_example.cpp](../apps/basic_example/basic_example.cpp) 
program in this tutorial shows how to use the various annotation macros in a 
C++ code. Refer to the
[C example](https://github.com/LLNL/Caliper/blob/master/examples/apps/c-example.c)
and
[Fortran example](https://github.com/LLNL/Caliper/blob/master/examples/apps/fortran-example.f)
codes in the main Caliper repository for C and Fortran examples, respectively.

### Marking functions

You can use the `CALI_CXX_MARK_FUNCTION` macro for marking functions in C++
or `CALI_MARK_FUNCTION_BEGIN` and `CALI_MARK_FUNCTION_END` in C. The C++
version "closes" the region automatically at the end of the function.

```c++
#include <caliper/cali.h>

void foo()
{
    CALI_CXX_MARK_FUNCTION;
    // ...
}

void bar()
{
    CALI_MARK_FUNCTION_BEGIN;
    /* ... */
    CALI_MARK_FUNCTION_END; /* remember to mark each function exit! */
}
```

### Marking user-defined regions

Use `CALI_MARK_BEGIN` and `CALI_MARK_END` to mark arbitrary code regions
using a custom name:

```c++
#include <caliper/cali.h>

CALI_MARK_BEGIN("setup");

CALI_MARK_END("setup");
```

### Marking loops

Use `CALI_CXX_MARK_LOOP_BEGIN` and `CALI_CXX_MARK_LOOP_END` to mark a loop.
Here you need to provide a handle identifier (`loop_handle` in the example
below) as well as the loop name.
You can also mark loop iterations with the `CALI_CXX_MARK_LOOP_ITERATION`
macro to enable time-series profiling with Caliper's `loop-report` and other
profiling recipes.

```c++
#include <caliper/cali.h>

CALI_CXX_MARK_LOOP_BEGIN(loop_handle, "main loop");
for (int i = 0; i < N; ++i) {
    CALI_CXX_MARK_LOOP_ITERATION(loop_handle, i);
    // ...
}
CALI_CXX_MARK_LOOP_END(loop_handle);
```

### Best practices

The region annotations don't do much on their own - we'll need to activate a
Caliper measurement configuration at runtime to record performance data. The
region markers themselves are therefore rather lightweight and can typically
be left in the code.

A few things to keep in mind when annotating your code:

* You can mix+match the different region annotation macros.
* Caliper automatically constructs a hierarchy out of nested regions.
* Regions created with the annotation macros must be nested correctly.

Lower-level instrumentation APIs for advanced use cases are documented here:
http://llnl.github.io/Caliper/AnnotationAPI.html

## Linking the Caliper library

Caliper provides a CMake package file, so with CMake projects, we can directly
import the *caliper* CMake package and link our program with the *caliper* 
target, as shown in the [CMakeLists.txt](../apps/basic_example/CMakeLists.txt)
file of our example project:

  find_package(caliper REQUIRED)
  add_executable(basic_example basic_example.cpp)
  target_link_libraries(basic_example caliper)

Without CMake, link the `libcaliper.so` library to the target code:

  CALIPER_DIR=/path/to/caliper/installation
  g++ -I${CALIPER_DIR}/include -L${CALIPER_DIR}/lib64 -lcaliper

## Region profiling with runtime-report

With region annotations in place, we can run performance measurements. An easy
way to do this is to use one of Caliper's built-in measurement recipes.
The *runtime-report* recipe, for example, records and prints the time spent in
the annotated code regions. We can activate the built-in recipes with
the `CALI_CONFIG` environment variable. Let's try this with the basic_example
program:

    $ CALI_CONFIG=runtime-report basic_example
    Path        Time (E) Time (I) Time % (E) Time % (I)
    main        0.000022 0.000226   2.217742  22.782258
      main loop 0.000016 0.000022   1.612903   2.217742
        bar     0.000005 0.000005   0.504032   0.504032
        foo     0.000001 0.000001   0.100806   0.100806
      setup     0.000182 0.000182  18.346774  18.346774

The runtime-report prints exclusive and inclusive times (Time (E) and Time (I))
as well as the percentage of runtime (Time %) spent in each annotated region.

### Profiling options

Most of Caliper's built-in profiling recipes accept configuration parameters to
enable additional performance measurement capabilities or customize the output.
Available features include profiling of common libraries and runtime systems
like MPI, OpenMP, CUDA, and POSIX I/O, as well as additional performance
metrics.

Parameters are added behind the config name, separated by commas. For example,
the *output* parameter redirects output to a file (or stdout, or stderr):

    $ CALI_CONFIG=runtime-report,output=report.txt basic_example
    $ ls -l report.txt
    $ -rw-r--r-- 1 david users 1680 Oct 19 17:26 report.txt
    $ cat report.txt
    Path        Time (E) Time (I) Time % (E) Time % (I)
    main        0.000028 0.000227   2.578269  20.902394
      main loop 0.000016 0.000025   1.473297   2.302026
        bar     0.000007 0.000007   0.644567   0.644567
        foo     0.000002 0.000002   0.184162   0.184162
      setup     0.000174 0.000174  16.022099  16.022099

Similarly, the *region.count* parameter shows the number of times each region
was called:

    $ CALI_CONFIG=runtime-report,region.count basic_example
    Path        Time (E) Time (I) Time % (E) Time % (I) Calls
    main        0.000022 0.000173   3.081232  24.229692 1.000000
      main loop 0.000011 0.000022   1.540616   3.081232 5.000000
        bar     0.000008 0.000008   1.120448   1.120448 4.000000
        foo     0.000003 0.000003   0.420168   0.420168 4.000000
      setup     0.000129 0.000129  18.067227  18.067227 1.000000

### Getting help

There are many more options and profiling recipes available. The
`cali-query --help=<config>` command shows the list of parameters for a given
recipe:

    $ cali-config --help=runtime-report
    runtime-report
    Print a time profile for annotated regions
    Options:
      aggregate_across_ranks
        Aggregate results across MPI ranks
      calc.inclusive
        Report inclusive instead of exclusive times
    [...]

You can also run `cali-query --help=configs` for a complete list of recipes and
their parameters. Note that some of the options have additional Caliper build
dependencies.
You can find more information about Caliper's built-in measurement recipes
[here](https://software.llnl.gov/Caliper/BuiltinConfigurations.html).

[Next - Profiling an MPI program](profiling_mpi.md)

[Back to Table of Contents](README.md#tutorial-contents)
