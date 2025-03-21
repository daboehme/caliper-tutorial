# Recording Program Metadata

Caliper is often used for performance comparison studies involving large
collections of runs - for example, automatic performance regression testing,
scaling studies, or comparing different program configurations. To that end,
Caliper can store metadata name-value pairs to describe and distinguish
performance profiles from different runs.

There are several complementary ways to record metadata name-value pairs
in a Caliper profile:

* Using the [Adiak](https://github.com/LLNL/Adiak) library
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

## Using Adiak

Caliper works together with [Adiak](https://github.com/LLNL/Adiak), a C/C++
library to record program metadata. Detailed documentation for Adiak is
available [here](https://software.llnl.gov/Adiak). This section covers basic
use of Adiak for recording run metadata in an application.

To use Adiak, an application first initializes Adiak and then registers
name-value pairs with Adiak's data collection API.
Caliper automatically imports all name-value pairs collected with Adiak as run
metadata in .cali or .json output files. It can also be printed in text-based
recipes like runtime-report with the `print.metadata` option, e.g.
`CALI_CONFIG=runtime-report,print.metadata`.

### Adding Adiak to an application build system

Like Caliper, Adiak provides a CMake package file. The Adiak CMake package
contains the `adiak::adiak` target, which should be linked to the target code:

    find_package(adiak)
    target_link_libraries(basic_example adiak::adiak)

The Adiak CMake package file lives in `lib/cmake/adiak` inside the Adiak
installation directory. Set `-Dadiak_DIR` to point CMake to the Adiak package:

    $ cmake -Dadiak_DIR=/path-to-adiak/lib/cmake/adiak

C++ source files using Adiak should include `adiak.hpp`. C sources should
include `adiak.h`.

### Initializing and finalizing Adiak

Adiak should be initialized with `adiak::init(void*)` (in C++) or
`adiak_init(void*)` (in C). The initialization function takes a pointer to
an MPI communicator, or `nullptr` in a non-MPI program. Initializing
Adiak with an MPI communicator allows it to collect certain MPI-specific
information, such as the MPI job size and MPI library version.

At exit, Adiak should be finalized with `adiak::fini()` in C++ or `adiak_fini()`
in C. Calling fini is important for collecting end-of-process data (such as job
runtime) and flushing data. If used in an MPI-enabled adiak, then fini should be
called before MPI_Finalize():

```c++
#include <adiak.hpp>

int main(int argc, char* argv[])
{
    MPI_Init(&argc, &argv);
    MPI_Comm adk_comm = MPI_COMM_WORLD;
    // Pass a pointer to an MPI communicator or NULL to skip MPI support
    adiak::init(&adk_comm);
    // ...
    adiak::fini(); // Call adiak::fini() before MPI_Finalize
    MPI_Finalize();
}
```

### Recording name-value pairs

Adiak has two types of functions:

* An implicit interface to collect system-level values stored under standardized names
* An explicit interface to collect application-level data under user-defined names

The implicit interface has a set of functions like `adiak::launchdate()` or
`adiak::user()` to collect system-provided information like the launch date or
user name. A complete list of functions is available in the Adiak
documentation. We recommend using the convenient collect_all shorthand, which
collects all available implicit Adiak variables:

```c++
bool adiak::collect_all(); // C++ version to collect all implicit Adiak variables
int adiak_collect_all(); // C version
```

Program-specific data can be recorded with the `adiak::value` template in C++.
It takes two required and two optional parameters:

* The name under which the value is stored
* The value. Adiak accepts many C++ datatypes, including compound types like STL vectors.
* (Optional) a category. Typical run metadata should use the default `adiak_general` category.
* (Optional) a user-defined subcategory. Typically left empty.

```c++
template<typename T>
bool value(std::string name, T value, int category = adiak_general, std::string subcategory = "")
```

Adiak's internal type system supports many common datatypes, including
integrals (integers and floating-point values), strings, UNIX time objects,
as well as compound types like lists and tuples. There are also specialized
types such as "path" and "version" for strings that represent file paths or
program versions, respectively. The `adiak::value` template automatically 
derives an appropriate Adiak datatype from the passed-in value. There are also
converters like `adiak::path` and `adiak::version` to convert strings to the
specialized "path" and "version" types. Here are a few examples:

```c++
adiak::value("maxtemperature", 70.2);
adiak::value("compiler", adiak::version("gcc@13.3.0"));
adiak::value("input_file", adiak::path("/home/user/in.dat"));

std::array<int, 3> dims = { 8, 8, 16 };
adiak::value("dimensions", dims);
```

In C, adiak provides the `adiak_namevalue` function, which uses a printf-style
type descriptor to describe the desired datatype:

```c
int adiak_namevalue(const char *name, int category, const char *subcategory, const char *typestr, ...);
```

Supported data types include integers (`%d`, `%u`), strings (`%s`), specialized 
strings like program versions (`%v`), and even compound types like arrays and
structs:

```c
adiak_namevalue("numrecords", adiak_general, NULL, "%d", 10);
adiak_namevalue("buildcompiler", adiak_general, NULL, "%v", "gcc@4.7.3");

double gridvalues[] = { 5.4, 18.1, 24.0, 92.8 };
adiak_namevalue("gridvals", adiak_general, NULL, "[%f]", gridvalues, 4);

struct { int pos; const char *val; } letters[3] = { {1, 'a'}, {2, 'b'}, {3, 'c'} };
adiak_namevalue("alphabet", adiak_general, NULL, "[(%u, %s)]", letters, 3, 2);
```

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
    adiak::collect_all();

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
