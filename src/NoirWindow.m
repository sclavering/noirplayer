/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NoirMovieView.h"
#import "NoirDocument.h"
#import "OverlaysControl.h"
#import "NoirController.h"
#import "NoirScrubber.h"
#import "NoirWindow.h"
#import "NoirApp.h"

#define SCRUB_STEP_DURATION 5


@implementation NoirWindow

-(NoirDocument*)noirDoc
{
    return self.windowController.document;
}

-(float)scrubberHeight
{
    return [theOverlayControllerWindow frame].size.height;
}

-(float)titlebarHeight
{
    return [theOverlayTitleBar frame].size.height;
}

- (instancetype)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)aStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag
{
    if((self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES])){
        timeUpdaterTimer = [NSTimer scheduledTimerWithTimeInterval:1
            target:self
            selector:@selector(updateByTime:)
            userInfo:nil
            repeats:YES];
        self.backgroundColor = [NSColor blackColor];
        [self setOpaque:YES];
        [self useOptimizedDrawing:YES];
        [self setHasShadow:YES];
        dropScreen = NO;
        isFilling = NO;
        windowOverlayControllerIsShowing = NO;
        titleOverlayIsShowing = NO;
    }
    return self;
}

-(void)awakeFromNib
{
    self.contentView = theMovieView;
    [self setReleasedWhenClosed:YES];

    id tParagraph = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    [tParagraph setAlignment:NSCenterTextAlignment];

    if(![self isFullScreen]) [self setLevel:NSFloatingWindowLevel];
    [self makeFirstResponder:self];
    [self setAcceptsMouseMovedEvents:YES];

    thePlayButton.keyEquivalent = @" ";
    thePlayButton.target = self;
    thePlayButton.action = @selector(doTogglePlaying);

    theScrubBar.target = self;
    theScrubBar.action = @selector(doSetPosition:);
}


// xxx this should probably live elsewhere
-(void)doTogglePlaying {
    [[self noirDoc] togglePlayingMovie];
}

-(IBAction)doSetPosition:(id)sender {
    [[self noirDoc] setMovieTimeByFraction:[sender doubleValue]];
    [self updateByTime:sender];
}

-(void)updatePlayButton:(BOOL)isPlaying {
    if(isPlaying) {
        thePlayButton.image = [NSImage imageNamed:@"pause"];
        thePlayButton.alternateImage = [NSImage imageNamed:@"pauseClick"];
    } else {
        thePlayButton.image = [NSImage imageNamed:@"play"];
        thePlayButton.alternateImage = [NSImage imageNamed:@"playClick"];
    }
}

-(void)close
{
    NSAutoreleasePool* tPool = [NSAutoreleasePool new];
    [timeUpdaterTimer invalidate];

    [[self noirDoc] closeMovie];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super close];

    [tPool release];
}

#pragma mark Overriden Methods

-(void)resignMainWindow
{
    [self hideOverLayWindow];
    [self hideOverLayTitle];
    [super resignMainWindow];
}

-(void)setFrame:(NSRect)frameRect display:(BOOL)displayFlag
{
    [super setFrame:frameRect display:displayFlag];
    [self setOverlayControllerWindowLocation];
    [self setOverlayTitleLocation];
}

-(void)setFrameOrigin:(NSPoint)orign
{
    [super setFrameOrigin:orign];
}

-(BOOL)canBecomeMainWindow
{
    return YES;
}

-(void)becomeKeyWindow
{
    [super becomeKeyWindow];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RebuildAllMenus" object:nil];
}

-(BOOL)canBecomeKeyWindow
{
    return YES;
}

#pragma mark Interface Items

- (BOOL)validateMenuItem:(NSMenuItem*)anItem
{
    switch(anItem.tag){
        case 7:
            return YES;
        default:
            return [super validateMenuItem:anItem];
    }
}

-(IBAction)performClose:(id)sender
{
    [self.windowController.document pauseMovie];
    [self orderOut:sender]; //order out before stops double button click from causing crash
    if(fullScreen) [[NSDocumentController sharedDocumentController] toggleFullScreen:sender];
    [self close];
}

-(void)updateVolumeIndicator {
    float vol = [[self noirDoc] volume];
    int percent = (int) floor(vol * 100);
    volumeIndicator.stringValue = [NSString stringWithFormat:@"Volume: %d%%", percent];
    volumeIndicator.hidden = false;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideVolumeIndicator:) object:nil];
    [self performSelector:@selector(hideVolumeIndicator:) withObject:nil afterDelay:1.0];
}

-(void)hideVolumeIndicator:(id)dummy {
    volumeIndicator.hidden = true;
}

- (void)performMiniaturize:(id)sender
{
    if(!fullScreen) [self miniaturize:sender];
}

