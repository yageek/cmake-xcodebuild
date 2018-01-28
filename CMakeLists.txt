cmake_minimum_required(VERSION 3.9)

include_directories(lib/include)
add_library(mylib STATIC lib/src/lib.cpp)