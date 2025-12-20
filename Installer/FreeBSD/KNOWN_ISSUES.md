# Known Issues - NextSpace on FreeBSD

## Suspend/Resume Crash (FreeBSD 15.0)

### Symptom
Workspace.app crashes with SIGILL (Illegal instruction) when resuming from suspend (lid close/open or `zzz` command).

### Root Cause
FreeBSD's kqueue file descriptors become invalid after system suspend/resume. Workspace uses CFRunLoop extensively for event monitoring, which relies on kqueue via CFFileDescriptor. When the system resumes, any CFRunLoop attempting to service its kqueue-based event sources encounters invalid file descriptors, resulting in a privileged opcode fault (SIGILL).

### Affected Components
- **Window Manager event loops** (WM_V0, WM_V1) - Monitor X11 connection for each virtual screen
- **D-Bus connection monitoring** (OSEBusConnection with CF_BUS_CONNECTION) - Monitors UDisks2 events for device management
- Potentially other CFRunLoop-based event sources throughout Workspace

### Stack Trace Example
```
Thread 1 (WM_V1):
#0  __CFRunLoopServicePorts (portSet=22, singlePort=-1, livePort=0x..., timeout=-1)
    at RunLoop.subproj/CFRunLoop.c:3106
#1  __CFRunLoopRun (rl=0x..., rlm=0x..., seconds=9999999999, ...)
    at RunLoop.subproj/CFRunLoop.c:3307
#2  CFRunLoopRunSpecific (...)
#3  CFRunLoopRun ()
#4  WMRunLoop_V1 () at WM/event.c:369
```

### Workarounds

**Option 1: Exit Workspace before suspend** (Recommended)
```sh
# Before suspending:
killall Workspace
# Or use the Workspace menu: Quit

# After resume, restart Workspace from login screen or:
/usr/local/NextSpace/Apps/Workspace.app/Workspace &
```

**Option 2: Disable suspend/sleep**
```sh
# Prevent accidental suspend
doas sysctl -w hw.acpi.lid_switch_state=NONE
```

**Option 3: Keep laptop lid open**
- Use external monitor
- Configure BIOS/UEFI to ignore lid switch

### Attempted Fixes

Several approaches were investigated:

1. **Remove CF_BUS_CONNECTION**: Switched D-Bus monitoring from CFRunLoop to NSFileHandle
   - Result: D-Bus component no longer crashes, but Window Manager CFRunLoops still fail
   - Conclusion: Problem is systemic, not limited to one component

2. **Proactive connection validation**: Added checks before CFRunLoopRunInMode
   - Result: dbus_connection_get_is_connected() returns true even when socket is stale
   - Conclusion: No reliable pre-check exists to detect invalid kqueue state

3. **Manual CFRunLoop teardown/rebuild**: Attempted to detect stale connections and recreate infrastructure
   - Result: Detection happens too late; CFRunLoop already blocked on invalid kevent call
   - Conclusion: Would need suspend notification hooks to work proactively

### Potential Long-term Solutions

**Option A: System-wide suspend/resume hooks**
- Hook into FreeBSD's devd or ACPI events
- Stop all CFRunLoops before suspend
- Recreate kqueue infrastructure after resume
- Complexity: High - requires deep integration across Workspace architecture

**Option B: Replace CFRunLoop with poll/select**
- Migrate all event monitoring to traditional UNIX poll/select mechanisms
- Avoid kqueue entirely
- Complexity: Very high - major architectural change affecting entire codebase

**Option C: Investigate FreeBSD kernel behavior**
- Determine if kqueue FD invalidation on suspend is expected behavior
- File bug report if this is a regression in FreeBSD 15.0
- Check if earlier FreeBSD versions had different behavior
- References:
  - [Ceph kqueue invalidation issue](https://github.com/ceph/ceph/pull/11430)
  - [FreeBSD kqueue man page](https://man.freebsd.org/cgi/man.cgi?kqueue)

### Related FreeBSD 15.0 Issues

As noted by the user, FreeBSD 15.0 has ongoing work around suspend/wake lifecycle, including:
- WiFi card issues on resume
- Other device state management problems

This suggests the kqueue invalidation may be a broader FreeBSD 15.0 regression or architectural change related to the power management overhaul.

### Technical Details

**kqueue behavior on suspend/resume:**
From FreeBSD documentation and bug reports, kqueue file descriptors are invalidated on:
- `fork()` calls
- Thread creation in some cases
- System suspend/resume events (confirmed in FreeBSD 15.0)

**Why SIGILL instead of EBADF?**
The crash manifests as SIGILL (illegal instruction / privileged opcode) rather than EBADF (bad file descriptor) because:
- The kevent syscall at the kernel boundary encounters an invalid state
- Rather than returning an error code, it triggers a privileged instruction fault
- This appears to be specific to how FreeBSD 15.0 handles stale kqueue descriptors

### References

- **Source files affected:**
  - `Applications/Workspace/WM/event.c:369` - WMRunLoop_V1() using CFRunLoopRun
  - `Frameworks/SystemKit/OSEBusConnection.m:158` - D-Bus monitoring (when CF_BUS_CONNECTION enabled)

- **Core dump analysis:**
  - `/home/heraclitus/Workspace.core` - Examine with `gdb /usr/local/NextSpace/Apps/Workspace.app/Workspace core`
  - Typical crash thread: WM_V0 or WM_V1

- **Logs:**
  - `/var/log/daemon.log` - Check for Workspace error messages
  - Look for ACPI suspend/resume events around crash time

### Status

**Current Status:** DOCUMENTED - No fix available
**Impact:** Critical - System unusable with suspend/resume while Workspace running
**Workaround Available:** Yes - Exit Workspace before suspend
**Priority for Fix:** Medium - Workaround exists but UX is poor

### Last Updated
2025-12-20
