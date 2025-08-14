# Cross-compilation toolchain for Raspberry Pi 4/5
# Target: ARM64 (aarch64) Cortex-A72

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# Cross-compilation tools
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)

# Root path for cross-compilation
set(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu)

# Search programs in host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# Search libraries and headers in target environment  
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Raspberry Pi 4/5 specific optimizations
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mcpu=cortex-a72 -mtune=cortex-a72")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mcpu=cortex-a72 -mtune=cortex-a72")

# Release optimizations
set(CMAKE_C_FLAGS_RELEASE "-O3 -DNDEBUG -ffast-math")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG -ffast-math")

# Security hardening flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fstack-protector-strong -D_FORTIFY_SOURCE=2")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fstack-protector-strong -D_FORTIFY_SOURCE=2")

# Static linking for standalone deployment
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static-libgcc -static-libstdc++")

# Set the target triple for consistency
set(CMAKE_C_COMPILER_TARGET aarch64-linux-gnu)
set(CMAKE_CXX_COMPILER_TARGET aarch64-linux-gnu)
