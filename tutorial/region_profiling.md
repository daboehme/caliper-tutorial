# Region Profiling

Here, you'll learn how to instrument source code and how to use Caliper's
built-in performance measurement recipes.

Unlike many traditional performance tools, Caliper is a library that lives as
part of the application. This way, performance analysis can always be enabled
without requiring special tool-specific workflows. Profiling can even be
always-on, say to write a basic performance report at the end of each run.

The downside to integrated performance tools is the manual effort of adding the
library to the application. Similar to any other library, Caliper has an API
that must be called by the application. In addition, Caliper works alongside
another library, Adiak, to collect application run metadata. This is extremely
useful for comparing large numbers of runs with analysis frameworks like
Thicket and TreeScape.

There are several steps to integrate Caliper into an application:

* Add Caliper (and, optionally, Adiak) to the application's build system.
* Add Caliper annotations to interesting regions of the code. These
  annotations put labels over code regions that take a relevant amount of
  time to execute.
* Decide on a policy of what level of performance analysis should be on
  by default, if any.
* Optionally, add infrastructure to allow users to specify what level
  of performance analysis they want. This could be in the form of a
  command-line argument or input deck argument. Alternatively, users can
  use the `CALI_CONFIG` environment variable to control profiling.
* Optionally, initialize Adiak and pass name/value pairs that describe
  metadata about this run, such as a problem size or set of enabled
  physics packages. We will cover metadata collection in the
  [Recording metadata](recording_metadata.md) section.
  of performance analysis they want.

Most of these steps are relatively easy and involve only a few lines of code.
Adding annotations throughout the code can be significant effort, though it
can also be done in stages with only a minimal level at the beginning and further
annotations refining the performance analysis data.

## Adding Caliper to your application build system

Caliper provides a CMake package file, so with CMake projects, you can
import the *caliper* CMake package and link our program with the *caliper*
target, as shown in the [CMakeLists.txt](../apps/basic_example/CMakeLists.txt)
file of our example project:

    find_package(caliper REQUIRED)
    add_executable(basic_example basic_example.cpp)
    target_link_libraries(basic_example caliper)

The Caliper CMake package file lives in `share/cmake/caliper` inside the
Caliper installation directory. If the Caliper installation directory is not
already in the CMake package search path you can point the CMake executable to
it with `-Dcaliper_DIR`:

    $ cmake -Dcaliper_DIR=/path/to/caliper/share/cmake/caliper

Without CMake, link the `libcaliper.so` library to the target code:

    CALIPER_DIR=/path/to/caliper/installation
    g++ -I${CALIPER_DIR}/include -L${CALIPER_DIR}/lib64 -lcaliper

C and C++ source files should include `caliper/cali.h` for the instrumentation
calls:

    #include <caliper/cali.h>

## Instrumenting regions

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

Caliper region markers are relatively lightweight, taking around 0.1-0.25
microseconds to execute depending on active measurement configurations
and options. However, it is best to focusing on high-level
code constructs when marking regions, and avoiding tight inner loops.
Other things to keep in mind when annotating your code:

* You can mix+match the different region annotation macros.
* Caliper automatically constructs a hierarchy out of nested regions.
* Regions created with the annotation macros must be nested correctly.

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

Caliper supports region levels to allow collection of profiling data at different
granularities. The default regions have region level 0 (the finest level).
Caliper also provides *phase* region macros to mark larger program phases, such
as a physics package in a multi-physics code. Phase regions have region level 4.

```c++
CALI_MARK_PHASE_BEGIN("hydrodynamics");
// ...
CALI_MARK_PHASE_END("hydrodynamics");
```

Use the `level` option for the built-in configuration to select the desired
measurement granularity level. For example `runtime-report,level=phase`
will only measure regions that have at least "phase" level.

### Marking loops

Use `CALI_CXX_MARK_LOOP_BEGIN` and `CALI_CXX_MARK_LOOP_END` to mark a loop.
Here you need to provide a handle identifier (`loop_handle` in the example
below) as well as the loop name.
The `CALI_CXX_MARK_LOOP_ITERATION` macro then marks the loop iterations.
This enables loop profiling with Caliper's `loop-report` config or
`loop.stats` option.

```c++
#include <caliper/cali.h>

CALI_CXX_MARK_LOOP_BEGIN(loop_handle, "main loop");
for (int i = 0; i < N; ++i) {
    CALI_CXX_MARK_LOOP_ITERATION(loop_handle, i);
    // ...
}
CALI_CXX_MARK_LOOP_END(loop_handle);
```

## Collecting performance data

With region annotations in place, we can run performance measurements using
Caliper's built-in measurement recipes. The recipes specify what is being measured
and how the performance data is aggregated and reported. Some recipes produce
simple human-readable reports, while others record profile or trace data for
offline processing.

The measurement recipes can be enabled with the `CALI_CONFIG` environment variable
or the [ConfigManager](configmanager.md) API. By default no measurements are active.

