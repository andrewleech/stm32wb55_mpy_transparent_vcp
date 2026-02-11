---
paths:
  - "micropython/**/*"
---

# MicroPython CLAUDE.md
This file provides context for AI coding agents working on the MicroPython codebase.

## Building MicroPython

### Prerequisites
First build the cross-compiler:
```bash
cd mpy-cross
make
```

### Common Build Commands

**Unix Port (for development/testing):**
```bash
cd ports/unix
make submodules  # Initialize git submodules (first time only)
make             # Standard build
make test        # Run basic tests
make test_full   # Run comprehensive test suite
make clean       # Clean build artifacts
```

**STM32 Port:**
```bash
cd ports/stm32
make submodules                    # Initialize git submodules (first time only)
make BOARD=PYBV10                  # Build for specific board
make BOARD=PYBV10 deploy           # Deploy via DFU
make BOARD=PYBV10 deploy-stlink    # Deploy via ST-Link
make clean                         # Clean build artifacts
```

**ESP32 Port:**
```bash
cd ports/esp32
make submodules        # Initialize git submodules
make BOARD=ESP32_GENERIC
make BOARD=ESP32_GENERIC deploy
```

**RP2 (Raspberry Pi Pico) Port:**
```bash
cd ports/rp2
make submodules
make BOARD=RPI_PICO
make BOARD=RPI_PICO_W  # For Pico W with wireless
```

### Common Make Options
- `V=1` - Verbose build output
- `DEBUG=1` - Debug build with symbols
- `FROZEN_MANIFEST=path/to/manifest.py` - Include frozen Python modules

## Running Tests

```bash
# Run all tests for Unix port
cd ports/unix
make test_full

# Run specific test
../../tests/run-tests.py basics/builtin_str.py

# Run tests with specific options
../../tests/run-tests.py --target unix --via-mpy

# Run multi-instance tests
../../tests/run-multitests.py

# Run performance benchmarks
../../tests/run-perfbench.py
```

## Unit Tests
The unit tests are in tests/<category> folders.
They are generally written as python scripts that are run under both
micropython a (c)python with the print outputs compared for consistency.
For tests that can only run on micropython a unittest based test is preferred else
 a <test name>.py script is accompanied by a <test name>.py.exp where the .exp file
contains the expected print outputs to compare the test output against.

## Code Formatting and Style

All new C/python/sh files should have a newline at the end of the file.

**Before committing code:**
```bash
# Format C code (requires uncrustify v0.72)
tools/codeformat.py

# Format specific files only
tools/codeformat.py path/to/file.c

# Check formatting without modifying
tools/codeformat.py -c

# Python code is formatted with ruff
ruff format

# Run spell check
codespell

# Run lint and formatting checks (if using pre-commit)
pre-commit run --files [files...]
```

**Use pre-commit hooks for automatic checks (recommended):**
```bash
pre-commit install --hook-type pre-commit --hook-type commit-msg
```

**Commit message format:**
```
component/subcomponent: Brief description ending with period.

Detailed explanation if needed, wrapped at 75 characters.

Signed-off-by: Your Name <your.email@example.com>
```

Example:
```
py/objstr: Add splitlines() method.

This implements the splitlines() method for str objects, compatible
with CPython behavior.

Signed-off-by: Developer Name <dev@example.com>
```

## Code Style Guidelines

**General:**
* Follow conventions in existing code.
* See `CODECONVENTIONS.md` for detailed C and Python style guides.

**Python:**
* Follow PEP 8.
* Use `ruff format` for auto-formatting (line length 99).
* Naming: `module_name`, `ClassName`, `function_name`, `CONSTANT_NAME`.

**C:**
* Use `tools/codeformat.py` for auto-formatting.
* Naming: `underscore_case`, `CAPS_WITH_UNDERSCORE` for enums/macros, `type_name_t`.
* Memory allocation: Use `m_new`, `m_renew`, `m_del`.
* Integer types: Use `mp_int_t`, `mp_uint_t` for general integers, `size_t` for sizes.

## Pull Requests

