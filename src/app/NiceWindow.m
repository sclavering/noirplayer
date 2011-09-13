/* ***** BEGIN LICENSE BLOCK *****
* Version: MPL 1.1/GPL 2.0/LGPL 2.1
*
* The contents of this file are subject to the Mozilla Public License Version
* 1.1 (the "License"); you may not use this file except in compliance with
* the License. You may obtain a copy of the License at
* http://www.mozilla.org/MPL/
*
* Software distributed under the License is distributed on an "AS IS" basis,
* WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
* for the specific language governing rights and limitations under the
* License.
*
* The Original Code is NicePlayer.
*
* The Initial Developer of the Original Code is
* James Tuley & Robert Chin.
* Portions created by the Initial Developer are Copyright (C) 2004-2006
* the Initial Developer. All Rights Reserved.
*
* Contributor(s):
*           Robert Chin <robert@osiris.laya.com> (NicePlayer Author)
*           James Tuley <jay+nicesource@tuley.name> (NicePlayer Author)
*
* Alternatively, the contents of this file may be used under the terms of
* either the GNU General Public License Version 2 or later (the "GPL"), or
* the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
* in which case the provisions of the GPL or the LGPL are applicable instead
* of those above. If you wish to allow use of your version of this file only
* under the terms of either the GPL or the LGPL, and not to allow others to
* use your version of this file under the terms of the MPL, indicate your
* decision by deleting the provisions above and replace them with the notice
* and other provisions required by the GPL or the LGPL. If you do not delete
* the provisions above, a recipient may use your version of this file under
* the terms of any one of the MPL, the GPL or the LGPL.
*
* ***** END LICENSE BLOCK ***** */

#import "NPMovieView.h"
#import "NiceDocument.h"
#import "OverlaysControl.h"
#import "NiceController.h"
#import "NiceScrubber.h"
#import "NiceWindow.h"
#import "NPApplication.h"
#import "ControlPlay.h"

#define SCRUB_STEP_DURATION 5


@implementation NiceWindow

-(float)scrubberHeight
{
    return [theOverlayControllerWindow frame].size.height;
}

-(float)titlebarHeight
{
    return [theOverlayTitleBar frame].size.height;
}

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)aStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag
{
    if((self = [super initWithContentRect:contentRect
								styleMask:NSBorderlessWindowMask
								  backing:NSBackingStoreBuffered
									defer:YES])){
        timeUpdaterTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                            target:self
                                                          selector:@selector(updateByTime:)
                                                          userInfo:nil
                                                           repeats:YES];
        [self setBackgroundColor:[NSColor blackColor]];
        [self setOpaque:YES];
        [self useOptimizedDrawing:YES];
        [self setHasShadow:YES];
        dropScreen = NO;
        isFilling = NO;
        windowOverlayControllerIsShowing = NO;
        titleOverlayIsShowing = NO;
		fixedAspectRatio = YES;
    }
    return self;
}

-(void)awakeFromNib
{
    [theScrubBar setTarget:theMovieView];
    [self setContentView:theMovieView];
    [theScrubBar setAction:@selector(scrub:)];
    [self setReleasedWhenClosed:YES];
	
	id tParagraph = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[tParagraph setAlignment:NSCenterTextAlignment];

    if(![self isFullScreen]) [self setLevel:NSFloatingWindowLevel];
    [self makeFirstResponder:self]; 
    [self setAcceptsMouseMovedEvents:YES];
    
    [thePlayButton setKeyEquivalent:@" "];
    [thePlayButton setActionView:theMovieView];
}

-(void)close
{
	NSAutoreleasePool* tPool = [NSAutoreleasePool new];
    [timeUpdaterTimer invalidate];

    [theMovieView close];
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
    switch([anItem tag]){
        case 7:
            return YES;
            break;
        default:
            return [super validateMenuItem:anItem];        
    }
    
}

-(IBAction)performClose:(id)sender
{
    [[[self windowController] document] pauseMovie];
    [self orderOut:sender]; //order out before stops double button click from causing crash
    if(fullScreen) [[NSDocumentController sharedDocumentController] toggleFullScreen:sender];
    [self close];
}

-(void)updateVolume
{
    [theVolumeView setVolume:[[theMovieView niceDocument] volume]];
}

- (void)performMiniaturize:(id)sender
{
    if(!fullScreen) [self miniaturize:sender];
}

/**
* Takes care of updating the time display window, as well as choosing the format for the time display.
 * Current the format can only be of two different choices: time elapsed or time remaining.
 */
