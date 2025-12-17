# Upshifted Recycler AppIcon Bug

## Problem Statement

After implementing a fix for Recycler icon positioning (commit e59e099), a regression was introduced where:

1. ✓ **Recycler icon correctly positioned** at bottom of screen
2. ✗ **Dock icons "scoop forward"** when clicked (create gaps, shift positions)
3. ✗ **Normal dock icons positioned incorrectly** (shifted down by one icon height)

## Symptoms

### Before Any Fix
- Recycler icon positioned 56 pixels too high (at y=960 instead of y=1016)
- Normal dock icons positioned correctly
- Screen height: 1080 pixels, icon size: 64 pixels, top panel height: 56 pixels

### After Initial Fix Attempt (commit e59e099)
- Recycler icon correctly at bottom (y=1016)
- Clicking any dock icon caused it to "scoop forward" and create gaps
- Issue traced to `dock->y_pos` being recalculated on every icon reattachment

### After Second Fix Attempt (preserving dock->y_pos=56)
- Recycler icon correctly at bottom (y=1016)
- Workspace icon (icon 0) appeared in "slot 1" position (shifted down 56 pixels)
- All normal icons shifted down by panel height

## Root Cause Analysis

The core issue was a **semantic conflict** in how `dock->y_pos` was being used:

1. **Normal dock behavior**: `dock->y_pos = 0` (icons start at screen top, y=0)
2. **Recycler positioning**: Needed `dock->y_pos = 56` (to account for 56-pixel top panel)

### Key Code Paths

**Icon Position Calculation** (dock.c, wDockReattachIcon):
```c
icon->y_pos = dock->y_pos + (y * ICON_SIZE);
```

With 16 icons fitting on 1080-pixel screen:
- If `dock->y_pos = 0`: Icon 0 at y=0, Icon 15 at y=960 (56 pixels from bottom)
- If `dock->y_pos = 56`: Icon 0 at y=56, Icon 15 at y=1016 (flush with bottom)

### The Dilemma

- **Icon 0** needs to be at y=0 (top of screen)
- **Icon 15 (Recycler)** needs to be at y=1016 (flush with bottom)
- But with `dock->y_pos = 0`: Icon 15 = 0 + 15*64 = 960 ≠ 1016
- And with `dock->y_pos = 56`: Icon 0 = 56 + 0*64 = 56 ≠ 0

**Mathematical impossibility**: Can't satisfy both constraints with a single `dock->y_pos` value.

## Investigation Process

### Discovery of moveDock Issue

Comprehensive logging revealed:
1. `wDockCreate` initialized `dock->y_pos = 56` correctly
2. `wDockRestoreState` loaded Position "-64,0" and overwrote `dock->y_pos = 0`
3. Manual correction back to 56 was applied
4. **But** `moveDock()` in Workspace+WM.m was called later and reset it to 0

### Failed Approaches

**Attempt 1**: Preserve `dock->y_pos` throughout initialization
- Modified `wDockRestoreState` to not overwrite for WM_DOCK
- Modified `moveDock` to not overwrite for WM_DOCK
- **Result**: All icons shifted down 56 pixels (Icon 0 in wrong position)

**Attempt 2**: Add panel offset in `syncFrameWithDock`
- Used `usable_area.y1` to get panel height
- **Result**: `usable_area.y1 = 0` (no panel detected), offset not applied

## Final Solution

**Strategy**: Keep `dock->y_pos = 0` for normal icons, add offset ONLY to Recycler.

### Implementation

**File**: `Applications/Workspace/RecyclerIcon.m`

**Location**: `updatePositionInDock` method, after `wDockReattachIcon` call

```objc
// FIX: Add offset to Recycler Y position to place it flush with bottom
// calculateDockYPos returns the Y offset needed to fit max_icons within usable area
int dock_offset = calculateDockYPos(dock);
rec_icon->y_pos += dock_offset;
XMoveWindow(dpy, rec_icon->icon->core->window, rec_icon->x_pos, rec_icon->y_pos);
NSLog(@"RecyclerIcon updatePositionInDock: Applied dock_offset=%d, final y_pos=%d",
      dock_offset, rec_icon->y_pos);
```