### PR Description Guidelines
* The title should focus on the end user effect of the change.
* All PR/MR descriptions should be written succinctly with a casual / personal writing style with minimal extra sub-headings if any.
* Do NOT list commits or provide checklists of things done/not-done.
* Provide only brief detail and background, we can assume everyone reading this is already a micropython expert.
* When writing PR/MR descriptions use the template:
``` markdown
### Summary
<!-- Explain the reason for making this change. What problem does the pull request
     solve, or what improvement does it add? Add links if relevant.
     Write the description in a clear technical style. The start of the
     summary should focus on end user requirements / issues being
     addressed in normal English. Technical details of the implementation
     / fix can come later though keep in mind the code can speak for
     itself in many cases.
-->

### Testing
<!-- Explain what testing you did, and on which boards/ports. If there are
     boards or ports that you couldn't test, please mention this here as well.
     If you leave this empty then your Pull Request may be closed. -->

### Trade-offs and Alternatives
<!-- If the Pull Request has some negative impact (i.e. increased code size)
     then please explain why you think the trade-off improvement is worth it.
     If you can think of alternative ways to do this, please explain that here too.
     Delete this heading if not relevant (i.e. small fixes) -->
```

### GitHub PR Guidelines
* The upstream repo https://github.com/micropython/micropython should always be used for PR's.
* Git pushes should always go to the origin remote.

### Working with PRs via gh
The `gh` tool can be used to interact with Pull Requests:
* List PRs: `gh pr list`
* View PR details: `gh pr view <PR_NUMBER>`
* View PR comments: `gh pr view <PR_NUMBER> --comments`
* View PR diff: `gh pr diff <PR_NUMBER>`
* Check out a PR: `gh pr checkout <PR_NUMBER>`

The GitHub API can also be accessed directly:
```bash
# Get review comments on a PR (inline on code)
gh api -H "Accept: application/vnd.github+json" \
       -H "X-GitHub-Api-Version: 2022-11-28" \
       /repos/micropython/micropython/pulls/<PR_NUMBER>/comments

# Get PR issue comments (main discussion)
gh api -H "Accept: application/vnd.github+json" \
       -H "X-GitHub-Api-Version: 2022-11-28" \
       /repos/micropython/micropython/issues/<PR_NUMBER>/comments

# Get PR review status
gh api -H "Accept: application/vnd.github+json" \
       -H "X-GitHub-Api-Version: 2022-11-28" \
       /repos/micropython/micropython/pulls/<PR_NUMBER>/reviews
```

## Architecture Overview

### Core Components

**py/** - Core Python implementation
- `compile.c`, `parse.c`, `lexer.c` - Python compiler
- `vm.c`, `bc.c` - Virtual machine and bytecode execution
- `obj*.c` - Python object implementations (str, list, dict, etc.)
- `mod*.c` - Built-in modules (sys, gc, struct, etc.)
- `gc.c` - Garbage collector
- `qstr.c` - Interned string system

**extmod/** - Extended modules
- `machine_*.c` - Hardware abstraction layer (GPIO, I2C, SPI, UART, etc.)
- `network_*.c` - Network drivers
- `vfs_*.c` - Virtual filesystem implementations
- `modbluetooth.c` - Bluetooth support
- `machine_usb_*.c` - USB device/host support

**ports/** - Platform-specific implementations
- Each port implements `mphalport.h` and `mpconfigport.h` interfaces
- Contains board-specific configurations in `boards/` subdirectories

**lib/** - External dependencies (git submodules)
- TinyUSB, LWIP, mbedTLS, BTstack, etc.

### Key Design Patterns

1. **QSTR System**: Strings are interned for efficiency. When adding new identifiers:
   - Add to `qstrdefsport.h` or use `MP_QSTR_*` in code
   - Build system automatically extracts and processes QSTRs

2. **Object Model**: All Python objects inherit from `mp_obj_base_t`
   - Use `MP_DEFINE_CONST_*` macros for constant objects
   - Follow existing patterns in `obj*.c` files

3. **Hardware Abstraction**:
   - Generic interface in `extmod/machine_*.c`
   - Port-specific implementation in `ports/*/machine_*.c`

4. **Module Registration**:
   - Static modules in `mpconfigport.h` via `MICROPY_PORT_BUILTIN_MODULES`
   - Dynamic modules via `MP_REGISTER_MODULE`

## Common Development Tasks

### Adding a New Built-in Function
1. Add implementation in appropriate `py/mod*.c` or `py/obj*.c` file
2. Add QSTR definition if needed
3. Register in module's globals dict
4. Add tests in `tests/basics/`

### Adding Hardware Support
1. Implement in port's `machine_*.c` following existing patterns
2. Use `MP_REGISTER_ROOT_POINTER` for GC roots
3. Follow the `machine` module API conventions
4. Add documentation in `docs/library/`

### Debugging
- Use `mp_printf(&mp_plat_print, "debug: %d\n", value)`
- Enable `DEBUG_printf` in specific files
- Use `MP_STACK_CHECK()` to detect stack overflow
- GC debugging: `gc.collect(True)` for verbose output
