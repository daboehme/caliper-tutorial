# Region Profiling

Here, you'll learn how to instrument source code and how to use Caliper's
built-in performance measurement configurations.

## Region instrumentation

Much of Caliper's functionality is built around region instrumentation. We
typically select the source-code regions to be measured manually by adding
region markers to the code. Caliper provides a high-level instrumentation API
using C and C++ macros (and Fortran functions) to mark various code
constructs.

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

Use `CALI_MARK_BEGIN` and `CALI_MARK_END` to mark arbitrary code regions
using a custom name:

```c++
#include <caliper/cali.h>

CALI_MARK_BEGIN("TestRegion");

CALI_MARK_END("TestRegion");
```

The region annotations don't do much on their own - we'll need to activate a
Caliper measurement configuration at runtime to record performance data. The
region markers themselves are therefore rather lightweight and can typically
be left in the code.

A few things to keep in mind when annotating your code:

* You can mix+match the different region annotation macros.
* Caliper automatically constructs a hierarchy out of nested regions.
* Regions created with the annotation macros must be nested correctly.

There are other macros to mark loops (we'll get to those later), and
lower-level instrumentation APIs for advanced use cases, documented here:
http://llnl.github.io/Caliper/AnnotationAPI.html


## Region instrumentation in LULESH

You'll find various function annotations in the LULESH example app in
[lulesh.cc](https://github.com/daboehme/LULESH/blob/adiak-caliper-support/lulesh.cc):

```c++
static inline
void LagrangeLeapFrog(Domain& domain)
{
   CALI_CXX_MARK_FUNCTION;
// [...]
```

We do not annotate *every* function in LULESH: typically, it is best to limit
annotations to high-level code subdivisions or specifc regions of interest to
avoid clutter and reduce instrumentation overhead.

You'll notice the line

    cali_config_set("CALI_CALIPER_ATTRIBUTE_DEFAULT_SCOPE", "process");

in the LULESH `main` function. This tells Caliper to place regions in "process
scope" by default. This way, events on sub-threads - e.g., inside OpenMP
parallel regions - will be correctly associated with the surrounding Caliper
region. If this option is used, only one thread should be creating regions.


## Region profiling

With region annotations in place, we can run performance measurements. An easy
way to do this is to use one of Caliper's built-in measurement configurations.
The *runtime-report* config, for example, records and prints the time spent in
the annotated code regions. We can activate the built-in configurations with
the `CALI_CONFIG` environment variable. Let's try this with LULESH:

    $ CALI_CONFIG=runtime-report lulesh2.0 -i 10
    [...]
    Path                                       Time (E) Time (I) Time % (E) Time % (I)
    main                                       0.008949 0.166577   5.359004  99.752680
      lulesh.cycle                             0.000050 0.157628   0.029942  94.393676
        LagrangeLeapFrog                       0.000057 0.157567   0.034134  94.357147
          CalcTimeConstraintsForElems          0.000791 0.000791   0.473681   0.473681
          LagrangeElements                     0.000168 0.074156   0.100605  44.407450
            ApplyMaterialPropertiesForElems    0.000320 0.052193   0.191628  31.255165
              EvalEOSForElems                  0.013930 0.051873   8.341817  31.063537
                CalcEnergyForElems             0.037943 0.037943  22.721720  22.721720
            CalcQForElems                      0.008000 0.013963   4.790706   8.361579
              CalcMonotonicQForElems           0.005963 0.005963   3.570873   3.570873
            CalcLagrangeElements               0.002058 0.007832   1.232409   4.690101
              CalcKinematicsForElems           0.005774 0.005774   3.457692   3.457692
          LagrangeNodal                        0.012653 0.082563   7.577100  49.441883
            CalcForceForNodes                  0.000596 0.069910   0.356908  41.864782
              CalcVolumeForceForElems          0.000621 0.069314   0.371879  41.507875
                CalcHourglassControlForElems   0.018404 0.049368  11.021019  29.563447
                  CalcFBHourglassForceForElems 0.030964 0.030964  18.542428  18.542428
                IntegrateStressForElems        0.019325 0.019325  11.572549  11.572549
        TimeIncrement                          0.000011 0.000011   0.006587   0.006587

The runtime-report prints exclusive and inclusive times (Time (E) and Time (I))
as well as the percentage of runtime (Time %) spent in each annotated region.

In an MPI build, the report prints summary statistics across all MPI processes
with the minimum, maximum, and average time per process:

    $ CALI_CONFIG=runtime-report mpirun -n 8 lulesh2.0 -i 10
    Path                                       Min time/rank Max time/rank Avg time/rank Time %
    main                                            0.006932      0.027010      0.010127  1.673192
      lulesh.cycle                                  0.000068      0.000110      0.000095  0.015654
        LagrangeLeapFrog                            0.000053      0.000066      0.000059  0.009769
          CalcTimeConstraintsForElems               0.002282      0.003061      0.002704  0.446731
          LagrangeElements                          0.000458      0.000648      0.000501  0.082857
            ApplyMaterialPropertiesForElems         0.001750      0.002363      0.002003  0.330975
              EvalEOSForElems                       0.013798      0.039726      0.023668  3.910463
                CalcEnergyForElems                  0.023149      0.098723      0.051831  8.563378
            CalcQForElems                           0.028205      0.032712      0.030043  4.963630
              CalcMonotonicQForElems                0.013401      0.016508      0.015412  2.546333
              CommMonoQ                             0.000456      0.000625      0.000501  0.082713
              CommSend                              0.012349      0.032752      0.022267  3.678991
              CommRecv                              0.000067      0.000103      0.000078  0.012970
            CalcLagrangeElements                    0.001646      0.002863      0.001948  0.321826
              CalcKinematicsForElems                0.045763      0.055270      0.050361  8.320610
          LagrangeNodal                             0.012952      0.015003      0.013905  2.297451
            CommSyncPosVel                          0.000071      0.012274      0.004784  0.790387
            CommSend                                0.000187      0.011205      0.006410  1.058991
            CommRecv                                0.000018      0.000245      0.000082  0.013465
            CalcForceForNodes                       0.002383      0.004745      0.002800  0.462634
              CommSBN                               0.001081      0.009807      0.003321  0.548651
              CommSend                              0.023369      0.062731      0.042375  7.001110
              CalcVolumeForceForElems               0.003071      0.005058      0.003812  0.629752
                CalcHourglassControlForElems        0.102635      0.116350      0.109321 18.061916
                  CalcFBHourglassForceForElems      0.081380      0.099431      0.087939 14.529164
                IntegrateStressForElems             0.038062      0.049790      0.041496  6.855882
              CommRecv                              0.000043      0.000181      0.000075  0.012433
        TimeIncrement                               0.000603      0.103159      0.063749 10.532540
      CommSBN                                       0.000012      0.007683      0.003480  0.575044
      CommSend                                      0.000138      0.019533      0.009467  1.564148
      CommRecv                                      0.000043      0.000216      0.000074  0.012185


## Profiling options

Most built-in Caliper configurations have options to modify output or enable
additional features. Options are added behind the config name, separated by
commas. For example, the *output* option redirects output to a file (or 
stdout, or stderr):

    $ CALI_CONFIG=runtime-report,output=report.txt lulesh2.0 -i 10
    [...]
    $ ls -l report.txt
    $ -rw-r--r-- 1 david users 1680 Oct 19 17:26 report.txt
    $ cat report.txt
    Path                                       Time (E) Time (I) Time % (E) Time % (I)
    main                                       0.008360 0.165988   5.024612  99.763795
      lulesh.cycle                             0.000050 0.157628   0.030052  94.739183
        LagrangeLeapFrog                       0.000048 0.157566   0.028849  94.701919
          CalcTimeConstraintsForElems          0.000722 0.000722   0.433944   0.433944
          LagrangeElements                     0.000174 0.075202   0.104579  45.198671
    [...]

Many build options for Caliper enable more profiling features, such as MPI, 
CUDA, I/O, or OpenMP profiling. For example, in an MPI-enabled build, we can 
use the *profile.mpi* option to record time in MPI functions:

    $ CALI_CONFIG=runtime-report,profile.mpi lulesh2.0 -i 10
    [...]
    Path                                       Min time/rank Max time/rank Avg time/rank Time %
    MPI_Comm_dup                                    0.027007      0.067727      0.053946  7.381235
    MPI_Finalize                                    0.000001      0.000022      0.000005  0.000650
    main                                            0.013770      0.026814      0.021420  2.930848
      MPI_Reduce                                    0.000012      0.019924      0.002567  0.351215
      lulesh.cycle                                  0.000065      0.000127      0.000078  0.010638
        LagrangeLeapFrog                            0.000050      0.000065      0.000060  0.008175
          CalcTimeConstraintsForElems               0.002313      0.008100      0.003267  0.446976
          LagrangeElements                          0.000471      0.001147      0.000631  0.086371
            ApplyMaterialPropertiesForElems         0.001704      0.003108      0.002032  0.278099
              EvalEOSForElems                       0.012401      0.040124      0.023242  3.180111
                CalcEnergyForElems                  0.027781      0.104812      0.056422  7.720016
            CalcQForElems                           0.027904      0.038862      0.031006  4.242445
              CalcMonotonicQForElems                0.014516      0.025469      0.017213  2.355238
              CommMonoQ                             0.000335      0.002198      0.000823  0.112574
                MPI_Wait                            0.000038      0.000067      0.000046  0.006294
              CommSend                              0.000691      0.001094      0.000807  0.110436
                MPI_Waitall                         0.008701      0.030753      0.022219  3.040155
                MPI_Isend                           0.000118      0.000151      0.000137  0.018779
              CommRecv                              0.000064      0.000075      0.000068  0.009253
                MPI_Irecv                           0.000075      0.000095      0.000085  0.011699
            CalcLagrangeElements                    0.001654      0.002848      0.001876  0.256720
              CalcKinematicsForElems                0.045219      0.058842      0.049670  6.796116
    [...]

There are many more options and profiling configs available. You can run
`cali-query --help=<config>` for the list of options for a given configuration:

    $ cali-config --help=runtime-report
    runtime-report
    Print a time profile for annotated regions
    Options:
      aggregate_across_ranks
        Aggregate results across MPI ranks
      calc.inclusive
        Report inclusive instead of exclusive times
      io.bytes
        Report I/O bytes written and read
      io.bytes.read
        Report I/O bytes read
      io.bytes.written
        Report I/O bytes written
      io.read.bandwidth
        Report I/O read bandwidth
      io.write.bandwidth
        Report I/O write bandwidth
      main_thread_only
        Only include measurements from the main thread in results.
      max_column_width
        Maximum column width in the tree display
      mem.bandwidth
        Record memory bandwidth using the Performance Co-pilot API
      mem.highwatermark
        Report memory high-water mark
      mem.read.bandwidth
        Record memory read bandwidth using the Performance Co-pilot API
      mem.write.bandwidth
        Record memory write bandwidth using the Performance Co-pilot API
      openmp.efficiency
        Compute OpenMP efficiency metrics
      openmp.threads
        Show OpenMP threads
      openmp.times
        Report time spent in OpenMP work and barrier regions
      output
        Output location ('stdout', 'stderr', or filename)
      print.metadata
        Print program metadata (Caliper globals and Adiak data)
      profile.cuda
        Profile CUDA API functions
      profile.kokkos
        Profile Kokkos functions
      profile.mpi
        Profile MPI functions
      region.count
        Report number of begin/end region instances
      topdown-counters.all
        Raw counter values for Intel top-down analysis (all levels)
      topdown-counters.toplevel
        Raw counter values for Intel top-down analysis (top level)
      topdown.all
        Top-down analysis for Intel CPUs (all levels)
      topdown.toplevel
        Top-down analysis for Intel CPUs (top level)

You can also run `cali-query --help=configs` for a complete list of configs and
options. Note that some of the options have additional Caliper build dependencies.
You can find more information about Caliper's built-in measurement configurations
[here](https://software.llnl.gov/Caliper/BuiltinConfigurations.html).

[Next - The ConfigManager API](configmanager.md)
[Back to Table of Contents](README.md)
