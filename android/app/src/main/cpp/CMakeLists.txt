cmake_minimum_required(VERSION 3.18.1)

project("spdfcore")

# Create the spdfcore library with direct FFI calls
add_library(
    spdfcore
    SHARED
    spdfcore_jni.cpp
)

# Find required libraries
find_library(log-lib log)
find_library(android-lib android)

# Link libraries (spdfcore_ffi will be loaded at runtime by Java)
target_link_libraries(
    spdfcore
    ${log-lib}
    ${android-lib}
)

# Set C++ standard
set_target_properties(spdfcore PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
)