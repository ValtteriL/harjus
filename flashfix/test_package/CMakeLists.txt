cmake_minimum_required(VERSION 3.15)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS  OFF)

project(PackageTest CXX)

find_package(flashfix CONFIG REQUIRED)
find_package(fstack REQUIRED)

add_executable(example src/example.cpp)
target_link_libraries(example flashfix::flashfix fstack::fstack)
