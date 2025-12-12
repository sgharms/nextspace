# CFFileDescriptor Minimal Test

## Purpose

This test validates whether `CFFileDescriptor` callbacks work correctly on FreeBSD after building only the minimal required components:

- **Script 0**: libdispatch (GCD)
- **Script 1**: CoreFoundation

This is the absolute minimum needed to test the dispatch queue functionality that was failing in the work described in `SYNCHRONIZE.md` and `patient_debugging.txt`.

## What It Tests

The test program:
1. Creates a simple pipe (file descriptors)
2. Wraps the read end in a `CFFileDescriptor`
3. Registers a callback for read events
4. Adds the descriptor to a `CFRunLoop`
5. Writes data to the pipe to trigger the callback
6. Runs the runloop for 5 seconds
7. Reports whether the callback fired

## Expected Results

### If CFFileDescriptor Works (SUCCESS)
```
[SUCCESS] Callback fired! count=1, thread=0x..., flags=0x1
[SUCCESS] Read 12 bytes from fd=3

✓✓✓ TEST PASSED ✓✓✓
CFFileDescriptor callbacks ARE working!
```

### If CFFileDescriptor Fails (FAILURE)
```
RUNLOOP EXITED
Result: kCFRunLoopRunTimedOut (5 second timeout reached)

Callback count: 0

✗✗✗ TEST FAILED ✗✗✗
CFFileDescriptor callbacks DID NOT FIRE
This matches the problem described in SYNCHRONIZE.md
```

## How to Run

### 1. Build the Required Libraries

From your development jail:

```sh
cd /src/Installer/FreeBSD

# Build libdispatch (GCD)
doas ./0_build_libdispatch.sh

# Build CoreFoundation
doas ./1_build_libcorefoundation.sh
```

These install to `/usr/local/NextSpace/` by default.

### 2. Build the Test

```sh
cd /src
make -f Makefile.test_cfdescriptor
```

### 3. Run the Test

```sh
./test_cfdescriptor
```

Or combined:

```sh
make -f Makefile.test_cfdescriptor run
```

## Interpreting Results

### Test Passes ✓
- CFFileDescriptor is working correctly
- The library sources from scripts 0 and 1 are good
- You can proceed to build the rest of the stack
- The problems described in `SYNCHRONIZE.md` may be resolved

### Test Fails ✗
- CFFileDescriptor callbacks don't fire (same as before)
- This confirms the issue is in the CF/dispatch layer
- Building the full application stack won't help
- Need to investigate library sources or try different versions

## Why This Test Matters

The previous debugging work (documented in `patient_debugging.txt`) showed that:

1. CFFileDescriptor callbacks **never fired** in the full application
2. This caused X event processing to fail
3. The desktop showed black screen because Window Maker couldn't process events

By testing **just CFFileDescriptor** in isolation, we can:
- Validate the core mechanism works before building everything else
- Save hours of build time if it's still broken
- Identify exactly which layer is failing

## Files

- `test_cfdescriptor.c` - Test program source
- `Makefile.test_cfdescriptor` - Build configuration
- `README.test_cfdescriptor.md` - This file

## Next Steps

### If Test Passes ✓
Continue with the remaining build scripts (2-9) to build the full stack.

### If Test Fails ✗
Options:
1. Try different library versions in scripts 0 and 1
2. Apply different patches to CoreFoundation
3. Use dispatch_source instead of CFFileDescriptor
4. Accept that CFFileDescriptor doesn't work on FreeBSD and use a simpler event mechanism