-(IBAction)updateByTime:(id)sender
{
    if((sender != self) && theScrubBar.hidden)
        return;

    NoirDocument* doc = self.windowController.document;

    int t = doc.movie.totalTime;
    int c = doc.movie.currentTime;
    int mc = c / 60, sc = c % 60, mt = t / 60, st = t % 60;
    id str = [NSString stringWithFormat:@"%d:%02d / %d:%02d", mc, sc, mt, st];
    [theTimeField setAttributedStringValue: [[[NSAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName: [NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]}] autorelease]];

    if(theMovieView) [theScrubBar setDoubleValue:[doc currentTimeAsFraction]];
    [theScrubBar setNeedsDisplay:YES];
}


#pragma mark -
#pragma mark Overlays

/**
* Setup the locations of all of the overlays given the initial setup of the window. There are three
 * primary overlay windows: the controller bar, the title bar and the volume window.
 */
-(void)setupOverlays
{
    NSRect currentFrame = self.frame;
    [self putOverlay:theOverlayControllerWindow inFrame:NSMakeRect(currentFrame.origin.x, currentFrame.origin.y, currentFrame.size.width, [theOverlayControllerWindow frame].size.height)];
    [self putOverlay:theOverlayTitleBar inFrame:NSMakeRect(currentFrame.origin.x, currentFrame.origin.y + currentFrame.size.height-[theOverlayTitleBar frame].size.height, currentFrame.size.width, [theOverlayTitleBar frame].size.height)];
}

-(void)putOverlay:(NSWindow*)anOverlay inFrame:(NSRect)aFrame
{
    [anOverlay setFrame:aFrame display:NO];
    anOverlay.alphaValue = 0.0;
    anOverlay.level = self.level;
    [self addChildWindow:anOverlay ordered:NSWindowAbove];
    [anOverlay orderFront:self];
}

-(void)hideOverlays
{
    [self hideOverLayWindow];
    [self hideOverLayTitle];
}

-(void)showOverlayControlBar
{
    if(windowOverlayControllerIsShowing) return;
    [self updateByTime:self];
    [self setOverlayControllerWindowLocation];
    [theOverlayControllerWindow setAlphaValue:1.0];
    windowOverlayControllerIsShowing = YES;
}

/**
* All of this logic is to set the location of the controller/scrubber bar that appears upon mouseover -- its
 * location is dependant on the screen position of the window, the mode of the window, and the location
 * of the window.
 */
-(void)setOverlayControllerWindowLocation
{
    NSRect mainFrame = [NSScreen mainScreen].visibleFrame;
    NSRect r = fullScreen ? mainFrame : NSIntersectionRect(self.frame, mainFrame);
    [theOverlayControllerWindow setFrame:NSMakeRect(r.origin.x, r.origin.y, r.size.width, [theOverlayControllerWindow frame].size.height) display:YES];
}

-(void)hideOverLayWindow
{
    if(!windowOverlayControllerIsShowing) return;
    [theOverlayControllerWindow setAlphaValue:0.0];
    windowOverlayControllerIsShowing = NO;
}

-(void)showOverLayTitle
{
    [self setOverlayTitleLocation];
    if(titleOverlayIsShowing) return;
    [theOverlayTitleBar setAlphaValue:1.0];
    titleOverlayIsShowing = YES;
}

/**
* All of this logic is to set the location of the title bar that appears upon mouseover -- its location is
 * dependant on the screen position of the window, the mode of the window, and the location of the window.
 */
-(void)setOverlayTitleLocation
{
    NSRect frame = self.frame;
    NSRect visibleFrame = [NSScreen mainScreen].visibleFrame;
    NSRect intersect = NSIntersectionRect(frame,visibleFrame);
    if(!fullScreen) {
        [theOverlayTitleBar setFrame:NSMakeRect(intersect.origin.x, intersect.origin.y + intersect.size.height - [theOverlayTitleBar frame].size.height, intersect.size.width, [theOverlayTitleBar frame].size.height) display:YES];
    } else {
        if([[NSScreen mainScreen] isEqualTo:[NSScreen screens][0]]) {
            visibleFrame = [NSScreen mainScreen].frame;
            [theOverlayTitleBar setFrame:NSMakeRect(visibleFrame.origin.x, visibleFrame.origin.y + visibleFrame.size.height - [theOverlayTitleBar frame].size.height - NSApp.mainMenu.menuBarHeight, visibleFrame.size.width, [theOverlayTitleBar frame].size.height) display:YES];
        } else {
            [theOverlayTitleBar setFrame:NSMakeRect(visibleFrame.origin.x, visibleFrame.origin.y + visibleFrame.size.height - [theOverlayTitleBar frame].size.height, visibleFrame.size.width, [theOverlayTitleBar frame].size.height) display:YES];
        }
    }
}

