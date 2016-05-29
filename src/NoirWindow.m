/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NoirWindow.h"

#import "NoirRootView.h"
#import "NoirDocument.h"
#import "NoirController.h"
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
        isFilling = NO;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSelfMovedOrResized:) name:NSWindowDidResizeNotification object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSelfMovedOrResized:) name:NSWindowDidMoveNotification object:self];
    }
    return self;
}

-(void) awakeFromNib {
    [self initOverlayWindow];

    [self setReleasedWhenClosed:YES];

    if(![self isFullScreen]) [self setLevel:NSFloatingWindowLevel];
    [self makeFirstResponder:self];

    thePlayButton.target = self.windowController.document;
    thePlayButton.action = @selector(togglePlayingMovie:);

    theScrubBar.target = self;
    theScrubBar.action = @selector(doSetPosition:);
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResizeNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidMoveNotification object:self];
}

-(IBAction) doSetPosition:(id)sender {
    self.noirDoc.movie.currentTimeAsFraction = [sender doubleValue];
    [self updateTimeInterface];
}

-(void) updatePlayButton:(BOOL)isPlaying {
    if(isPlaying) {
        thePlayButton.image = [NSImage imageNamed:@"pause"];
        thePlayButton.alternateImage = [NSImage imageNamed:@"pauseClick"];
    } else {
        thePlayButton.image = [NSImage imageNamed:@"play"];
        thePlayButton.alternateImage = [NSImage imageNamed:@"playClick"];
    }
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
    _layer.stretchVideoToFitLayer = true;
    _layer.frame = rootLayer.frame;
    _layer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    _layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
    [rootLayer addSublayer:_layer];
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
    if(fullScreen) [[NSDocumentController sharedDocumentController] toggleFullScreen:sender];
    [self close];
}

-(void) updateVolumeIndicator {
    int percent = [[self noirDoc] volumePercent];
    volumeIndicator.stringValue = [NSString stringWithFormat:@"Volume: %d%%", percent];
    volumeIndicator.hidden = false;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideVolumeIndicator:) object:nil];
    [self performSelector:@selector(hideVolumeIndicator:) withObject:nil afterDelay:1.0];
}

-(void) hideVolumeIndicator:(id)dummy {
    volumeIndicator.hidden = true;
}

-(void) performMiniaturize:(id)sender {
    if(!fullScreen) [self miniaturize:sender];
}

#pragma mark Time Interface

-(void) startPeriodicTimeInterfaceUpdates {
    timeInterfaceUpdateTimer = [NSTimer
        scheduledTimerWithTimeInterval:0.5
        target:self
        selector:@selector(scheduledUpdateTimeInterface:)
        userInfo:nil
        repeats:YES
    ];
    [self updateTimeInterface];
}

// This exists solely because of the requirements of [NSTimer scheduledTimerWithTimeInterval:...selector:...].
-(void) scheduledUpdateTimeInterface:(id)sender {
    [self updateTimeInterface];
}

