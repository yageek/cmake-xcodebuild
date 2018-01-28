# Helpers for building with xcodebuild
# Once done this will define:
#   XCODE_VERSION - The Xcode build version
#   XCRUN_VERSION - The Xcode build version
#   XCODE_SDK_LIST - The list of available SDKs
#   Input: XCODEBUILD_PLATFORM and XCODEBUILD_PLATFORM_VERSION and BITCODE_ENABLED

cmake_minimum_required(VERSION 3.3)
set(CMAKE_CROSSCOMPILING TRUE)

if(DEFINED __XCODEBUILD_PLATFORM_CHOOSED)
return()
endif()

if(NOT DEFINED XCODEBUILD_PLATFORM)
  message(FATAL_ERROR "Not platform set")
endif()

set(XCODEBUILD_PLATFORM $ENV{XCODEBUILD_PLATFORM})
set(__XCODEBUILD_PLATFORM_CHOOSED TRUE CACHE BOOL "" FORCE)

option(BITCODE_ENABLED "Bitcode generation" OFF)

# First check we have xcodebuild and xcrun installed
# XCODE_VERSION and XCRUN_VERSION
execute_process(COMMAND xcodebuild -version
  OUTPUT_VARIABLE XCODEBUILD_VERSION_OUTPUT_TERM
  RESULT_VARIABLE RESULT_XCODEBUILD
  ERROR_QUIET
)

set(XCODEBUILD_VERSION_OUTPUT ${XCODEBUILD_VERSION_OUTPUT_TERM})

execute_process(COMMAND xcrun -version
  OUTPUT_VARIABLE XCRUN_VERSION_OUTPUT
  RESULT_VARIABLE RESULT_XCRUN
  ERROR_QUIET
)

if(NOT "${RESULT_XCODEBUILD}" STREQUAL "0" OR NOT "${RESULT_XCRUN}" STREQUAL "0")
  message(FATAL_ERROR "Xcode/The command-line tools does not seems to be installed.")
endif()

string(REGEX MATCH "Xcode [0-9\\.]+" XCODEBUILD_VERSION "${XCODEBUILD_VERSION_OUTPUT}")
string(REGEX REPLACE "Xcode ([0-9\\.]+)" "\\1" XCODEBUILD_VERSION "${XCODEBUILD_VERSION}")
message(STATUS "Xcode version: ${XCODEBUILD_VERSION}")

string(REGEX MATCH "xcrun version [0-9]+" XCRUN_VERSION "${XCRUN_VERSION_OUTPUT}")
string(REGEX REPLACE "xcrun version ([0-9]+)" "\\1" XCRUN_VERSION "${XCRUN_VERSION}")
message(STATUS "xcrun version: ${XCRUN_VERSION}")

# XCODE_SDK_LIST
execute_process(COMMAND xcodebuild -showsdks
  OUTPUT_VARIABLE XCODE_SDK_OUTPUT
  ERROR_QUIET
)

# set valid platform
set(VALID_PLATFORMS iOS iOSSimulator macOS tvOS tvOSSimulator watchOS watchOSSimulator CACHE STRING "The valid buildable platforms")

# Get all valid sdk
set(XCODE_SDK_LIST "" CACHE STRING "The found sdk lists")
string(REGEX MATCHALL "-sdk [a-z0-9\\.^ ]+" XCODE_SDK_OUTPUT_LIST "${XCODE_SDK_OUTPUT}")

foreach(sdk_str IN LISTS XCODE_SDK_OUTPUT_LIST) 

  string(REGEX REPLACE "-sdk ([a-z0-9\\.^ ]+)" "\\1" sdk_name "${sdk_str}")
  list(APPEND XCODE_SDK_LIST ${sdk_name})
endforeach()

# Get the sdk name from the name
if(${XCODEBUILD_PLATFORM} IN_LIST VALID_PLATFORMS)
  if("${XCODEBUILD_PLATFORM}" STREQUAL "iOS")
    set(USED_SDK_NAME "iphoneos")
  elseif("${XCODEBUILD_PLATFORM}" STREQUAL "iOSSimulator")
    set(USED_SDK_NAME "iphonesimulator")
  elseif("${XCODEBUILD_PLATFORM}" STREQUAL "macOS")
    set(USED_SDK_NAME "macosx")
  elseif("${XCODEBUILD_PLATFORM}" STREQUAL "tvOS")
    set(USED_SDK_NAME "appletvos")
  elseif("${XCODEBUILD_PLATFORM}" STREQUAL "tvOSSimulator")
    set(USED_SDK_NAME "appletvsimulator")
  elseif("${XCODEBUILD_PLATFORM}" STREQUAL "watchOS")
    set(USED_SDK_NAME "watchos")
  elseif("${XCODEBUILD_PLATFORM}" STREQUAL "watchOSSimulator")
    set(USED_SDK_NAME "watchsimulator")
  endif()
endif()


