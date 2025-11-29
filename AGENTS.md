# AI Agent Context & Developer Guide

## Project Overview

This is a latency-sensitive Linux C++ project. We prioritize runtime performance, deterministic execution, and memory safety. The development environment is strictly managed via Nix to ensure reproducibility.

## Tech Stack & Tooling

- **Language**: C++ (Modern standard, e.g., C++20/23)
- **Build System**: CMake
- **Compiler**: GCC (primary), Clang (used for tools/verification)
- **Task Runner**: just (All entry points are defined here)
- **Environment**: Nix Shell + Direnv
- **Linting/Formatting**: clang-tidy, clang-format
- **Testing**: Google Test (gtest) managed via CTest. Flashfix library uses Catch2
- **CI/CD**: Jenkins
- **IDE**: VSCode (recommended) with clangd

## Development Environment Setup

This project uses a hermetic environment. Do not rely on system-installed packages.

1. Ensure **Nix** is installed (without flake support).
2. Ensure **Direnv** is installed and hooked into your shell.
3. Run direnv allow in the root directory.
    Note: This will automatically bootstrap the environment with gcc, cmake, ninja, and other tools.

## Workflow & Commands

We use just as the standard command runner. Do not run raw CMake commands unless debugging the build system itself.

| Command | Description |
|---|---|
| `just build` | Configures and builds Harjus (Incremental). |
| `just full-build` | Configures and builds Harjus from scratch. |
| `just test` | Runs Harjus unit tests. |
| `just nix-build-all` | Builds all Nix derivations. |
| `just release <version>` | Builds harjus release as a Nix derivation with given version. |
| `just fmt` | Applies clang-format to files modified after branching off main. |
| `just fmt-full` | Applies clang-format to all C/C++ files in the codebase. |
| `just lint` | Runs essential clang-tidy checks. |
| `just lint-full` | Runs full clang-tidy checks. |
| `just flashfix build` | Configures and build Flashfix (Incremental). |
| `just flashfix full-build` | Configures and builds Flashfix from scratch. |
| `just flashfix test` | Runs Flashfix unit tests. |

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
- nix/: Nix flake and derivation logic.
- flashfix/: Flashfix library sources.
- Jenkinsfile: CI pipeline definition.
- Justfile: Task definitions.

## Testing Strategy

- **Unit Tests**: Must cover all business logic. Mocks are allowed but prefer testing state changes.

## VSCode Configuration

- The project includes .vscode/settings.json which is auto-configured by Nix/Direnv to point clangd to the correct compilation database (compile_commands.json).
- Ensure the clangd extension is installed and the C/C++ extension (IntelliSense) is disabled to avoid conflicts.