-(void)hideOverLayTitle
{
    if(!titleOverlayIsShowing) return;
    [theOverlayTitleBar setAlphaValue:0.0];
    titleOverlayIsShowing = NO;
}

#pragma mark -
#pragma mark Window Toggles

-(BOOL)toggleWindowFullScreen
{
    [[NoirController controller] toggleFullScreen:self];
    return fullScreen;
}

-(void)unFullScreen
{
    [[NoirController controller] exitFullScreen];
}

#pragma mark Window Attributes

-(void)makeFullScreen
{
    if(!fullScreen) {
        fullScreen = YES;
        [self setLevel:NSFloatingWindowLevel + 2];
        [self makeKeyAndOrderFront:self];
        beforeFullScreen = self.frame;
        [self fillScreenSize];
    }
    [theOverlayControllerWindow setAlphaValue:0.0];
    [theOverlayTitleBar setAlphaValue:0.0];
}

-(void)makeNormalScreen
{
    if(fullScreen) {
        [self setLevel:NSFloatingWindowLevel];
        isFilling = NO;
        [self setFrame:beforeFullScreen display:NO];
        fullScreen = NO;
        [self resizeToAspectRatio];
    }
    [theOverlayTitleBar orderFront:self];
    [theOverlayControllerWindow orderFront:self];
    [self hideOverLayWindow];
    [self setInitialDrag:nil];
}

-(BOOL)isFullScreen
{
    return fullScreen;
}

-(void)setLevel:(NSInteger)windowLevel
{
    id enumerator = [self.childWindows objectEnumerator];
    id object;
    while((object = [enumerator nextObject])) [object setLevel:windowLevel];
    super.level = windowLevel;
}

/**
* Resize the window to the given resolution. Resizes the window depending on the window pinning preferences.
 * Setting animate to YES will cause the window to perform an animated resizing effect.
 */
-(void)resizeWithSize:(NSSize)aSize animate:(BOOL)animate
{
    [self setFrame:[self calcResizeSize:aSize] display:YES animate:animate];
}

