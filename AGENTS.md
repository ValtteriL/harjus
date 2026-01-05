# AI Agent Context & Developer Guide

## Project Overview

This is a latency-sensitive Linux C++ project. We prioritize runtime performance, deterministic execution, and memory safety.

## Tech Stack & Tooling

- **Language**: C++ (Modern standard, e.g., C++20/23)
- **Build System**: CMake
- **Compiler**: GCC (primary), Clang (used for tools/verification)
- **Task Runner**: just (All entry points are defined here)
- **Testing**: Google Test (gtest) managed via CTest. Flashfix library uses Catch2
- **CI/CD**: Jenkins
- **IDE**: VSCode (recommended) with clangd
- **Development VM**: Vagrant (for isolated development environment)

## Development Environment Setup

Ensure the following are installed

1. cmake
2. libdpdk-dev
3. dpdk

For Vagrant-based development, ensure VirtualBox and Vagrant are installed.

## Workflow & Commands

We use just as the standard command runner. Do not run raw CMake commands unless debugging the build system itself.

| Command | Description |
|---|---|
| `just build` | Configures and builds Harjus (Incremental). |
| `just test` | Runs Harjus unit tests. |
| `just release <version>` | Builds harjus release with given version. |
| `just test-flashfix` | Runs Flashfix unit tests. |
| `just fstack release` | Configures and builds F-Stack to be used as a dependency. |
| `just vagrant-debug` | Runs Debug build of Harjus in Vagrant. |

## Coding Guidelines (Latency Sensitive)

Performance is a critical feature. Adhere to these strict guidelines:

1. **Hot Paths**: Identify critical paths marked with // HOT PATH.

    - **No Heap Allocations**: Avoid new, malloc, std::shared_ptr, std::vector resizing, or std::string creation in the hot path. Use pre-allocated pools or stack memory.
    - **No Exceptions**: Exceptions are for fatal startup/config errors only. Use error codes or std::expected/std::optional for runtime flow control.
    - **No Blocking I/O**: All I/O must be non-blocking (io_uring/epoll) or offloaded to dedicated threads.
    - **No Locking**: Avoid std::mutex in hot paths. Use lock-free structures or single-writer/single-reader ring buffers if thread synchronization is required.

2. **Memory Management**:

    - Prefer std::unique_ptr over raw pointers.
    - Use std::span or std::string_view for passing buffers to avoid copies.
    - Cache locality is key; prefer "Structure of Arrays" (SoA) or flat data structures over pointer chasing.

3. **Style**:
    - Code must be formatted via clang-format before commit.
    - All clang-tidy warnings are treated as errors in CI.

## Project Structure

- src/: Implementation files (.cpp).
- include/: Public header files (.hpp).
- tests/: GTest unit tests.
- deploy/: Deployment files
- flashfix/: Flashfix library sources.
- Jenkinsfile: CI pipeline definition.
- Justfile: Task definitions.

## Testing Strategy

- **Unit Tests**: Must cover all business logic. Mocks are allowed but prefer testing state changes.

## VSCode Configuration

- The project includes .vscode/settings.json which points clangd to the correct compilation database (compile_commands.json).
- Ensure the clangd extension is installed and the C/C++ extension (IntelliSense) is disabled to avoid conflicts.
