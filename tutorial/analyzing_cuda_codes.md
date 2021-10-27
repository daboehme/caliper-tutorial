# Analyzing CUDA codes

Here, you'll learn how you can analyze CUDA programs with Caliper. To follow 
along, you can build the tutorial example apps with the "cuda" build 
configuration:

    $ . setup-env.sh cuda

We will use the XSBench app for this section.

## Instrumenting XSBench

The XSBench CUDA version lets users choose between several different 
implementations of the main algorithm. Each version launches multiple different
CUDA kernels, including both XSBench's own kernels and kernels from NVidia's 
thrust library. We mark the different CUDA kernel invocations with Caliper 
region markers so we can study them individually.

Here is an exerpt from [Simulation.cu](https://github.com/daboehme/XSBench/blob/caliper-support/cuda/Simulation.cu):

```c++
// [...]
CALI_MARK_BEGIN("sampling_kernel");
sampling_kernel<<<nblocks, nthreads>>>( in, GSD );
gpuErrchk( cudaPeekAtLastError() );
gpuErrchk( cudaDeviceSynchronize() );
CALI_MARK_END("sampling_kernel");

CALI_MARK_BEGIN("count");
// Count the number of fuel material lookups that need to be performed (fuel id = 0)
int n_fuel_lookups = thrust::count(thrust::device, GSD.mat_samples, GSD.mat_samples + in.lookups, 0);
CALI_MARK_END("count");

CALI_MARK_BEGIN("partition");
// Partition fuel into the first part of the array
thrust::partition(thrust::device, GSD.mat_samples, GSD.mat_samples + in.lookups, GSD.p_energy_samples, is_mat_fuel());
CALI_MARK_END("partition");

CALI_MARK_BEGIN("lookup_kernel");
// Launch all material kernels individually (asynchronous is allowed)
nblocks = ceil( (double) n_fuel_lookups / (double) nthreads);
xs_lookup_kernel_optimization_5<<<nblocks, nthreads>>>( in, GSD, n_fuel_lookups, 0 );

nblocks = ceil( (double) (in.lookups - n_fuel_lookups) / (double) nthreads);
xs_lookup_kernel_optimization_5<<<nblocks, nthreads>>>( in, GSD, in.lookups-n_fuel_lookups, n_fuel_lookups );

gpuErrchk( cudaPeekAtLastError() );
gpuErrchk( cudaDeviceSynchronize() );
CALI_MARK_END("lookup_kernel");
// [...]
```

## Basic runtime profiling

Basic time profiling with `runtime-report` now reveals the time spent in the
different algorithmic phases. It also shows that most of the program runtime
is actually spent in initialization steps. Inside the main simulation routine,
the `lookup_kernel` phase takes by far the most time.

We can launch measurements via the ConfigManager, and modified XSBench to add
a new command-line parameter (`-P`), which lets us provide a Caliper 
configuration string.

    $ XSBench -k 4 -s small -m event -P runtime-report
    [...]
    Path                                          Time (E) Time (I) Time % (E) Time % (I) 
    main                                          0.173986 2.665342   6.527252  99.992872 
      simulation                                  0.000023 0.128070   0.000863   4.804669 
        run_event_based_simulation_optimization_4 0.004479 0.128047   0.168034   4.803807 
          verification                            0.000240 0.000240   0.009004   0.009004 
          lookup_kernel                           0.109309 0.109309   4.100832   4.100832 
          sort                                    0.010845 0.010845   0.406861   0.406861 
          count                                   0.001737 0.001737   0.065165   0.065165 
          sampling_kernel                         0.001437 0.001437   0.053910   0.053910 
      move_simulation_data_to_device              2.066417 2.066417  77.523624  77.523624 
      grid_init_do_not_profile                    0.296869 0.296869  11.137326  11.137326 

## Profiling the CUDA host-side API

We can get more information with additional profiling options. 
The `profile.cuda` option lets you profile the time spent in CUDA API functions
such as `cudaMalloc`, `cudaMemcpy`, `cudaDeviceSynchronize`, etc. You can use 
it with the `runtime-report` or `hatchet-region-profile` Caliper 
configurations. It shows that most program runtime - over 77% - is spent in 
a `cudaMalloc` inside `move_simulation_data_to_device`.

    $ XSBench -k 4 -s small -m event -P runtime-report,profile.cuda
    [...]
    Path                                             Time (E) Time (I) Time % (E) Time % (I) 
    main                                             0.178092 2.830274   6.291905  99.992228 
      simulation                                     0.000024 0.127734   0.000848   4.512781 
        run_event_based_simulation_optimization_4    0.000047 0.127710   0.001660   4.511933 
          verification                               0.000061 0.000342   0.002155   0.012083 
            cudaFree                                 0.000015 0.000015   0.000530   0.000530 
            cudaStreamSynchronize                    0.000009 0.000009   0.000318   0.000318 
            cudaMemcpyAsync                          0.000022 0.000022   0.000777   0.000777 
            cudaGetLastError                         0.000003 0.000003   0.000106   0.000106 
            cudaDeviceSynchronize                    0.000158 0.000158   0.005582   0.005582 
            cudaPeekAtLastError                      0.000008 0.000008   0.000283   0.000283 
            cudaLaunchKernel                         0.000023 0.000023   0.000813   0.000813 
            cudaMalloc                               0.000014 0.000014   0.000495   0.000495 
            cudaOccupancyMaxAct~~iprocessorWithFlags 0.000007 0.000007   0.000247   0.000247 
            cudaDeviceGetAttribute                   0.000005 0.000005   0.000177   0.000177 
            cudaGetDevice                            0.000007 0.000007   0.000247   0.000247 
            cudaFuncGetAttributes                    0.000010 0.000010   0.000353   0.000353 
          lookup_kernel                              0.000043 0.107176   0.001519   3.786477 
            cudaDeviceSynchronize                    0.107016 0.107016   3.780824   3.780824 
            cudaPeekAtLastError                      0.000003 0.000003   0.000106   0.000106 
            cudaLaunchKernel                         0.000114 0.000114   0.004028   0.004028 
    [...]
      move_simulation_data_to_device                 0.000113 2.226495   0.003992  78.661004 
        cudaDeviceSynchronize                        0.000028 0.000028   0.000989   0.000989 
        cudaPeekAtLastError                          0.000004 0.000004   0.000141   0.000141 
        cudaMemcpy                                   0.024325 0.024325   0.859391   0.859391 
        cudaMalloc                                   2.202025 2.202025  77.796491  77.796491 
      grid_init_do_not_profile                       0.297325 0.297325  10.504350  10.504350 
      cudaGetDeviceProperties                        0.000614 0.000614   0.021692   0.021692 
      cudaGetDevice                                  0.000014 0.000014   0.000495   0.000495 

## Profiling GPU activities

Another Caliper measurement recipe - `cuda-activity-report` - gives us more 
detailed information about GPU activities like kernel executions and memory
copies. The report output shows both "Host Time" and "GPU Time": The "Host Time"
shows the time spent in host-side regions on the CPU, similar to `runtime-report`.
The "GPU Time" column shows the time spent on the GPU in activities like kernel
executions for any activities that were launched at or below this node in the
region hierarchy.

The output below shows that this run took a total of 2.71 seconds (from the 
"Host Time" in `main`), and the GPU was executing 0.14 seconds worth of 
activities total ("GPU Time" in `main`). Going down the region hierarchy we
can see that most of this GPU activity (0.1077 seconds) is from the lookup 
kernel - it was launched from `cudaLaunchKernel` inside the `lookup_kernel`
Caliper region.

The "GPU %" column compares the GPU activity time with the time on the host, 
giving us an idea of the overall GPU utilization. The GPU utilization for the
program as whole was low (5.17%), but in the `simulation` region itself we 
achieved 90.7%. 

Note that the `cudaLaunchKernel` calls are asynchronous. In the example, the
`cudaLaunchKernel` call under `lookup_kernel` spends very little time on the
host, but launches 0.1 seconds worth of GPU activities. Correspondingly, we 
see that we spend 0.1 seconds on the host in `cudaDeviceSynchronize`, waiting
for the CUDA kernels to finish. Due to this asynchronous nature, the "GPU %"
metric only makes sense for regions above CUDA synchronization points, like
the `lookup_kernel` region.

    $ XSBench -k 4 -s small -m event -P cuda-activity-report
    [...]
    Path                                             Host Time GPU Time GPU %        
    main                                              2.714768 0.140372     5.170669 
      simulation                                      0.128210 0.116375    90.769106 
        run_event_based_simulation_optimization_4     0.128180 0.116375    90.790648 
          verification                                0.000370 0.000169    45.672395 
    [...]
          lookup_kernel                               0.107829 0.107756    99.932302 
            cudaDeviceSynchronize                     0.107646                       
            cudaPeekAtLastError                       0.000003                       
            cudaLaunchKernel                          0.000148 0.107756 73039.554399 
    [...]

We can use `cuda-activity-profile` instead of `cuda-activity-report` to produce
a JSON file instead of the text output that we can analyze in external tools.

    $ XSBench -k 4 -s small -m event -P cuda-activity-profile
    [...]
    $ ls *.json
    cuda_profile.json

## Viewing host<->device memory copies

We can use the `cuda.memcpy` option for `cuda-activity-report` to print the 
amount of data copied between host and device in explicit `cudaMemcpy` (and 
similar) calls.

The XSBench example app does not copy much data from GPU to CPU but does copy
252 MB from CPU to GPU in the `move_simulation_data_to_device` region.

    $ XSBench -k 4 -s small -m event -P cuda-activity-report,cuda.memcpy
    [...]
    Path                                             Host Time GPU Time GPU %        Copy CPU->GPU Copy GPU->CPU 
    main                                              2.724224 0.142380     5.226454                             
      simulation                                      0.130136 0.118380    90.966589                             
        run_event_based_simulation_optimization_4     0.130111 0.118380    90.984216                             
          verification                                0.000344 0.000171    49.608941                             
            cudaFree                                  0.000015                                                   
            cudaMemcpyAsync                           0.000028 0.000003     9.393006                    0.000004 
    [...]
          count                                       0.002818 0.001108    39.301212                             
            cudaFree                                  0.000175                                                   
            cudaStreamSynchronize                     0.000096                                                   
            cudaMemcpyAsync                           0.000293 0.000023     7.698713                    0.000096 
    [...]
      move_simulation_data_to_device                  2.120833 0.024000     1.131626                             
        cudaDeviceSynchronize                         0.000027                                                   
        cudaPeekAtLastError                           0.000004                                                   
        cudaMemcpy                                    0.024433 0.024000    98.226649    252.107056               
        cudaMalloc                                    2.096273                                                   
    [...]

## Looking at individual kernels

With the `show_kernels` option, we can see the individual CUDA `__global__` 
kernel functions that were executed. This includes the CUDA kernels invoked
by libraries like NVidia's `thrust` library in the XSBench example.

The display is "inclusive": directly under `main`, we see all kernel functions 
that were launched anywhere in the program and the total time spent in them. 
As we go down the region hierarchy, we see the exact places where the kernel
functions where launched and their runtime.

    Path                                             Kernel                                           Host Time GPU Time GPU %     
    main                                             
     |-                                                                                                2.723571 0.024071  0.883819 
     |-                                              sampling_kernel(Inputs, SimulationData)                    0.001400           
     |-                                              void thrust::cuda_cub::~~t>, thrust::plus<long>)           0.000999           
     |-                                              void thrust::cuda_cub::~~rust::plus<long>, long)           0.000087           
     |-                                              void thrust::cuda_cub::~~ub::GridEvenShare<int>)           0.000291           
     |-                                              void thrust::cuda_cub::~~icy700, int>(int*, int)           0.000583           
     |-                                              void thrust::cuda_cub::~~ub::GridEvenShare<int>)           0.002095           
     |-                                              void thrust::cuda_cub::~~ub::GridEvenShare<int>)           0.000407           
     |-                                              void thrust::cuda_cub::~~ub::GridEvenShare<int>)           0.002053           
     |-                                              void thrust::cuda_cub::~~_true_predicate>, long)           0.000177           
     |-                                              void thrust::cuda_cub::~~_true_predicate>, long)           0.000337           
     |-                                              xs_lookup_kernel_optimi~~ionData, int, int, int)           0.108182           
     |-                                              void thrust::cuda_cub::~~nt>, thrust::plus<int>)           0.000160           
     |-                                              void thrust::cuda_cub::~~thrust::plus<int>, int)           0.000007           
      simulation                                     
       |-                                                                                              0.129518 0.000025  0.019197 
       |-                                            sampling_kernel(Inputs, SimulationData)                    0.001400           
    [...]
       |-                                            void thrust::cuda_cub::~~thrust::plus<int>, int)           0.000007           
        run_event_based_simulation_optimization_4    
    [...]
          verification                               
           |-                                                                                          0.000341 0.000002  0.693529 
           |-                                        void thrust::cuda_cub::~~nt>, thrust::plus<int>)           0.000160           
           |-                                        void thrust::cuda_cub::~~thrust::plus<int>, int)           0.000007           
    [...]
            cudaLaunchKernel                         
             |-                                                                                        0.000031                    
             |-                                      void thrust::cuda_cub::~~nt>, thrust::plus<int>)           0.000160           
             |-                                      void thrust::cuda_cub::~~thrust::plus<int>, int)           0.000007           
    [...]
          lookup_kernel                              
           |-                                                                                          0.108254                    
           |-                                        xs_lookup_kernel_optimi~~ionData, int, int, int)           0.108182           
            cudaDeviceSynchronize                                                                      0.108075                    
            cudaPeekAtLastError                                                                        0.000003                    
            cudaLaunchKernel                         
             |-                                                                                        0.000144                    
             |-                                      xs_lookup_kernel_optimi~~ionData, int, int, int)           0.108182           
    [...]

[Back to Table of Contents](README.md)