-(IBAction)updateByTime:(id)sender
{
    if((sender != self) && [theScrubBar isHidden])
        return;

    NiceDocument* doc = [[self windowController] document];

    int t = [doc totalTime];
    int c = [doc currentMovieTime];
    int mc = c / 60, sc = c % 60, mt = t / 60, st = t % 60;
    id str = [NSString stringWithFormat:@"%d:%02d / %d:%02d", mc, sc, mt, st];
    [theTimeField setAttributedStringValue: [[[NSAttributedString alloc] initWithString:str attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]], NSFontAttributeName, nil]] autorelease]];

	if(theMovieView) {
		[theScrubBar setDoubleValue:[doc currentTimeAsFraction]];
		[theScrubBar setLoadedValue:[doc percentLoaded]];
	}
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
    NSRect currentFrame = [self frame];
    [self putOverlay:theOverlayControllerWindow asChildOf:self inFrame:NSMakeRect(currentFrame.origin.x, currentFrame.origin.y, currentFrame.size.width, [theOverlayControllerWindow frame].size.height) withVisibility:NO];
    [self putOverlay:theOverlayTitleBar asChildOf:self inFrame:NSMakeRect(currentFrame.origin.x, currentFrame.origin.y + currentFrame.size.height-[theOverlayTitleBar frame].size.height, currentFrame.size.width, [theOverlayTitleBar frame].size.height) withVisibility:NO];
    [self putOverlay:theOverlayVolume asChildOf:self inFrame:NSOffsetRect([theOverlayVolume frame], NSMidX(currentFrame) - NSMidX([theOverlayVolume frame]), NSMidY(currentFrame) - NSMidY([theOverlayVolume frame])) withVisibility:NO];
}

-(void)putOverlay:(NSWindow*)anOverlay asChildOf:(NSWindow*)aWindow inFrame:(NSRect)aFrame withVisibility:(BOOL)isVisible
{
    [anOverlay setFrame:aFrame display:NO];
    [anOverlay setAlphaValue:(isVisible ? 1.0 : 0.0)];
    [anOverlay setLevel:[self level]];
	/* For some reason on Tiger, we have to add the child window after we set the alpha and level, otherwise
		the child window is visible in locations as setFrame: is being called, very odd. Didn't bother to file
		it in radar. */
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
    NSRect mainFrame = [[NSScreen mainScreen] visibleFrame];
    NSRect r = fullScreen ? mainFrame : NSIntersectionRect([self frame], mainFrame);
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
    NSRect frame = [self frame];
    NSRect visibleFrame = [[NSScreen mainScreen] visibleFrame];
    NSRect intersect = NSIntersectionRect(frame,visibleFrame);
    if(!fullScreen) {
        if(NSEqualRects(intersect, frame)) {
            [theOverlayTitleBar setFrame:NSMakeRect(frame.origin.x, frame.origin.y + frame.size.height - [theOverlayTitleBar frame].size.height, frame.size.width, [theOverlayTitleBar frame].size.height) display:YES];
        } else {
            [theOverlayTitleBar setFrame:NSMakeRect(intersect.origin.x, intersect.origin.y + intersect.size.height - [theOverlayTitleBar frame].size.height, intersect.size.width, [theOverlayTitleBar frame].size.height) display:YES];
        }
    } else {
        if([[NSScreen mainScreen] isEqualTo:[[NSScreen screens] objectAtIndex:0]]) {
            visibleFrame = [[NSScreen mainScreen] frame];
            [theOverlayTitleBar setFrame:NSMakeRect(visibleFrame.origin.x, visibleFrame.origin.y + visibleFrame.size.height - [theOverlayTitleBar frame].size.height - [[NSApp mainMenu] menuBarHeight], visibleFrame.size.width, [theOverlayTitleBar frame].size.height) display:YES];
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

-(void)showVolumeOverlay
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideVolumeOverlay:) object:nil];
    [self performSelector:@selector(hideVolumeOverlay:) withObject:nil afterDelay:1.0];
    NSRect frame = [self frame];
    NSRect visibleFrame = [[NSScreen mainScreen] visibleFrame];
    NSRect intersect = NSIntersectionRect(frame, visibleFrame);
    [theOverlayVolume setFrame:NSOffsetRect([theOverlayVolume frame], NSMidX(intersect) - NSMidX([theOverlayVolume frame]), NSMidY(intersect) - NSMidY([theOverlayVolume frame])) display:YES];
    [theOverlayVolume setAlphaValue:1.0];
}

