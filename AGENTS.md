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
- **IDE**: VSCode (recommended) with clangd, connected via Remote SSH
- **Development Environment**: Vagrant VM (required for DPDK support)

## Development Environment Setup

Development is done inside a Vagrant VM accessed via VSCode Remote SSH. This ensures a consistent environment with all dependencies (including DPDK for kernel bypass networking) pre-installed.

### Prerequisites (Host Machine)

1. VirtualBox
2. Vagrant
3. VSCode with Remote - SSH extension

### Setting Up

```bash
vagrant up
```

By default, the VM is allocated 50% of your host's CPU and RAM. Override with environment variables:

```bash
VM_CPUS=8 VM_RAM_GB=16 vagrant up
```

### VM Resource Configuration

| Environment Variable | Description         | Default          |
| -------------------- | ------------------- | ---------------- |
| `VM_CPUS`            | Number of CPU cores | 50% of host CPUs |
| `VM_RAM_GB`          | RAM in GB           | 50% of host RAM  |

## Workflow & Commands

We use just as the standard command runner. Do not run raw CMake commands unless debugging the build system itself.

### Build Commands

| Command               | Description                                               |
| --------------------- | --------------------------------------------------------- |
| `just build`          | Configures and build (Incremental).                       |
| `just test`           | Runs unit tests.                                          |
| `just build-release`  | Configures and build in Release mode (Incremental).       |
| `just run`            | Runs debug build.                                         |
| `just run-release`    | Runs release build.                                       |
| `just fstack release` | Configures and builds F-Stack to be used as a dependency. |

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
