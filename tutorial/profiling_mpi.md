# Profiling MPI programs

Let's look at profiling an MPI code with Caliper. As an example, we'll use the
Caliper-instrumented Lulesh proxy app that comes with this tutorial.
Make sure the MPI build config is loaded:

    $ . setup-env.sh mpi
    Build config:      mpi
    Root directory:    /home/david/src/caliper-tutorial
    Install directory: /home/david/src/caliper-tutorial/install/mpi
    Done! /home/david/src/caliper-tutorial/install/mpi/bin added to PATH

You can now launch Lulesh with your system's MPI launcher, e.g. `mpirun`.
Lulesh must be launched with a cubic power (e.g., 1, 8, 27, ...) of MPI ranks,
others like 16 or 32 will not work. It is also helpful to limit the number of
iterations for test runs with the *-i* parameter, e.g. `-i 10`:

    $ mpirun -n 8 lulesh2.0 -i 10
    Running problem size 30^3 per domain until completion
    Num processors: 8
    Total number of elements: 216000
    [...]
    Elapsed time         =       0.72 (s)
    Grind time (us/z/c)  =  2.6684406 (per dom)  (0.72047898 overall)
    FOM                  =  2998.0056 (z/s)

## Print MPI statistics with mpi-report

The *mpi-report* Caliper recipe measures and prints the number of MPI calls
and the time spent in MPI functions:

    $ CALI_CONFIG=mpireport mpirun -np 8 lulesh2.0 -i 10
    [...]
    Function      Count (min) Count (max) Time (min) Time (max) Time (avg) Time %
                          435         505   0.495476   0.669825   0.546080 77.752653
    MPI_Allreduce           9           9   0.005468   0.161736   0.107671 15.330481
    MPI_Waitall            31          31   0.004131   0.041330   0.022909  3.261873
    MPI_Comm_dup            1           1   0.000132   0.019433   0.014170  2.017622
    MPI_Wait              107         177   0.000572   0.018274   0.009785  1.393148
    MPI_Isend             107         177   0.000652   0.001401   0.001017  0.144732
    MPI_Irecv             107         177   0.000330   0.000507   0.000414  0.058875
    MPI_Barrier             1           1   0.000040   0.000403   0.000248  0.035329
    MPI_Reduce              1           1   0.000013   0.000056   0.000031  0.004449
    MPI_Finalize            1           1   0.000003   0.000010   0.000006  0.000837

## Region instrumentation in LULESH

The Lulesh version provided with this tutorial has Caliper annotations for many
top-level functions and the main loop.
You'll find various function annotations in
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

## Using runtime-report with MPI

Most Caliper measurement recipes like runtime-report work out-of-the box with
MPI programs.
In an MPI build, runtime-report prints summary statistics across
all MPI processes with the minimum, maximum, and average time per process:

    $ CALI_CONFIG=runtime-report mpirun -n 8 lulesh2.0 -i 10
    [...]
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

Furthermore, we can use the *profile.mpi* option to measure and print the time
in MPI functions inside the Lulesh region annotations:

    $ CALI_CONFIG=runtime-report,profile.mpi mpirun -n 8 lulesh2.0 -i 10
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

The *mpi.message.count* and *mpi.message.size* options collect statistics for
the number and sizes of MPI messages, respectively:

    $ CALI_CONFIG=runtime-report,mpi.message.size mpirun -n 8 lulesh2.0 -i 10
    [...]
    Path                                      [...] Msg size (min) Msg size (avg) Msg size (max)
    main
      MPI_Reduce                                          0.000000       7.000000       8.000000
      lulesh.cycle
        LagrangeLeapFrog
        [...]
            CalcQForElems
              CalcMonotonicQForElems
              CommMonoQ
                MPI_Wait                              21600.000000   21600.000000   21600.000000
              CommSend
                MPI_Waitall
                MPI_Isend                             21600.000000   21600.000000   21600.000000
              CommRecv
                MPI_Irecv
            CalcLagrangeElements
              CalcKinematicsForElems
          LagrangeNodal
            CommSyncPosVel
              MPI_Wait                                   48.000000   24152.816327   46128.000000
            CommSend
              MPI_Isend                                  48.000000   24152.816327   46128.000000
              MPI_Waitall

We can see that Lulesh sends messages with 21600 bytes inside *CalcQForElems*,
but different-sized messages from 48 up to 46128 bytes inside *LagrangeNodal*.

## Summary

Most Caliper profiling recipes work out-of-the box with MPI programs and
automatically collect and compute performance statistics across all MPI ranks.

Recipes and options for MPI profiling:

* mpi-report
  * Recipe that prints counts and time spent in MPI functions
* profile.mpi
  * Measure time in MPI functions in runtime-report etc.
* mpi.message.size
  * Collect statistics on the sizes of MPI messages
* mpi.message.count
  * Collect statistics for the number of MPI messages sent and received

[Next - Recording Program Metadata](recording_metadata.md)

[Back to Table of Contents](README.md#tutorial-contents)
