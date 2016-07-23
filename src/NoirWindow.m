/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NoirWindow.h"

#import "NoirRootView.h"
#import "NoirDocument.h"
#import "NoirScrubber.h"
#import "NoirOverlayView.h"
#import "OverlayWindow.h"

#import "libavPlayer/libavPlayer.h"

#define SCRUB_STEP_DURATION 5


@implementation NoirWindow

-(NoirDocument*) noirDoc {
    return self.windowController.document;
}

-(instancetype) initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)aStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag {
    if((self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES])){
        self.backgroundColor = [NSColor blackColor];
        [self setOpaque:YES];
        [self useOptimizedDrawing:YES];
        [self setHasShadow:YES];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_onSelfMovedOrResized:) name:NSWindowDidResizeNotification object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_onSelfMovedOrResized:) name:NSWindowDidMoveNotification object:self];

        self.movableByWindowBackground = true;
    }
    return self;
}

-(void) awakeFromNib {
    [self _initOverlayWindow];

    [self setReleasedWhenClosed:YES];

    if(!fullScreen) [self setLevel:NSFloatingWindowLevel];
    [self makeFirstResponder:self];

    thePlayButton.target = self;
    thePlayButton.action = @selector(togglePlayingMovie:);

    theScrubBar.target = self;
    theScrubBar.action = @selector(doSetPosition:);
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResizeNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidMoveNotification object:self];
}

-(IBAction) doSetPosition:(id)sender {
    [self _seekToFraction:[sender doubleValue]];
}

-(void) close {
    @autoreleasepool {
        if(timeInterfaceUpdateTimer) [timeInterfaceUpdateTimer invalidate];
        // xxx why doesn't this happen automatically?
        [(LAVPLayer*)self.contentView.layer.sublayers[0] invalidate];
        [super close];
    }
}

-(void) showMovie:(LAVPMovie*)movie {
    NSView* view = self.contentView;
    [view setWantsLayer:YES];
    CALayer* rootLayer = view.layer;
    rootLayer.needsDisplayOnBoundsChange = YES;
    LAVPLayer* _layer = [LAVPLayer layer];
    [_layer setMovie:movie];
    _layer.frame = rootLayer.frame;
    _layer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    _layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
    [rootLayer addSublayer:_layer];

    // Resize the time-indicator to suit the length of the text we'll be showing in it.
    // For the text before the "/", we round up to the next power of 10, as that ought to be just a smidgen wider than any other string that'll later be shown there.
    double oldWidth = theTimeField.frame.size.width;
    int t = movie.durationInMicroseconds / 1000000;
    int mt = t / 60, st = t % 60;
    int placeholder = pow(10, ceil(log10(mt)));
    NSString* longestString = [NSString stringWithFormat:@"%d:00 / %d:%02d", placeholder, mt, st];
    theTimeField.stringValue = longestString;
    [theTimeField sizeToFit];
    double widthChange = theTimeField.frame.size.width - oldWidth;
    [theTimeField setFrameOrigin:NSMakePoint(theTimeField.frame.origin.x - widthChange, theTimeField.frame.origin.y)];
    [theScrubBar setFrameSize:NSMakeSize(theScrubBar.frame.size.width - widthChange, theScrubBar.frame.size.height)];

    [self _setInitialSize:movie.naturalSize];
}

#pragma mark Overriden Methods

-(BOOL) canBecomeMainWindow {
    return YES;
}

-(BOOL) canBecomeKeyWindow {
    return YES;
}

#pragma mark Interface Items

-(BOOL) validateMenuItem:(NSMenuItem*)anItem {
    // Without this, the "Close" and "Minimize" menu items are permanently disabled.
    if(anItem.tag == 7) return YES;
    return [super validateMenuItem:anItem];
}

-(IBAction) performClose:(id)sender {
    [self orderOut:sender]; //order out before stops double button click from causing crash
    if(fullScreen) [self _exitFullScreen];
    [self close];
}

-(void) _showStatusMessage:(NSString*)str {
    statusMessage.stringValue = str;
    statusMessage.hidden = false;
    CGFloat right = statusMessage.frame.origin.x + statusMessage.frame.size.width;
    [statusMessage sizeToFit];
    [statusMessage setFrameOrigin:CGPointMake(right - statusMessage.frame.size.width, statusMessage.frame.origin.y)];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_hideStatusMessage:) object:nil];
    [self performSelector:@selector(_hideStatusMessage:) withObject:nil afterDelay:1.0];
}