if(${XCODEBUILD_PLATFORM} IN_LIST VALID_PLATFORMS)
  if("${XCODEBUILD_PLATFORM}" STREQUAL "iOS")
    set(ARCHS_LIST armv7 armv7s arm64)
  elseif("${XCODEBUILD_PLATFORM}" STREQUAL "iOSSimulator")
    set(ARCHS_LIST x86_64)
  elseif("${XCODEBUILD_PLATFORM}" STREQUAL "macOS")
    set(ARCHS_LIST x86_64)
  elseif("${XCODEBUILD_PLATFORM}" STREQUAL "tvOS")
    set(ARCHS_LIST arm64)
  elseif("${XCODEBUILD_PLATFORM}" STREQUAL "tvOSSimulator")
    set(ARCHS_LIST x86_64)
  elseif("${XCODEBUILD_PLATFORM}" STREQUAL "watchOS")
    set(ARCHS_LIST armv7 armv7s arm64)
  elseif("${XCODEBUILD_PLATFORM}" STREQUAL "watchOSSimulator")
    set(ARCHS_LIST x86_64)
  endif()
endif()

message(STATUS "Selected platform: ${XCODEBUILD_PLATFORM}")

# Get the SDK name
if(NOT XCODEBUILD_PLATFORM_VERSION)
  message(STATUS "Detecting version...")
  foreach(var_loop IN LISTS XCODE_SDK_LIST) 
    string(REGEX REPLACE "([a-z]+)[0-9\\.]+" "\\1" CURRENT_LOOP_PLATFORM "${var_loop}")
    if("${CURRENT_LOOP_PLATFORM}" STREQUAL "${USED_SDK_NAME}")
      string(REGEX REPLACE "[a-z]+([0-9\\.]+)" "\\1" XCODEBUILD_PLATFORM_VERSION "${var_loop}")
      break()
    endif()
  endforeach()
endif()

message(STATUS "Selected platform version: ${XCODEBUILD_PLATFORM_VERSION}")
# SDK
set(FULL_SDK_NAME "${USED_SDK_NAME}${XCODEBUILD_PLATFORM_VERSION}")

# Set the basic
set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_SYSTEM_VERSION 1)
set(UNIX TRUE)
set(APPLE TRUE)

# Skip checks
set(CMAKE_CXX_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_WORKS TRUE)
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_C_COMPILER_WORKS TRUE)

# Set the C Compiler
execute_process(COMMAND xcrun -sdk ${FULL_SDK_NAME} -find clang
OUTPUT_VARIABLE CMAKE_C_COMPILER
ERROR_QUIET
OUTPUT_STRIP_TRAILING_WHITESPACE)

message(STATUS "C Compiler: ${CMAKE_C_COMPILER}")

# Set the C++ Compiler
execute_process(COMMAND xcrun -sdk ${FULL_SDK_NAME} -find clang++
OUTPUT_VARIABLE CMAKE_CXX_COMPILER
ERROR_QUIET
OUTPUT_STRIP_TRAILING_WHITESPACE)

# Bitcode
if(NOT BITCODE_ENABLED)
  message(STATUS "Bitcode disabled")
else()
  message(STATUS "Bitcode enabled")
  set(CMAKE_C_FLAGS "-fembed-bitcode ${CMAKE_C_FLAGS}")
  set(CMAKE_CXX_FLAGS "-fembed-bitcode ${CMAKE_CXX_FLAGS}")
endif()

# Set the ranlib tool
execute_process(COMMAND xcrun -sdk ${FULL_SDK_NAME} -find ranlib
OUTPUT_VARIABLE CMAKE_RANLIB
ERROR_QUIET
OUTPUT_STRIP_TRAILING_WHITESPACE)

# Set the ar tool
execute_process(COMMAND xcrun -sdk ${FULL_SDK_NAME} -find ar
OUTPUT_VARIABLE CMAKE_AR
ERROR_QUIET
OUTPUT_STRIP_TRAILING_WHITESPACE)

execute_process(COMMAND xcrun -sdk ${FULL_SDK_NAME} -find libtool
OUTPUT_VARIABLE IOS_LIBTOOL
ERROR_QUIET
OUTPUT_STRIP_TRAILING_WHITESPACE)
message(STATUS "Using libtool: ${IOS_LIBTOOL}")
# Configure libtool to be used instead of ar + ranlib to build static libraries.
# This is required on Xcode 7+, but should also work on previous versions of
# Xcode.
set(CMAKE_C_CREATE_STATIC_LIBRARY
"${IOS_LIBTOOL} -static -o <TARGET> <LINK_FLAGS> <OBJECTS> ")
set(CMAKE_CXX_CREATE_STATIC_LIBRARY
"${IOS_LIBTOOL} -static -o <TARGET> <LINK_FLAGS> <OBJECTS> ")

# Get sysroot
execute_process(COMMAND xcodebuild -version -sdk ${FULL_SDK_NAME} Path
OUTPUT_VARIABLE CMAKE_OSX_SYSROOT
ERROR_QUIET
OUTPUT_STRIP_TRAILING_WHITESPACE)

if(NOT CMAKE_OSX_SYSROOT)
message(FATAL_ERROR "Impossible to get the full path for ${FULL_SDK_NAME}")
endif()

# Flags - Needs to force
set(CMAKE_OSX_SYSROOT ${CMAKE_OSX_SYSROOT} CACHE PATH "Sysroot used for iOS support")
set(CMAKE_OSX_ARCHITECTURES ${ARCHS_LIST} CACHE STRING "Sysroot used for iOS support")
set(CMAKE_FIND_ROOT_PATH ${CMAKE_OSX_SYSROOT} CACHE PATH "Find used for iOS support")