-(NSRect)calcResizeSize:(NSSize)aSize
{
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

-(void)adjustHeightRetainingAspectRatio:(float)amount {
    float newHeight = self.frame.size.height + amount;
    float newWidth = (self.aspectRatio.width/self.aspectRatio.height)*newHeight;
    if(newHeight <= self.minSize.height) {
        newHeight = self.frame.size.height;
        newWidth = self.frame.size.width;
    }
    [self resizeWithSize:NSMakeSize(newWidth, newHeight) animate:false];
}

- (void)setTitle:(NSString *)aString
{
    [theTitleField setStringValue:aString];
    super.title = aString;
}

-(IBAction)halfSize:(id)sender
{
    [self resizeNormalByScaler:0.5];
}

-(IBAction)normalSize:(id)sender
{
    [self resizeNormalByScaler:1.0];
}

-(IBAction)doubleSize:(id)sender
{
    [self resizeNormalByScaler:2.0];
}

-(void)resizeNormalByScaler:(float)aScaler
{
    isFilling = NO;
    [self resizeWithSize: NSMakeSize(aScaler * self.aspectRatio.width, aScaler * self.aspectRatio.height) animate:NO];
    if(fullScreen) [self centerOnScreen];
    [self setInitialDrag:nil];
}

-(void)fillScreenSize
{
    isFilling = YES;
    NSSize aSize = [self getResizeAspectRatioSize];
    NSRect newRect = [self calcResizeSize:aSize];
    newRect.origin.x = 0;
    newRect = [self centerRect:newRect];
    [self setFrame:newRect display:YES];
    [self centerOnScreen];
}

/**
* Sets the internally stored aspect ratio size.
 */
- (void)setAspectRatio:(NSSize)ratio
{
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

-(NSSize)getResizeAspectRatioSize
{
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

-(void)initialDefaultSize
{
    [self resizeWithSize:NSMakeSize(self.aspectRatio.width, self.aspectRatio.height) animate:YES];
    if(fullScreen) [self centerOnScreen];
}

-(void)resizeToAspectRatio
{
    NSSize aSize = [self getResizeAspectRatioSize];
    [self resizeWithSize:aSize animate:YES];
    if(isFilling) [self fillScreenSize];
}

-(void)centerOnScreen
{
    [self setInitialDrag:nil];
    if(fullScreen) [self removeChildWindow:theOverlayTitleBar];
    [self setFrame:[self centerRect:self.frame] display:YES];
    if(fullScreen) [self addChildWindow:theOverlayTitleBar ordered:NSWindowAbove];
}

-(NSRect)centerRect:(NSRect)aRect
{
    NSRect screenRect = fullScreen ? self.screen.frame : self.screen.visibleFrame;
    return NSOffsetRect(aRect, NSMidX(screenRect) - NSMidX(aRect), NSMidY(screenRect) - NSMidY(aRect));
}

#pragma mark -
#pragma mark Mouse Events

-(void)mouseDown:(NSEvent *)anEvent
{
    if(anEvent.clickCount > 0 && anEvent.clickCount % 2 == 0) {
        [self setInitialDrag:anEvent];
        [self toggleWindowFullScreen];
    } else {
        [self setInitialDrag:anEvent];
    }
}

-(void)mouseDragged:(NSEvent *)anEvent
{
    if(fullScreen && !NSEqualRects([[[NSDocumentController sharedDocumentController] backgroundWindow] frame], [NSScreen mainScreen].frame)) {
        [[[NSDocumentController sharedDocumentController] backgroundWindow] setFrame:[NSScreen mainScreen].frame display:YES];
        if([[NSScreen mainScreen] isEqualTo:[NSScreen screens][0]]) NSApp.presentationOptions = NSApplicationPresentationHideDock | NSApplicationPresentationAutoHideMenuBar;
        dropScreen = YES;
    }
    [self showOverLayTitle];
    /* If we don't do a remove, the child window gets automatically placed when the parent window moves, even if we try
        to set the location manually. */
    if(fullScreen) [self removeChildWindow:theOverlayTitleBar];
    [self setFrameOrigin:NSMakePoint([NSEvent mouseLocation].x-initialDrag.x,[NSEvent mouseLocation].y-initialDrag.y)];
    if(fullScreen) [self addChildWindow:theOverlayTitleBar ordered:NSWindowAbove];
}


/* Used to detect what controls the mouse is currently over. */
- (void)mouseMoved:(NSEvent *)anEvent
{
    [[OverlaysControl control] mouseMovedInScreenPoint:[self convertBaseToScreen:anEvent.locationInWindow]];
}

-(void)mouseUp:(NSEvent *)anEvent
{
    if(dropScreen) { // If the screen has been dropped onto a different display
        [self centerOnScreen];
        if(isFilling) [self fillScreenSize];
    }
    dropScreen = NO;
    [self hideOverLayTitle];
}

/* These two events always get passed down to the view. */

-(void)setInitialDrag:(NSEvent *)anEvent
{
    initialDrag = [self convertScreenToBase:[NSEvent mouseLocation]];
}

-(void)scrollWheel:(NSEvent *)anEvent
{
    float deltaX = anEvent.deltaX, deltaY = anEvent.deltaY;
    if(deltaX) {
        id doc = self.windowController.document;
        [doc startStepping];
        [doc stepBy:SCRUB_STEP_DURATION * deltaX];
        [doc endStepping];
    }
    if(deltaY) [self adjustHeightRetainingAspectRatio:deltaY * 5];
}

#pragma mark -
#pragma mark Keyboard Events

-(void)keyDown:(NSEvent *)anEvent
{
    if((anEvent.modifierFlags & NSShiftKeyMask)) return;
    
    switch([anEvent.characters characterAtIndex:0]){
        case ' ':
            if(!anEvent.ARepeat) [[self noirDoc] togglePlayingMovie];
            break;
        case NSRightArrowFunctionKey:
            if(!anEvent.ARepeat) [[self noirDoc] startStepping];
            [[self noirDoc] stepBy:SCRUB_STEP_DURATION];
            break;
        case NSLeftArrowFunctionKey:
            if(anEvent.modifierFlags & NSCommandKeyMask) {
                [self noirDoc].movie.currentTime = 0;
                break;
            }
            if(!anEvent.ARepeat) [[self noirDoc] startStepping];
            [[self noirDoc] stepBy:-SCRUB_STEP_DURATION];
            break;
        case NSUpArrowFunctionKey:
            [[self noirDoc] incrementVolume];
            break;
        case NSDownArrowFunctionKey:
            [[self noirDoc] decrementVolume];
            break;
        case 0x1B:
            [self unFullScreen];
            break;
        default:
            [super keyDown:anEvent];
    }
}

-(void)keyUp:(NSEvent*)anEvent
{
    if((anEvent.modifierFlags & NSShiftKeyMask)) return;

    switch([anEvent.characters characterAtIndex:0]){
        case ' ':
            break;
        case NSRightArrowFunctionKey:
            [[self noirDoc] endStepping];
            break;
        case NSLeftArrowFunctionKey:
            [[self noirDoc] endStepping];
            break;
        default:
            [super keyUp:anEvent];
    }
}

@end