-(void) _hideStatusMessage:(id)dummy {
    statusMessage.hidden = true;
}

-(void) performMiniaturize:(id)sender {
    if(!fullScreen) [self miniaturize:sender];
}

#pragma mark Time Interface

-(void) _startPeriodicTimeInterfaceUpdates {
    timeInterfaceUpdateTimer = [NSTimer
        scheduledTimerWithTimeInterval:0.5
        target:self
        selector:@selector(_scheduledUpdateTimeInterface:)
        userInfo:nil
        repeats:YES
    ];
    [self _updateTimeInterface];
}

// This exists solely because of the requirements of [NSTimer scheduledTimerWithTimeInterval:...selector:...].
-(void) _scheduledUpdateTimeInterface:(id)sender {
    [self _updateTimeInterface];
}

-(void) _updateTimeInterface {
    LAVPMovie* mov = self.noirDoc.movie;
    int t = mov.durationInMicroseconds / 1000000;
    int c = mov.currentTimeInMicroseconds / 1000000;
    int mc = c / 60, sc = c % 60;
    int mt = t / 60, st = t % 60;
    theTimeField.stringValue = [NSString stringWithFormat:@"%d:%02d / %d:%02d", mc, sc, mt, st];
    [theScrubBar setDoubleValue:mov.currentTimeAsFraction];
    [theScrubBar setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Overlays

-(void) _initOverlayWindow {
    [overlayWindow setFrame:self.frame display:false];
    overlayWindow.level = self.level;
    [self addChildWindow:overlayWindow ordered:NSWindowAbove];
    [overlayWindow orderFront:self];
    [self _hideControlsOverlay];
    [self _hideTitleOverlay];
}

-(void) _hideControlsOverlay {
    controlsOverlay.alphaValue = 0.0;
    if(timeInterfaceUpdateTimer) [timeInterfaceUpdateTimer invalidate];
}

-(void) _hideTitleOverlay {
    titleOverlay.alphaValue = 0.0;
}

-(void) mouseEnteredOverlayView:(NSView*)overlay {
    if(overlay == titleOverlay) {
        if(!fullScreen) titleOverlay.alphaValue = 1.0;
    } else if(overlay == controlsOverlay) {
        controlsOverlay.alphaValue = 1.0;
        [self _startPeriodicTimeInterfaceUpdates];
    }
}

-(void) mouseExitedOverlayView:(NSView*)overlay {
    if(overlay == titleOverlay) [self _hideTitleOverlay];
    else if(overlay == controlsOverlay) [self _hideControlsOverlay];
}

-(void) _onSelfMovedOrResized:(NSNotification*)notification {
    [overlayWindow setFrame:self.frame display:false];
}

#pragma mark -
#pragma mark Window Attributes

-(void) setLevel:(NSInteger)windowLevel {
    overlayWindow.level = windowLevel;
    [super setLevel:windowLevel];
}

-(void) setTitle:(NSString*)title {
    [titleField setStringValue:title];
    super.title = title;
}

#pragma mark -
#pragma mark Window Sizing

-(void) _setInitialSize:(NSSize)naturalSize {
    [self _setAspectRatio:naturalSize];
    self.minSize = NSMakeSize(150 * naturalSize.width / naturalSize.height, 150);
    [self _resizeWithSize:NSMakeSize(self.aspectRatio.width, self.aspectRatio.height) animate:NO];
}

-(void) _resizeWithSize:(NSSize)aSize animate:(BOOL)animate {
    [self setFrame:[self _calcResizeSize:aSize] display:YES animate:animate];
}

-(NSRect) _calcResizeSize:(NSSize)aSize {
    float newHeight = aSize.height;
    float newWidth = aSize.width;

    if(newHeight <= self.minSize.height || newWidth <= self.minSize.width) {
        newHeight = self.frame.size.height;
        newWidth = self.frame.size.width;
    }

    NSRect screenFrame = self.screen.visibleFrame;
    NSRect centerRect = NSMakeRect(self.frame.origin.x + (self.frame.size.width - newWidth) / 2, self.frame.origin.y + (self.frame.size.height - newHeight) / 2, newWidth, newHeight);

    if(self.frame.origin.x < screenFrame.origin.x || self.frame.origin.y < screenFrame.origin.y || self.frame.origin.x + self.frame.size.width > screenFrame.origin.x + screenFrame.size.width || self.frame.origin.y + self.frame.size.height > screenFrame.origin.y + screenFrame.size.height) {
        return centerRect;
    }

    NSRect newRect = centerRect;
    if(newRect.origin.x < screenFrame.origin.x) newRect.origin.x = screenFrame.origin.x;
    if(newRect.origin.y < screenFrame.origin.y) newRect.origin.y = screenFrame.origin.y;

    if(screenFrame.origin.x + screenFrame.size.width < newRect.origin.x + newRect.size.width) newRect.origin.x -= (newRect.origin.x + newRect.size.width) - (screenFrame.origin.x + screenFrame.size.width);
    if(screenFrame.origin.y + screenFrame.size.height < newRect.origin.y + newRect.size.height) newRect.origin.y -= (newRect.origin.y + newRect.size.height) - (screenFrame.origin.y + screenFrame.size.height);

    if(newRect.origin.x < screenFrame.origin.x) newRect.origin.x = centerRect.origin.x;
    if(newRect.origin.y < screenFrame.origin.y) newRect.origin.y = centerRect.origin.y;

    return newRect;
}

-(void) _adjustHeightRetainingAspectRatio:(float)amount {
    if(fullScreen) return;
    float newHeight = self.frame.size.height + amount;
    float newWidth = (self.aspectRatio.width/self.aspectRatio.height)*newHeight;
    if(newHeight <= self.minSize.height) {
        newHeight = self.frame.size.height;
        newWidth = self.frame.size.width;
    }
    [self _resizeWithSize:NSMakeSize(newWidth, newHeight) animate:false];
}

-(IBAction) selectAspectRatio:(id)sender {
    // The menu items have .representedObject set to a float NSNumber via the "User Defined Runtime Attributes" field in Xcode.
    id obj = [sender representedObject];
    NSSize ratio = obj ? NSMakeSize([obj floatValue], 1) : self.noirDoc.movie.naturalSize;
    [self _setAspectRatio:ratio];
    [self _resizeToAspectRatio];
}

-(IBAction) halfSize:(id)sender {
    [self _resizeNormalByScaler:0.5];
}

-(IBAction) normalSize:(id)sender {
    [self _resizeNormalByScaler:1.0];
}

-(IBAction) doubleSize:(id)sender {
    [self _resizeNormalByScaler:2.0];
}

-(void) _resizeNormalByScaler:(float)aScaler {
    if(fullScreen) return;
    [self _resizeWithSize: NSMakeSize(aScaler * self.aspectRatio.width, aScaler * self.aspectRatio.height) animate:NO];
}

-(void) _setAspectRatio:(NSSize)ratio {
    self.aspectRatio = ratio;
    self.minSize = NSMakeSize(self.minSize.height / ratio.height * ratio.width, self.minSize.height);
}

-(void) _resizeToAspectRatio {
    NSSize ratio = self.aspectRatio;
    float newWidth = self.frame.size.height / ratio.height * ratio.width;
    NSSize aSize = NSMakeSize(newWidth, self.frame.size.height);
    [self _resizeWithSize:aSize animate:YES];
    if(fullScreen) [self _fillScreen];
}

#pragma mark -
#pragma mark Mouse Events

-(void) mouseDown:(NSEvent *)anEvent {
    if(anEvent.clickCount > 0 && anEvent.clickCount % 2 == 0) {
        [self toggleNoirFullScreen:nil];
    }
}

-(void) scrollWheel:(NSEvent *)ev {
    if(ev.deltaY) {
        [self _adjustHeightRetainingAspectRatio:ev.deltaY * 5];
    } else if(ev.deltaX) {
        [self _stepBy:SCRUB_STEP_DURATION * ev.deltaX];
    }
}

#pragma mark -
#pragma mark Keyboard Events

-(void) keyDown:(NSEvent *)anEvent {
    if((anEvent.modifierFlags & NSShiftKeyMask)) return;
    
    switch([anEvent.characters characterAtIndex:0]){
        case NSRightArrowFunctionKey:
            [self _stepBy:SCRUB_STEP_DURATION];
            break;
        case NSLeftArrowFunctionKey:
            if(anEvent.modifierFlags & NSCommandKeyMask) {
                [self _seekToFraction:0];
                break;
            }
            [self _stepBy:-SCRUB_STEP_DURATION];
            break;
        case 0x1B:
            [self _exitFullScreen];
            break;
        default:
            [super keyDown:anEvent];
    }
}

-(void) _seekToFraction:(double)pos {
    self.noirDoc.movie.currentTimeAsFraction = pos;
    [self _updateTimeInterface];
}

-(void) _stepBy:(int)seconds {
    LAVPMovie* mov = self.noirDoc.movie;
    mov.currentTimeInMicroseconds += seconds * 1000000;
    [self _updateTimeInterface];
}

#pragma mark -
#pragma mark Play/Pause

-(IBAction) togglePlayingMovie:(id)sender {
    LAVPMovie* mov = self.noirDoc.movie;
    bool paused = mov.paused = !mov.paused;
    thePlayButton.image = [NSImage imageNamed:(paused ? @"play" : @"pause")];
    thePlayButton.alternateImage = [NSImage imageNamed:(paused ? @"playClick" : @"pauseClick")];
}

#pragma mark -
#pragma mark Playback Speed

-(IBAction) playFaster:(id)sender {
    [self _adjustSpeed:+5];
}

-(IBAction) playSlower:(id)sender {
    [self _adjustSpeed:-5];
}

-(void) _adjustSpeed:(int)change {
    LAVPMovie* mov = self.noirDoc.movie;
    int percent = mov.playbackSpeedPercent = MAX(10, MIN(200, mov.playbackSpeedPercent + change));
    [self _showStatusMessage:[NSString stringWithFormat:@"Speed: %d%%", percent]];
}

#pragma mark -
#pragma mark Volume

-(IBAction) incrementVolume:(id)sender {
    [self _adjustVolume:+10];
}

-(IBAction) decrementVolume:(id)sender {
    [self _adjustVolume:-10];
}

-(void) _adjustVolume:(int)change {
    LAVPMovie* mov = self.noirDoc.movie;
    int percent = mov.volumePercent = MAX(0, MIN(200, mov.volumePercent + change));
    [self _showStatusMessage:[NSString stringWithFormat:@"Volume: %d%%", percent]];
}

#pragma mark -
#pragma mark Full Screen

// Note: we currently use our own full-screen mechanism, not the standard macOS one.  This is partly historical, and partly that my attempts to get the built-in one to work on our floating windows were unsuccessful.

-(IBAction) toggleNoirFullScreen:(id)sender {
    if(fullScreen) [self _exitFullScreen];
    else [self _enterFullScreen];
}

-(void) _enterFullScreen {
    if(fullScreen) return;
    fullScreen = true;
    [self setLevel:NSFloatingWindowLevel + 2];
    [self makeKeyAndOrderFront:self];
    beforeFullScreen = self.frame;
    [self _fillScreen];
    [overlayWindow setFrame:[NSScreen mainScreen].frame display:false];
    if([self.screen isEqualTo:[NSScreen screens][0]]) NSApp.presentationOptions = NSApplicationPresentationHideDock | NSApplicationPresentationAutoHideMenuBar;
    _fullScreenBackground = [[BlackWindow alloc] init];
    [_fullScreenBackground setFrame:[self.screen frame] display:YES];
    [_fullScreenBackground orderBack:nil];
    [_fullScreenBackground setPresentingWindow:self];
}

-(void) _fillScreen {
    NSSize ratio = self.aspectRatio;
    NSRect screenFrame = self.screen.frame;
    NSSize space = screenFrame.size;
    int h = space.width / ratio.width * ratio.height;
    int w = space.height / ratio.height * ratio.width;
    NSRect frame = h > space.height
        ? NSMakeRect((space.width - w) / 2, 0, w, space.height)
        : NSMakeRect(0, (space.height - h) / 2, space.width, h);
    frame.origin.x += screenFrame.origin.x;
    frame.origin.y += screenFrame.origin.y;
    [self setFrame:frame display:YES];
}

-(void) _exitFullScreen {
    if(!fullScreen) return;
    fullScreen = false;
    [self setLevel:NSFloatingWindowLevel];
    [self setFrame:beforeFullScreen display:false];
    [self _resizeToAspectRatio];
    NSApp.presentationOptions = NSApplicationPresentationDefault;
    [_fullScreenBackground orderOut:nil];
    _fullScreenBackground = nil;
}

@end
