# The ConfigManager API

A unique feature in Caliper is the ConfigManager API, which allows you to
control profiling programmatically. We can use this to control performance
profiling through program-specific means, like a command-line argument, and
even automatically enable a profiling configuration whenever the program
runs.

## ConfigManager basics

With the ConfigManager API, you can control performance measurements 
programmatically. The ConfigManager
interprets a short configuration string that can be hard-coded
or provided by the user in some form, e.g. as a command-line parameter or
in the program's configuration file. The configuration string syntax is similar
to that for the `CALI_CONFIG` environment variable. It is explained
in detail [here](https://software.llnl.gov/Caliper/BuiltinConfigurations.html).

To access and control the built-in configurations, create a
`cali::ConfigManager` object. Add a configuration string with
`add()`, start the requested configuration channels with `start()`,
and trigger output with `flush()`. In MPI programs, the `flush()` method
must be called before `MPI_Finalize`. You can pause profiling with
`stop()` and resume it by calling `start()` again.

Our [basic example](../apps/basic_example/basic_example.cpp) creates a 
ConfigManager that accepts a profiling configuration from the first 
command-line argument:

```c++
#include <caliper/cali.h>
#include <caliper/cali-manager.h>

#include <mpi.h>

#include <iostream>

int main(int argc, char* argv[])
{
    MPI_Init(&argc, &argv);

    cali::ConfigManager mgr;

    if (argc > 1)
        mgr.add(argv[1]);
    if (mgr.error())
        std::cerr "Caliper config error: " << mgr.error_msg() << std::endl;

    // Start configured performance measurements, if any
    mgr.start();

    // ...

    // Flush output before finalizing MPI
    mgr.flush();

    MPI_Finalize();
}
```

We can now use a command-line argument instead of the `CALI_CONFIG` environment
variable to enable profiling:

    $ basic_example runtime-report
    Path        Time (E) Time (I) Time % (E) Time % (I) 
    main        0.000020 0.000224   1.998002  22.377622 
      main loop 0.000015 0.000023   1.498501   2.297702 
        bar     0.000006 0.000006   0.599401   0.599401 
        foo     0.000002 0.000002   0.199800   0.199800 
      setup     0.000181 0.000181  18.081918  18.081918 

## ConfigManager in LULESH

The LULESH example app uses ConfigManager. LULESH's command-line parsing was
extended so that the `-P` argument can be used to specify a Caliper profiling 
configuration:

    $ lulesh2.0 -i 10 -P runtime-report
    [...]
    Path                                       Time (E) Time (I) Time % (E) Time % (I) 
    main                                       0.005634 0.220264   2.527183  98.801450 
      lulesh.cycle                             0.000043 0.214630   0.019288  96.274267 
        LagrangeLeapFrog                       0.000024 0.214579   0.010765  96.251391 
          CalcTimeConstraintsForElems          0.001221 0.001221   0.547691   0.547691 
          LagrangeElements                     0.000192 0.095624   0.086123  42.893028 
            ApplyMaterialPropertiesForElems    0.000802 0.047583   0.359745  21.343794 
              EvalEOSForElems                  0.015333 0.046781   6.877759  20.984049 
                CalcEnergyForElems             0.031448 0.031448  14.106291  14.106291 
            CalcQForElems                      0.014041 0.020164   6.298220   9.044748 
              CalcMonotonicQForElems           0.006123 0.006123   2.746528   2.746528 
            CalcLagrangeElements               0.000834 0.027685   0.374098  12.418362 
              CalcKinematicsForElems           0.026851 0.026851  12.044264  12.044264 
          LagrangeNodal                        0.002574 0.117710   1.154591  52.799907 
            CalcForceForNodes                  0.000363 0.115136   0.162827  51.645315 
              CalcVolumeForceForElems          0.002500 0.114773   1.121398  51.482488 
                CalcHourglassControlForElems   0.057453 0.090250  25.771073  40.482470 
                  CalcFBHourglassForceForElems 0.032797 0.032797  14.711397  14.711397 
                IntegrateStressForElems        0.022023 0.022023   9.878620   9.878620 
        TimeIncrement                          0.000008 0.000008   0.003588   0.003588 

## ConfigManager in XSBench

The XSBench example app was similarly modified to use ConfigManager. It also 
lets you specify a profiling configuration with the `-P` command-line argument.
XSBench uses the ConfigManager C API:

```c
cali_ConfigManager mgr;
cali_ConfigManager_new(&mgr);

if (in.cali_config)
    cali_ConfigManager_add(&mgr, in.cali_config);
if (cali_ConfigManager_error(&mgr)) {
    cali_SHROUD_array errmsg;
    cali_ConfigManager_error_msg_bufferify(&mgr, &errmsg);
    fprintf(stderr, "Caliper config error: %s\n", errmsg.addr.ccharp);
    cali_SHROUD_memory_destructor(&errmsg.cxx);
}

cali_ConfigManager_start(&mgr);

/* ... */

cali_ConfigManager_flush(&mgr);
```

[Next - Analyzing data with Hatchet](recording_hatchet.md)

[Back to Table of Contents](README.md#tutorial-contents)