**Why `calculateDockYPos()`?**

This function returns the Y offset needed to position icons such that `max_icons` fit within the usable screen area with the last icon flush against the bottom:

```c
int calculateDockYPos(WDock *dock)
{
  WScreen *scr = dock->screen_ptr;
  WArea usable_area = wGetUsableAreaForHead(scr, scr->xrandr_info.primary_head, NULL, False);
  int usable_height = usable_area.y2 - usable_area.y1;
  int max_icons = usable_height / wPreferences.icon_size;
  int result = usable_area.y2 - (max_icons * wPreferences.icon_size);
  return result;
}
```

**Calculation**:
- `usable_area.y2 = 1080` (screen height)
- `max_icons = 16` (1080 / 64)
- `result = 1080 - (16 * 64) = 1080 - 1024 = 56`

### Files Modified

1. **Applications/Workspace/WM/dock.c**
   - Changed `calculateDockYPos` from `static` to public (line 1040)

2. **Applications/Workspace/WM/dock.h**
   - Added declaration: `int calculateDockYPos(WDock *dock);` (line 78)

3. **Applications/Workspace/RecyclerIcon.m**
   - Added offset calculation and XMoveWindow call in `updatePositionInDock` (lines 380-386)

## Testing & Verification

### Test Results

**Scenario 1: Fresh Workspace Launch**
```
RecyclerIcon updatePositionInDock: Applied dock_offset=56, final y_pos=1016
```
- Icon 0 (Workspace) at y=0 ✓
- Icon 15 (Recycler) at y=1016 ✓

**Scenario 2: Double-Click Dock Icons**
- No "scoop forward" behavior ✓
- Icons remain in correct positions ✓
- No gaps created ✓

**Scenario 3: Screen Resolution Changes**
- Recycler automatically repositions to new bottom ✓
- Normal icons adjust correctly ✓

## Key Insights

1. **Single offset value can't satisfy dual constraints**: Normal icons need y=0 start, Recycler needs y=1016 end
2. **Panel height is encoded in calculation**: `calculateDockYPos` already accounts for usable area
3. **Recycler is special case**: Only icon that needs explicit offset adjustment
4. **X11 window must be moved**: Setting `icon->y_pos` alone isn't enough, must call `XMoveWindow`
5. **usable_area.y1 = 0**: Top panel not reflected in usable_area bounds, only in max_icons calculation

## Logs Location

- **NSLog() output**: `/tmp/GNUstepSecure1001/console.log`
- **WMLogInfo() output**: `/var/log/daemon.log`

## Related Issues

- Terminal.app missing from dock (separate issue - not a bug, just missing from WMState.plist)
- SKIP_GORM_PC environment variable doesn't work with `doas` (use: `doas env SKIP_GORM_PC=1 ./script.sh`)

## Build Process Notes

**Fast rebuilds** (skip Gorm/ProjectCenter):
```bash
export SKIP_GORM_PC=1
doas ./9_build_Applications.sh
# OR
doas env SKIP_GORM_PC=1 ./9_build_Applications.sh
```

**Why `doas env`?** The `doas` command doesn't pass environment variables through by default (unlike `sudo -E`).

## Timeline

- **Initial problem**: Recycler 56 pixels too high
- **First fix**: Set `dock->y_pos = 56` everywhere → Recycler correct, normal icons wrong
- **Investigation**: Discovered `moveDock()` resetting `dock->y_pos`
- **Second attempt**: Preserve `dock->y_pos = 56` → Icon 0 shifted down
- **Root cause identified**: Impossible to satisfy both constraints with single offset
- **Final solution**: Offset only Recycler, using `calculateDockYPos()`
- **Result**: All icons correctly positioned ✓

## Lessons Learned

1. **Read the logs**: Console.log vs daemon.log distinction was crucial
2. **Question assumptions**: `usable_area.y1` seemed right but was 0
3. **Use existing calculations**: `calculateDockYPos` already solved the math
4. **Test systematically**: Each failed approach revealed more about the system
5. **Simple is better**: Final fix is ~6 lines of code vs complex preservation logic
