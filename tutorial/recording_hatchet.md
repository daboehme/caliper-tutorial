# Analyzing Data with Hatchet

[Hatchet](https://github.com/LLNL/hatchet) is a Python library for analyzing
hierarchical performance data, such as Caliper's region profiles. We can 
record data for Hatchet with Caliper's `hatchet-region-profile` config:

    $ lulesh2.0 -P hatchet-region-profile
    [...]
    $ ls region_profile.json
    region_profile.json

This produces a `region_profile.json` JSON file, which we can import into 
Hatchet. Note that you can change the filename with the `output` option:

    $ lulesh2.0 -P hatchet-region-profile,output=lulesh.json
    [...]
    $ ls lulesh.json
    lulesh.json

## Profiling options

The `hatchet-region-profile` config supports many Caliper profiling options,
including MPI and CUDA profiling:

    $ mpirun -n 8 lulesh2.0 -P hatchet-region-profile,profile.mpi,output=lulesh_mpi_x8.json
    [...]
    $ XSBench -P hatchet-region-profile,profile.cuda,output=xsbench.json
    [...]

## Importing the data

Check out the [notebook](HatchetCaliperImport.ipynb) for the example code!

We can import the JSON file into a Hatchet GraphFrame with the 
`from_caliper_json` reader:

```
>>> import hatchet
>>> gf = hatchet.GraphFrame.from_caliper_json('region_profile.json')
>>> gf.dataframe
node                                                    time  nid                             name
{'name': 'main', 'type': 'region'}                  0.005730    0                             main
{'name': 'lulesh.cycle', 'type': 'region'}          0.000041    1                     lulesh.cycle
{'name': 'LagrangeLeapFrog', 'type': 'region'}      0.000020    3                 LagrangeLeapFrog
{'name': 'CalcTimeConstraintsForElems', 'type':...  0.001254   18      CalcTimeConstraintsForElems
{'name': 'LagrangeElements', 'type': 'region'}      0.000172   10                 LagrangeElements
{'name': 'ApplyMaterialPropertiesForElems', 'ty...  0.000726   15  ApplyMaterialPropertiesForElems
{'name': 'EvalEOSForElems', 'type': 'region'}       0.015199   16                  EvalEOSForElems
{'name': 'CalcEnergyForElems', 'type': 'region'}    0.031497   17               CalcEnergyForElems
{'name': 'CalcLagrangeElements', 'type': 'region'}  0.000816   11             CalcLagrangeElements
{'name': 'CalcKinematicsForElems', 'type': 'reg...  0.026612   12           CalcKinematicsForElems
{'name': 'CalcQForElems', 'type': 'region'}         0.014272   13                    CalcQForElems
{'name': 'CalcMonotonicQForElems', 'type': 'reg...  0.006118   14           CalcMonotonicQForElems
{'name': 'LagrangeNodal', 'type': 'region'}         0.002668    4                    LagrangeNodal
{'name': 'CalcForceForNodes', 'type': 'region'}     0.000396    5                CalcForceForNodes
{'name': 'CalcVolumeForceForElems', 'type': 're...  0.002580    6          CalcVolumeForceForElems
{'name': 'CalcHourglassControlForElems', 'type'...  0.056916    8     CalcHourglassControlForElems
{'name': 'CalcFBHourglassForceForElems', 'type'...  0.032328    9     CalcFBHourglassForceForElems
{'name': 'IntegrateStressForElems', 'type': 're...  0.022024    7          IntegrateStressForElems
{'name': 'TimeIncrement', 'type': 'region'}         0.000010    2                    TimeIncrement
```

## Extracting metadata

The JSON file also contains the Adiak metadata. The metadata entries are stored
as top-level entries in the JSON object. We can access them with the JSON
reader:

```
>>> import json
>>> obj = json.load(open('region_profile.json))
>>> obj['problem_size']
'30'
```

[Next - Analyzing CUDA codes](analyzing_cuda_codes.md)

[Back to Table of Contents](README.md#tutorial-contents)