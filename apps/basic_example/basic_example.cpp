#include <caliper/cali.h>
#include <caliper/cali-manager.h>

#include <adiak.hpp>

#include <iostream>

void foo()
{
    //   Mark function "foo" as a Caliper region. Automatically closes at the
    // end of the function.
    CALI_CXX_MARK_FUNCTION;
    // ...
}

void bar()
{
    //   Mark function "bar" as a Caliper region using explicit begin/end
    // markers. These also work in C.
    CALI_MARK_FUNCTION_BEGIN;
    // ...
    CALI_MARK_FUNCTION_END;
}

int main(int argc, char* argv[])
{
    // MPI_Init(&argc, &argv);

    //   (Optional) Create a ConfigManager object to configure Caliper
    // profiling channels programmatically. We can now pass profiling
    // configurations on the command line, e.g.
    //     "$ basic_example runtime-report"
    //   Alternatively, we can use the CALI_CONFIG environment variable
    // to configure profiling, e.g.
    //     "$ CALI_CONFIG=runtime-report basic_example"
    cali::ConfigManager mgr;

    if (argc > 1)
        mgr.add(argv[1]);
    if (mgr.error()) {
        std::cerr << "Caliper config error: " << mgr.error_msg() << std::endl;
        return 1;
    }

    // Start the configured profiling channels, if any
    mgr.start();

    // Mark function "main" after starting the configured profiling channels
    CALI_MARK_FUNCTION_BEGIN;

    // Mark user-defined region "setup"
    CALI_MARK_BEGIN("setup");

    const int N = 4;

    //   (Optional) Record some program metadata with Adiak. This lets us
    // store environment and program configuration information together with
    // the performance data.
    adiak::hostname();
    adiak::launchdate();
    adiak::value("iterations", N);

    CALI_MARK_END("setup");

    // Mark "main loop" loop and iterations
    CALI_CXX_MARK_LOOP_BEGIN(loop_handle, "main loop");
    for (int i = 0; i < N; ++i) {
        CALI_CXX_MARK_LOOP_ITERATION(loop_handle, i);

        foo();
        bar();
    }
    CALI_CXX_MARK_LOOP_END(loop_handle);

    CALI_MARK_FUNCTION_END;

    // Flush output of configured profiling channels
    mgr.flush();

    // In an MPI code, flush profiling output before MPI_Finalize().
    // MPI_Finalize();
}
