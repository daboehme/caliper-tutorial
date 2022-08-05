cmake_minimum_required(VERSION 3.15)
project(basic_example LANGUAGES CXX)

find_package(caliper REQUIRED)
find_package(adiak REQUIRED)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

add_executable(basic_example basic_example.cpp)
target_link_libraries(basic_example caliper adiak::adiak)

install(TARGETS basic_example DESTINATION ${CMAKE_INSTALL_BINDIR})
