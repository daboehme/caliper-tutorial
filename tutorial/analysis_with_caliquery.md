# Analyzing Data with cali-query

When not using Hatchet, you can use Caliper's *cali-query* tool or Python
reader API to convert, analyze, and query Caliper performance data.

In addition to the Hatchet .json format, the *hatchet-region-profile* config
recipe has two other output format options, which you can select with the
*output.format* parameter.

The *json* output format creates a simple JSON format (different from the
JSON format that Hatchet uses) with easy-to-parse dictionary records:

    $ basic_example hatchet-region-profile,output.format=json,output=stdout
    [
    {"time":0.000750},
    {"path":"main","time":0.000023},
    {"path":"main/setup","time":0.000074},
    {"path":"main/main loop","time":0.000024},
    {"path":"main/main loop/foo","time":0.000005},
    {"path":"main/main loop/bar","time":0.000008}
    ]

The *cali* output option creates a .cali file in Caliper's "native" data
format. We can read and display this data with *cali-query*. With the
*--tree* option, *cali-query* prints a table with hierarchical region data:

    $ mpirun -n 8 lulesh2.0 -i 4 -P hatchet-region-profile,output.format=cali
    $ cali-query --tree region_profile.cali
    Path                                       mpi.rank time
    main
    |-                                               0 0.051542
    |-                                               1 0.032454
    |-                                               2 0.036181
    |-                                               3 0.037724
    |-                                               4 0.033592
    |-                                               5 0.036821
    |-                                               6 0.037938
    |-                                               7 0.056281
      lulesh.cycle
      |-                                             0 0.000044
      |-                                             1 0.000052
      |-                                             2 0.000053
      |-                                             3 0.000065
      |-                                             4 0.000055
      |-                                             5 0.000059
      |-                                             6 0.000060
      |-                                             7 0.000065
    [...]

## Complex queries with CalQL

The *event-trace* recipe records a complete event trace, i.e. a record for
each region begin and end event. With *cali-query*, we can run custom
queries in Caliper's [CalQL](https://software.llnl.gov/Caliper/calql.html)
query language on this data. As an example, here is how we compute the time in
each loop iteration in the basic_example program:

    $ basic_example event-trace,output=trace.cali
    $ cali-query -q "select iteration#main\ loop as iteration,sum(time.duration) as time group by iteration#main\ loop format table" trace.cali
    iteration time
              0.000168
            0 0.000012
            1 0.000006
            2 0.000006
            3 0.000006

This example just gives you an idea of what the query system can do. It is
most useful when creating custom configuration recipes - however, these are
outside of the scope of this tutorial.

[Next - Analyzing CUDA codes](analyzing_cuda_codes.md)

[Back to Table of Contents](README.md#tutorial-contents)