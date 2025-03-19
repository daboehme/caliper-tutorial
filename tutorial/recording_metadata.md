# Recording Program Metadata

Caliper is often used for performance comparison studies involving large
collections of runs - for example, automatic performance regression testing,
scaling studies, or comparing different program configurations. To that end,
Caliper can store metadata name-value pairs to describe and distinguish
performance profiles from different runs.

There are several complementary ways to record metadata name-value pairs
in a Caliper profile:

* Using the Adiak library
* Using Caliper's metadata name-value API
* Providing metadata name-value pairs in the Caliper config string
* Reading metadata name-value pairs from a JSON file

We recommend using Adiak, which provides a user-friendly API as well as
built-in functionality to record common information provided by the OS
and runtime systems.
Generally, we recommend recording any variables that are relevant to
distinguishing and understanding the run generating the performance
profile, such as:

* The version / build date / git hash of the code
* Build information, like the compiler and optimization level used
* Versions of important libraries
* Application configuration and input parameters, such as problem size and
  decomposition settings, enabled physics packages, algorithms used, etc.
* Machine and execution information, e.g. OS version, machine name,
  date/time of the run
* Information about the kind/purpose of the run, such as a test or experiment
  name
* Application-generated figure-of-merit metrics

## The Adiak library

Caliper works together with [Adiak](https://github.com/LLNL/Adiak), a C/C++
library to record program metadata. This data helps us with comparisons across
runs - for example, comparing performance between different machines or
different program configurations.

Adiak has two types of functions. First, there is built-in functionality
to record common metadata attributes. These functions record things like
the user name, executable name, launch date, etc.:

```c
int adiak_user();  /* Makes a 'user' name/val with the real name of who's running the job */
int adiak_uid(); /* Makes a 'uid' name/val with the uid of who's running the job */
int adiak_launchdate(); /* Makes a 'launchdate' name/val with the date of when this job started */
int adiak_launchday(); /* Makes a 'launchday' name/val with date when this job started, but truncated to midnight */
int adiak_executable(); /* Makes an 'executable' name/val with the executable file for this job */
int adiak_executablepath(); /* Makes an 'executablepath' name/value with the full executable file path. */
int adiak_workdir(); /* Makes a 'working_directory' name/val with the cwd for this job */
int adiak_libraries(); /* Makes a 'libraries' name/value with the set of shared library paths. */
int adiak_cmdline(); /* Makes a 'cmdline' name/val string set with the command line parameters */
int adiak_hostname(); /* Makes a 'hostname' name/val with the hostname */
int adiak_clustername(); /* Makes a 'cluster' name/val with the cluster name (hostname with numbers stripped) */
int adiak_walltime(); /* Makes a 'walltime' name/val with the walltime how long this job ran */
int adiak_systime(); /* Makes a 'systime' name/val with the timeval of how much time was spent in IO */
int adiak_cputime(); /* Makes a 'cputime' name/val with the timeval of how much time was spent on the CPU */

int adiak_job_size(); /* Makes a 'jobsize' name/val with the number of ranks in an MPI job */
int adiak_hostlist(); /* Makes a 'hostlist' name/val with the set of hostnames in this MPI job */
int adiak_num_hosts(); /* Makes a 'numhosts' name/val with the number of hosts in this MPI job */
```

Second, there is a key-value interface for custom data.
This is useful to record program-specific information, like input parameters
and configuration settings. In C, we can do this with the `adiak_namevalue`
function. It supports many different data types and uses a printf-style type
descriptor to describe the data types. Supported data types include integers
(`%d`, `%u`), strings (`%s`), specialized strings like program versions
(`%v`), and even compound types like arrays and structs:

```c
/**
 * adiak_namevalue registers a name/value pair.  The printf-style typestr describes the type of the
 * value, which is constructed from the string specifiers above.  The varargs contains parameters
 * for the type.  The entire type describes how value is encoded.  For example:
 *
 * adiak_namevalue("numrecords", adiak_general, NULL, "%d", 10);
 *
 * adiak_namevalue("buildcompiler", adiak_general, NULL, "%v", "gcc@4.7.3");
 *
 * double gridvalues[] = { 5.4, 18.1, 24.0, 92.8 };
 * adiak_namevalue("gridvals", adiak_general, NULL, "[%f]", gridvalues, 4);
 *
 * struct { int pos; const char *val; } letters[3] = { {1, 'a'}, {2, 'b'}, {3, 'c} }
 * adiak_namevalue("alphabet", adiak_general, NULL, "[(%u, %s)]", letters, 3, 2);
 **/
int adiak_namevalue(const char *name, int category, const char *subcategory, const char *typestr, ...);
```

A simpler form is available for C++:

```c++
adiak::value("key", value);
```

This template function automatically deduces a suitable Adiak datatype from
the given `value` parameter. It works for most built-in types like integers
and strings, as well as certain compound types like `std::vector`.

## A simple example

The [basic example](../apps/basic_example/basic_example.cpp) program shows how
we record program information with Adiak in C++. We use Adiak's built-in
functionality to record the executable name, host name, and launch date, and
the `adiak::value()` function to record the selected number of
main loop iterations in this run:

```c++
#include <adiak.hpp>

adiak::executable();
adiak::hostname();
adiak::launchdate();
adiak::value("iterations", N);
```

When using CMake, we can build a program with Adiak support by adding the
`adiak::adiak` target as a dependency:

    find_package(adiak)
    target_link_libraries(basic_example adiak::adiak)

## Viewing program metadata

Caliper configuration recipes that produce machine-readable output like
*hatchet-region-profile* automatically include the collected Adiak values
in their .json or .cali output files. We can also view the recorded
metadata in *runtime-report* with the *print.metadata* option:

    $ CALI_CONFIG=runtime-report,print.metadata basic_example
    cali.caliper.version : 2.8.0
    iterations           :          4
    launchdate           : 1659921370
    hostname             : gowron.dbonet
    executable           : basic_example
    cali.channel         : runtime-report
    Path        Min time/rank Max time/rank Avg time/rank Time %
    main             0.000025      0.000025      0.000025 1.712329
      main loop      0.000014      0.000014      0.000014 0.958904
        bar          0.000002      0.000002      0.000002 0.136986
        foo          0.000002      0.000002      0.000002 0.136986
      setup          0.000111      0.000111      0.000111 7.602740

We see the recorded executable name, host name, launchdate (as a UNIX epoch
stamp), iteration count, and some Caliper-provided metadata attributes
like the Caliper version number and the profiling channel name.

## Program metadata in LULESH

In our LULESH example, we record various system and execution attributes
(system name, number of MPI ranks, etc.), as well as program configuration
settings like problem size and number of iterations. This is done in the
`RecordGlobals` function in [lulesh-util.cc](https://github.com/daboehme/LULESH/blob/adiak-caliper-support/lulesh-util.cc):

```c++
// defined in lulesh-build-metadata.cc, which is generated by cmake
extern const char* buildMetadata[][2];

void RecordGlobals(const cmdLineOpts& opts, int num_threads)
{
    adiak::user();
    adiak::launchdate();
    adiak::executablepath();
    adiak::libraries();
    adiak::cmdline();
    adiak::clustername();
    adiak::jobsize();

    adiak::value("threads", num_threads);

    adiak::value("iterations", opts.its);
    adiak::value("problem_size", opts.nx);
    adiak::value("num_regions", opts.numReg);
    adiak::value("region_cost", opts.cost);
    adiak::value("region_balance", opts.balance);

    // add build metadata
    for (size_t i = 0; buildMetadata[i][0]; ++i)
       adiak::value(buildMetadata[i][0], buildMetadata[i][1]);
}
```

We also record build information like the compiler name, which is provided
by a CMake-generated source file
([lulesh-build-metadata.cc.in](https://github.com/daboehme/LULESH/blob/adiak-caliper-support/lulesh-build-metadata.cc.in)):

```c++
const char* buildMetadata[][2] = {
  { "Compiler Name",    "@CMAKE_CXX_COMPILER_ID@" },
  { "Compiler Version", "@CMAKE_CXX_COMPILER_VERSION@" },
  { "Built by",         "@LULESH_BUILT_BY@" },
  { "Compiler Flags",   "@CMAKE_CXX_FLAGS@" },
  { 0, 0 }
};
```

At the end of the run, we record a global "figure-of-merit" as well as the
total elapsed time:

```c++
adiak::value("elapsed_time", elapsed_time);
adiak::value("figure_of_merit", 1000.0/grindTime2);
```

We can view the recorded data with in a runtime report with the
*print.metadata* option:

```
$ CALI_CONFIG=runtime-report,print.metadata lulesh2.0 -i 10
cali.caliper.version : 2.7.0-dev
figure_of_merit      : 1257.281757
elapsed_time         :    0.214749
Compiler Flags       :
Built by             : boehme3
Compiler Version     : 11.0.0.11000033
Compiler Name        : AppleClang
region_balance       :           1
region_cost          :           1
num_regions          :          11
problem_size         :          30
iterations           :          10
threads              :           1
jobsize              :           1
cluster              : condor
user                 : boehme3
cali.channel         : runtime-report
Path                                       Time (E) Time (I) Time % (E) Time % (I)
main                                       0.004968 0.219693   2.226714  98.468910
  lulesh.cycle                             0.000042 0.214725   0.018825  96.242196
    LagrangeLeapFrog                       0.000031 0.214674   0.013895  96.219337
      CalcTimeConstraintsForElems          0.001336 0.001336   0.598810   0.598810
      LagrangeElements                     0.000190 0.096224   0.085160  43.128695
        ApplyMaterialPropertiesForElems    0.000797 0.048494   0.357224  21.735564
          EvalEOSForElems                  0.015742 0.047697   7.055744  21.378340
            CalcEnergyForElems             0.031955 0.031955  14.322596  14.322596
        CalcQForElems                      0.014044 0.020171   6.294681   9.040872
          CalcMonotonicQForElems           0.006127 0.006127   2.746191   2.746191
        CalcLagrangeElements               0.000838 0.027369   0.375601  12.267098
          CalcKinematicsForElems           0.026531 0.026531  11.891497  11.891497
      LagrangeNodal                        0.002712 0.117083   1.215549  52.477937
        CalcForceForNodes                  0.000355 0.114371   0.159115  51.262387
          CalcVolumeForceForElems          0.002560 0.114016   1.147421  51.103272
            CalcHourglassControlForElems   0.056492 0.090048  25.320359  40.360541
              CalcFBHourglassForceForElems 0.033556 0.033556  15.040182  15.040182
            IntegrateStressForElems        0.021408 0.021408   9.595310   9.595310
    TimeIncrement                          0.000009 0.000009   0.004034   0.004034
```

## Program metadata in XSBench

The XSBench example app demonstrates the Adiak C API. You find the Adiak
annotations in the `record_globals` function in
[io.c](https://github.com/daboehme/XSBench/blob/caliper-support/openmp-threading/io.c):

```c
void record_globals(Inputs in, int version)
{
	adiak_cmdline();
	adiak_executable();
	adiak_clustername();
	adiak_job_size();
	adiak_launchdate();
	adiak_user();

	const char* method = in.simulation_method == EVENT_BASED ? "event" : "history";
	adiak_namevalue("method",    adiak_general, NULL, "%s", method);
	adiak_namevalue("size",      adiak_general, NULL, "%s", in.HM);
	adiak_namevalue("materials", adiak_general, NULL, "%d", 12);
	adiak_namevalue("nuclides",  adiak_general, NULL, "%d", in.n_isotopes);
	adiak_namevalue("kernel",    adiak_general, NULL, "%d", in.kernel_id);
	adiak_namevalue("threads",   adiak_general, NULL, "%d", in.nthreads);
	adiak_namevalue("version",   adiak_general, NULL, "%d", version);

	switch (in.grid_type) {
		case HASH:
			adiak_namevalue("grid",      adiak_general, NULL, "%s", "hash");
			adiak_namevalue("hash_bins", adiak_general, NULL, "%d", in.hash_bins);
			break;
		case NUCLIDE:
			adiak_namevalue("grid",      adiak_general, NULL, "%s", "nuclide");
			break;
		case UNIONIZED:
			adiak_namevalue("grid",      adiak_general, NULL, "%s", "unionized");
			break;
		default:
			break;
	}
}
```

Here, too, we record basic environment information as well as the program
configuration flags.

[Next - ConfigManager](configmanager.md)

[Back to Table of Contents](README.md)