-(void)hideVolumeOverlay:(id)dummy
{
    [theOverlayVolume setAlphaValue:0.0];
}

#pragma mark -
#pragma mark Window Toggles

-(BOOL)toggleWindowFullScreen
{
    [[NiceController controller] toggleFullScreen:self];
    return fullScreen;
}

-(void)unFullScreen
{
    [[NiceController controller] exitFullScreen];
}

-(void)setFixedAspect:(BOOL)aBool
{
    if(aBool){
        [self setAspectRatio:aspectRatio];
        _lastSize = NSMakeSize(0, 0);
        [self resizeToAspectRatio];
    } else {
        [self setResizeIncrements:NSMakeSize(1.0, 1.0)];
    }
}

-(BOOL)fixedAspect
{
    return fixedAspectRatio;
}

#pragma mark Window Attributes

-(void)makeFullScreen
{
    if(!fullScreen) {
		fullScreen = YES;
		[self setLevel:NSFloatingWindowLevel + 2];
		[self makeKeyAndOrderFront:self];
		beforeFullScreen = [self frame];
		[self fillScreenSize];
    }
    [theMovieView drawMovieFrame];
    [theOverlayControllerWindow setAlphaValue:0.0];
    [theOverlayTitleBar setAlphaValue:0.0];
    [theOverlayVolume setAlphaValue:0.0];
}

-(void)makeNormalScreen
{
    if(fullScreen) {
		[self setLevel:NSFloatingWindowLevel];
        isFilling = NO;
        [self setFrame:beforeFullScreen display:NO];
        fullScreen = NO;
        if([self fixedAspect]) [self resizeToAspectRatio];
    }
    [theMovieView drawMovieFrame];
    [theOverlayTitleBar orderFront:self];
    [theOverlayVolume orderFront:self];
    [theOverlayControllerWindow orderFront:self];
    [self hideOverLayWindow];
    [self setInitialDrag:nil];
}

-(BOOL)isFullScreen
{
    return fullScreen;
}

/**
* Sets the window level by setting all of the windows and child windows to their own proper window levels.
 */