-(void) updateTimeInterface {
    NoirDocument* doc = self.windowController.document;
    LAVPMovie* mov = doc.movie;
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

-(void) initOverlayWindow {
    [overlayWindow setFrame:self.frame display:false];
    overlayWindow.level = self.level;
    [self addChildWindow:overlayWindow ordered:NSWindowAbove];
    [overlayWindow orderFront:self];
    [self hideControlsOverlay];
    [self hideTitleOverlay];
}

-(void) hideControlsOverlay {
    controlsOverlay.alphaValue = 0.0;
    if(timeInterfaceUpdateTimer) [timeInterfaceUpdateTimer invalidate];
}

-(void) hideTitleOverlay {
    titleOverlay.alphaValue = 0.0;
}

-(void) mouseEnteredOverlayView:(NSView*)overlay {
    if(overlay == titleOverlay) {
        if(!fullScreen) titleOverlay.alphaValue = 1.0;
    } else if(overlay == controlsOverlay) {
        controlsOverlay.alphaValue = 1.0;
        [self startPeriodicTimeInterfaceUpdates];
    }
}

-(void) mouseExitedOverlayView:(NSView*)overlay {
    if(overlay == titleOverlay) [self hideTitleOverlay];
    else if(overlay == controlsOverlay) [self hideControlsOverlay];
}

-(void) onSelfMovedOrResized:(NSNotification*)notification {
    [overlayWindow setFrame:self.frame display:false];
}

#pragma mark -
#pragma mark Window Toggles

-(BOOL) toggleWindowFullScreen {
    [[NoirController controller] toggleFullScreen:self];
    return fullScreen;
}

-(void) unFullScreen {
    [[NoirController controller] exitFullScreen];
}

#pragma mark Window Attributes

-(void) makeFullScreen {
    if(!fullScreen) {
        fullScreen = YES;
        [self setLevel:NSFloatingWindowLevel + 2];
        [self makeKeyAndOrderFront:self];
        beforeFullScreen = self.frame;
        [self fillScreenSize];
        [overlayWindow setFrame:[NSScreen mainScreen].frame display:false];
    }
}

-(void) makeNormalScreen {
    if(fullScreen) {
        [self setLevel:NSFloatingWindowLevel];
        isFilling = NO;
        [self setFrame:beforeFullScreen display:NO];
        fullScreen = NO;
        [self resizeToAspectRatio];
    }
    [overlayWindow orderFront:self];
    [self setInitialDrag:nil];
}

-(BOOL) isFullScreen {
    return fullScreen;
}

-(void) setLevel:(NSInteger)windowLevel {
    overlayWindow.level = windowLevel;
    [super setLevel:windowLevel];
}

/**
* Resize the window to the given resolution. Resizes the window depending on the window pinning preferences.
 * Setting animate to YES will cause the window to perform an animated resizing effect.
 */
-(void) resizeWithSize:(NSSize)aSize animate:(BOOL)animate {
    [self setFrame:[self calcResizeSize:aSize] display:YES animate:animate];
}

-(NSRect) calcResizeSize:(NSSize)aSize {
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

-(void) adjustHeightRetainingAspectRatio:(float)amount {
    if(fullScreen) return;
    float newHeight = self.frame.size.height + amount;
    float newWidth = (self.aspectRatio.width/self.aspectRatio.height)*newHeight;
    if(newHeight <= self.minSize.height) {
        newHeight = self.frame.size.height;
        newWidth = self.frame.size.width;
    }
    [self resizeWithSize:NSMakeSize(newWidth, newHeight) animate:false];
}

-(void) setTitle:(NSString*)title {
    [titleField setStringValue:title];
    super.title = title;
}

-(IBAction) halfSize:(id)sender {
    [self resizeNormalByScaler:0.5];
}

-(IBAction) normalSize:(id)sender {
    [self resizeNormalByScaler:1.0];
}

-(IBAction) doubleSize:(id)sender {
    [self resizeNormalByScaler:2.0];
}

-(void) resizeNormalByScaler:(float)aScaler {
    if(fullScreen) return;
    isFilling = NO;
    [self resizeWithSize: NSMakeSize(aScaler * self.aspectRatio.width, aScaler * self.aspectRatio.height) animate:NO];
    [self setInitialDrag:nil];
}

-(void) fillScreenSize {
    isFilling = YES;
    NSSize aSize = [self getResizeAspectRatioSize];
    NSRect newRect = [self calcResizeSize:aSize];
    newRect.origin.x = 0;
    newRect = [self centerRect:newRect];
    [self setFrame:newRect display:YES];
    [self setInitialDrag:nil];
    [self setFrame:[self centerRect:self.frame] display:YES];
}

/**
* Sets the internally stored aspect ratio size.
 */
-(void) setAspectRatio:(NSSize)ratio {
    if((ratio.width == 0) || (ratio.height == 0)){
        ratio.width = 1;
        ratio.height = 1;
    }
    aspectRatio = ratio;
    super.aspectRatio = ratio;
    self.minSize = NSMakeSize((self.aspectRatio.width/self.aspectRatio.height) *self.minSize.height,self.minSize.height);
}

/**
* Get the size given the aspect ratio and current size. This returns a size that has the same height
 * as the current window, but with the width adjusted wrt to the aspect ratio. Or if the window is
 * full screen, it returns a size that has the width stretched out to fit the screen,
 * assuming the current video is also screen filling.
 */

-(NSSize) getResizeAspectRatioSize {
    NSSize ratio = self.aspectRatio;
    float newWidth = ((self.frame.size.height / ratio.height) * ratio.width);
    if(isFilling) {
        NSRect frame = self.screen.frame;
        float width = frame.size.width;
        float height = frame.size.height;
        float calcHeigth =(width / ratio.width) * ratio.height;
        if(calcHeigth > height) return NSMakeSize((height / ratio.height) * ratio.width, height);
        return NSMakeSize(width, (width / ratio.width) * ratio.height);
    }
    return NSMakeSize(newWidth, self.frame.size.height);
}

-(void) resizeToAspectRatio {
    NSSize aSize = [self getResizeAspectRatioSize];
    [self resizeWithSize:aSize animate:YES];
    if(isFilling) [self fillScreenSize];
}

-(NSRect) centerRect:(NSRect)aRect {
    NSRect screenRect = fullScreen ? self.screen.frame : self.screen.visibleFrame;
    return NSOffsetRect(aRect, NSMidX(screenRect) - NSMidX(aRect), NSMidY(screenRect) - NSMidY(aRect));
}

#pragma mark -
#pragma mark Mouse Events

-(void) mouseDown:(NSEvent *)anEvent {
    if(anEvent.clickCount > 0 && anEvent.clickCount % 2 == 0) {
        [self setInitialDrag:anEvent];
        [self toggleWindowFullScreen];
    } else {
        [self setInitialDrag:anEvent];
    }
}

-(void) mouseDragged:(NSEvent *)anEvent {
    if(fullScreen) return;
    [self setFrameOrigin:NSMakePoint([NSEvent mouseLocation].x-initialDrag.x,[NSEvent mouseLocation].y-initialDrag.y)];
}

/* These two events always get passed down to the view. */

-(void) setInitialDrag:(NSEvent *)anEvent {
    initialDrag = [self convertScreenToBase:[NSEvent mouseLocation]];
}

-(void) scrollWheel:(NSEvent *)ev {
    if(ev.deltaY) {
        [self adjustHeightRetainingAspectRatio:ev.deltaY * 5];
    } else if(ev.deltaX) {
        id doc = self.windowController.document;
        [doc stepBy:SCRUB_STEP_DURATION * ev.deltaX];
    }
}

#pragma mark -
#pragma mark Keyboard Events

-(void) keyDown:(NSEvent *)anEvent {
    if((anEvent.modifierFlags & NSShiftKeyMask)) return;
    
    switch([anEvent.characters characterAtIndex:0]){
        case NSRightArrowFunctionKey:
            [[self noirDoc] stepBy:SCRUB_STEP_DURATION];
            break;
        case NSLeftArrowFunctionKey:
            if(anEvent.modifierFlags & NSCommandKeyMask) {
                self.noirDoc.movie.currentTimeAsFraction = 0;
                [self updateTimeInterface];
                break;
            }
            [[self noirDoc] stepBy:-SCRUB_STEP_DURATION];
            break;
        case 0x1B:
            [self unFullScreen];
            break;
        default:
            [super keyDown:anEvent];
    }
}

@end