As a simple example, the *runtime-report* recipe records and prints the time spent in
the annotated code regions. Let's try it with the `basic_example` program:

    $ CALI_CONFIG=runtime-report basic_example
    Path        Time (E) Time (I) Time % (E) Time % (I)
    main        0.000022 0.000226   2.217742  22.782258
      main loop 0.000016 0.000022   1.612903   2.217742
        bar     0.000005 0.000005   0.504032   0.504032
        foo     0.000001 0.000001   0.100806   0.100806
      setup     0.000182 0.000182  18.346774  18.346774

In a non-MPI program, runtime-report prints exclusive and inclusive times (Time (E)
and Time (I)) as well as the percentage of runtime (Time %) spent in each annotated
region. In an MPI program, it will print the average, minimum, maximum, and total
time spent in each region over all MPI ranks.

### Profiling options

Caliper profiling recipes accept many configuration parameters to
enable additional performance measurement features or customize the output.
Such features include profiling of common libraries and runtime systems
like MPI, OpenMP, CUDA, and POSIX I/O, as well as additional performance
metrics.

Parameters are added in the configuration string behind the recipe
name, separated by commas. Here, we're adding the *output* option to
redirect output to `report.txt` instead of stdout, and the *region.count*
option to show how often each region was called:

    $ CALI_CONFIG=runtime-report,output=report.txt basic_example
    $ ls -l report.txt
    $ -rw-r--r-- 1 david users 1680 Oct 19 17:26 report.txt
    $ cat report.txt
    Path        Time (E) Time (I) Time % (E) Time % (I) Calls
    main        0.000009 0.000291   2.205651  71.528187     1
      setup     0.000255 0.000255  62.652775  62.652775     1
      main loop 0.000004 0.000027   1.013912   6.669761     5
        foo     0.000022 0.000022   5.447811   5.447811     4
        bar     0.000001 0.000001   0.208039   0.208039     4

There are many more options and profiling recipes available. The
`cali-query --help=<config>` command shows the list of parameters for a given
recipe:

    $ cali-config --help=runtime-report
    runtime-report
     Print a time profile for annotated regions
      Options:
       aggregate_across_ranks Aggregate results across MPI ranks
       calc.inclusive         Report inclusive instead of exclusive times
       exclude_regions        Do not take snapshots for the given region names/patterns.
       include_branches       Only take snapshots for branches with the given region names.
       include_regions        Only take snapshots for the given region names/patterns.
       level                  Minimum region level that triggers snapshots
    [...]

You can also run `cali-query --help=configs` for the list of available recipes.
Note that some of the options have additional Caliper build
dependencies.
You can find more information about Caliper's built-in measurement recipes
[here](https://software.llnl.gov/Caliper/BuiltinConfigurations.html).

### Diagnostics

You can enable Caliper diagnostics with the `CALI_LOG_VERBOSITY` environment
variable. It is set to 0 by default to disable any Caliper log output except
for critical errors. Increasing the log level shows what Caliper is doing,
which can be very helpful for diagnosing problems or submitting bug reports:

    $ CALI_CONFIG=runtime-report CALI_LOG_VERBOSITY=1 basic_example
    == CALIPER: Initialized
    == CALIPER: Creating channel default
    == CALIPER: default: No services enabled, default channel will not record data.
    == CALIPER: Creating channel builtin.configmgr
    == CALIPER: builtin.configmgr: Registered MPI service
    == CALIPER: builtin.configmgr: Registered mpiflush service
    == CALIPER: Creating channel runtime-report
    == CALIPER: runtime-report: Registered aggregation service
    == CALIPER: runtime-report: Registered event trigger service
    == CALIPER: runtime-report: Registered report service
    == CALIPER: runtime-report: Registered timestamp service
    == CALIPER: Registered builtin ConfigManager
    == CALIPER: Finalizing ...
    == CALIPER: default: Flushing Caliper data
    == CALIPER: Releasing channel default
    == CALIPER: builtin.configmgr: Flushing Caliper data
    == CALIPER: runtime-report: Flushing Caliper data
    == CALIPER: runtime-report: Aggregate: flushed 6 snapshots.
    Path        Time (E) Time (I) Time % (E) Time % (I)
    main        0.000020 0.000120   2.427184  14.563107
      main loop 0.000025 0.000036   3.033981   4.368932
        bar     0.000006 0.000006   0.728155   0.728155
        foo     0.000005 0.000005   0.606796   0.606796
      setup     0.000064 0.000064   7.766990   7.766990
    == CALIPER: Releasing channel builtin.configmgr
    == CALIPER: Releasing channel runtime-report
    == CALIPER: Finished

## Summary

* Use Caliper annotation macros like CALI_MARK_BEGIN and CALI_MARK_END to instrument user-defined code regions
* Use the `CALI_CONFIG` environment variable to activate one of Caliper's built-in measurement recipes
* The `runtime-report` recipe collects and prints the time in the instrumented regions
* You can add additional options like `region.count` to most recipes

[Next - Recording Program Metadata](recording_metadata.md)

[Back to Table of Contents](README.md#tutorial-contents)