-(void)setLevel:(int)windowLevel
{
    id enumerator = [[self childWindows] objectEnumerator];
    id object;
    while((object = [enumerator nextObject])) [object setLevel:windowLevel];
    [super setLevel:windowLevel];
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

    if(newHeight <= [self minSize].height || newWidth <= [self minSize].width) {
        newHeight = [self frame].size.height;
        newWidth = [self frame].size.width;
    }

    NSRect screenFrame = [[self screen] visibleFrame];
    NSRect centerRect = NSMakeRect([self frame].origin.x + ([self frame].size.width - newWidth) / 2, [self frame].origin.y + ([self frame].size.height - newHeight) / 2, newWidth, newHeight);

    if([self frame].origin.x < screenFrame.origin.x || [self frame].origin.y < screenFrame.origin.y || [self frame].origin.x + [self frame].size.width > screenFrame.origin.x + screenFrame.size.width || [self frame].origin.y + [self frame].size.height > screenFrame.origin.y + screenFrame.size.height) {
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

/**
* Resize the window by a floating point percentage value, with 1.0 being no change.
 * Setting animate to YES will cause the window to animate while resizing.
 */
-(void)resize:(float)amount animate:(BOOL)animate
{
    float deltaHeight = amount;
    float newHeight = [self frame].size.height + deltaHeight;
    float newWidth = ([self aspectRatio].width/[self aspectRatio].height)*newHeight;
    if(newHeight <= [self minSize].height) {
        newHeight =[self frame].size.height;
        newWidth= [self frame].size.width;
    }
    [self resizeWithSize:NSMakeSize(newWidth, newHeight) animate:animate];
}

- (void)setTitle:(NSString *)aString
{
    [theTitleField setStringValue:aString];
    [super setTitle:aString];
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
    [self resizeWithSize: NSMakeSize(aScaler * [self aspectRatio].width, aScaler * [self aspectRatio].height) animate:NO];
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
    [super setAspectRatio:ratio];
    [self setMinSize:NSMakeSize(([self aspectRatio].width/[self aspectRatio].height) *[self minSize].height,[self minSize].height)];
    fixedAspectRatio = YES;
}

-(void)setResizeIncrements:(NSSize)increments
{
    [super setResizeIncrements:increments];
    fixedAspectRatio = NO;
}

- (NSSize)aspectRatio
{
    if(fixedAspectRatio) return [super aspectRatio];
    return NSMakeSize(([self frame].size.width / [self frame].size.height) * aspectRatio.height, aspectRatio.height);
}

/**
* Get the size given the aspect ratio and current size. This returns a size that has the same height
 * as the current window, but with the width adjusted wrt to the aspect ratio. Or if the window is
 * full screen, it returns a size that has the width stretched out to fit the screen,
 * assuming the current video is also screen filling.
 */

-(NSSize)getResizeAspectRatioSize
{
    NSSize ratio = [self aspectRatio];
    float newWidth = (([self frame].size.height / ratio.height) * ratio.width);
    if(isFilling) {
        NSRect frame = [[self screen] frame];
        float width = frame.size.width;
        float height = frame.size.height;
        float calcHeigth =(width / ratio.width) * ratio.height;
        if(calcHeigth > height) return NSMakeSize((height / ratio.height) * ratio.width, height);
        return NSMakeSize(width, (width / ratio.width) * ratio.height);
    }
    return NSMakeSize(newWidth, [self frame].size.height);
}

-(void)initialDefaultSize
{
    id doc = [[self windowController] document];
    _lastSize = [doc naturalSize];
    [self resizeWithSize:NSMakeSize([self aspectRatio].width, [self aspectRatio].height) animate:YES];
    if(fullScreen) [self centerOnScreen];
}

/**
* Resize the window to the size returned by getResizeAspectRatioSize
 */
-(void)resizeToAspectRatio
{
    NSSize aSize = [self getResizeAspectRatioSize];
    [self resizeWithSize:aSize animate:YES];
    if(isFilling) [self fillScreenSize];
    _lastSize = aSize;
}

-(void)centerOnScreen
{
    [self setInitialDrag:nil];
    if(fullScreen) [self removeChildWindow:theOverlayTitleBar];
    [self setFrame:[self centerRect:[self frame]] display:YES];
    if(fullScreen) [self addChildWindow:theOverlayTitleBar ordered:NSWindowAbove];
}

-(NSRect)centerRect:(NSRect)aRect
{
    NSRect screenRect = fullScreen ? [[self screen] frame] : [[self screen] visibleFrame];
    return NSOffsetRect(aRect, NSMidX(screenRect) - NSMidX(aRect), NSMidY(screenRect) - NSMidY(aRect));
}

#pragma mark -
#pragma mark Mouse Events

-(void)mouseDown:(NSEvent *)anEvent
{
    if([anEvent clickCount] > 0 && [anEvent clickCount] % 2 == 0) {
        [self setInitialDrag:anEvent];
        [self toggleWindowFullScreen];
    } else {
        [self setInitialDrag:anEvent];
    }
}

-(void)mouseDragged:(NSEvent *)anEvent
{
    if(fullScreen && !NSEqualRects([[[NSDocumentController sharedDocumentController] backgroundWindow] frame], [[NSScreen mainScreen] frame])) {
        [[[NSDocumentController sharedDocumentController] backgroundWindow] setFrame:[[NSScreen mainScreen] frame] display:YES];
        if([[NSScreen mainScreen] isEqualTo:[[NSScreen screens] objectAtIndex:0]]) SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
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
    [[OverlaysControl control] mouseMovedInScreenPoint:[self convertBaseToScreen:[anEvent locationInWindow]]];
}

-(void)mouseUp:(NSEvent *)anEvent
{
    if(dropScreen){			// If the screen has been dropped onto a different display
        [self centerOnScreen];
        if(isFilling) [self fillScreenSize];
    }
    dropScreen = NO;
    [self hideOverLayTitle];
}

/* These two events always get passed down to the view. */

-(void)setInitialDrag:(NSEvent *)anEvent
{
	initialDrag =[self convertScreenToBase:[NSEvent mouseLocation]];
}

-(void)scrollWheel:(NSEvent *)anEvent
{
    float deltaX = [anEvent deltaX], deltaY = [anEvent deltaY];
    if(deltaX) {
        id doc = [[self windowController] document];
        [doc startStepping];
        [doc stepBy:SCRUB_STEP_DURATION * deltaX];
        [doc endStepping];
    }
    if(deltaY) [self resize:deltaY * 5 animate:NO];
}

#pragma mark -
#pragma mark Accessor Methods

/* These accessor methods are used to set button attributes by NPMovieView */

-(id)playButton
{
    return thePlayButton;
}

@end
