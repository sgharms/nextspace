/*
 * Minimal CFFileDescriptor Test
 *
 * Tests if CFFileDescriptor callbacks fire on FreeBSD with the
 * libdispatch and CoreFoundation built by scripts 0 and 1.
 *
 * Success: Callback fires and prints "CALLBACK FIRED!"
 * Failure: Times out after 5 seconds with no callback
 */

#include <CoreFoundation/CoreFoundation.h>
#include <CoreFoundation/CFFileDescriptor.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <pthread.h>

static int callback_count = 0;

void fd_callback(CFFileDescriptorRef fdref, CFOptionFlags flags, void *info)
{
    callback_count++;

    printf("[SUCCESS] Callback fired! count=%d, thread=%p, flags=0x%lx\n",
           callback_count, (void*)pthread_self(), flags);

    // Read the data from the pipe to clear it
    int fd = CFFileDescriptorGetNativeDescriptor(fdref);
    char buf[256];
    ssize_t n = read(fd, buf, sizeof(buf));

    if (n > 0) {
        printf("[SUCCESS] Read %zd bytes from fd=%d\n", n, fd);
    }

    // Re-enable callbacks for next event
    CFFileDescriptorEnableCallBacks(fdref, kCFFileDescriptorReadCallBack);
}

int main(int argc, char *argv[])
{
    printf("=================================================\n");
    printf("CFFileDescriptor Test\n");
    printf("=================================================\n");
    printf("Thread: %p\n", (void*)pthread_self());
    printf("\n");

    // Create a pipe - simple test file descriptor
    int fds[2];
    if (pipe(fds) < 0) {
        perror("pipe");
        return 1;
    }

    printf("[SETUP] Created pipe: read_fd=%d, write_fd=%d\n", fds[0], fds[1]);

    // Create CFFileDescriptor for the read end
    CFFileDescriptorRef fdref = CFFileDescriptorCreate(
        kCFAllocatorDefault,
        fds[0],           // Monitor the read end
        false,            // Don't close on invalidate
        fd_callback,
        NULL
    );

    if (!fdref) {
        fprintf(stderr, "[FAIL] CFFileDescriptorCreate returned NULL\n");
        return 1;
    }

    printf("[SETUP] CFFileDescriptorRef created: %p\n", (void*)fdref);

    // Enable read callbacks
    CFFileDescriptorEnableCallBacks(fdref, kCFFileDescriptorReadCallBack);
    printf("[SETUP] Enabled read callbacks\n");

    // Create runloop source
    CFRunLoopSourceRef source = CFFileDescriptorCreateRunLoopSource(
        kCFAllocatorDefault,
        fdref,
        0  // order
    );

    if (!source) {
        fprintf(stderr, "[FAIL] CFFileDescriptorCreateRunLoopSource returned NULL\n");
        return 1;
    }

    printf("[SETUP] CFRunLoopSource created: %p\n", (void*)source);

    // Add to current runloop
    CFRunLoopRef runloop = CFRunLoopGetCurrent();
    printf("[SETUP] Current runloop: %p\n", (void*)runloop);

    CFRunLoopAddSource(runloop, source, kCFRunLoopDefaultMode);
    printf("[SETUP] Source added to runloop in default mode\n");

    printf("\n");
    printf("=================================================\n");
    printf("TRIGGERING EVENTS\n");
    printf("=================================================\n");

    // Write data to trigger the callback
    const char *msg1 = "Test data 1\n";
    write(fds[1], msg1, strlen(msg1));
    printf("[TRIGGER] Wrote '%s' to pipe\n", "Test data 1");

    printf("\n");
    printf("=================================================\n");
    printf("RUNNING RUNLOOP (5 second timeout)\n");
    printf("=================================================\n");
    printf("Expecting callback to fire...\n\n");

    // Run the runloop for 5 seconds
    CFRunLoopRunResult result = CFRunLoopRunInMode(
        kCFRunLoopDefaultMode,
        5.0,    // 5 second timeout
        false   // Don't exit after one source
    );

    printf("\n");
    printf("=================================================\n");
    printf("RUNLOOP EXITED\n");
    printf("=================================================\n");
    printf("Result: ");
    switch (result) {
        case kCFRunLoopRunFinished:
            printf("kCFRunLoopRunFinished (no sources/timers)\n");
            break;
        case kCFRunLoopRunStopped:
            printf("kCFRunLoopRunStopped (manually stopped)\n");
            break;
        case kCFRunLoopRunTimedOut:
            printf("kCFRunLoopRunTimedOut (5 second timeout reached)\n");
            break;
        case kCFRunLoopRunHandledSource:
            printf("kCFRunLoopRunHandledSource (processed source)\n");
            break;
        default:
            printf("Unknown (%d)\n", result);
    }

    printf("\n");
    printf("=================================================\n");
    printf("FINAL RESULTS\n");
    printf("=================================================\n");
    printf("Callback count: %d\n", callback_count);

    if (callback_count > 0) {
        printf("\n");
        printf("✓✓✓ TEST PASSED ✓✓✓\n");
        printf("CFFileDescriptor callbacks ARE working!\n");
        printf("\n");

        // Cleanup
        CFRelease(source);
        CFRelease(fdref);
        close(fds[0]);
        close(fds[1]);

        return 0;
    } else {
        printf("\n");
        printf("✗✗✗ TEST FAILED ✗✗✗\n");
        printf("CFFileDescriptor callbacks DID NOT FIRE\n");
        printf("This matches the problem described in SYNCHRONIZE.md\n");
        printf("\n");

        // Cleanup
        CFRelease(source);
        CFRelease(fdref);
        close(fds[0]);
        close(fds[1]);

        return 1;
    }
}
