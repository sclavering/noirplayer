/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@import Cocoa;

@class NoirRootView;
@class NoirScrubber;
@class NoirDocument;
@class NoirOverlayView;
@class OverlayWindow;

@interface NoirWindow : NSWindow
{
    IBOutlet NSTextField* volumeIndicator;
    IBOutlet id theTitleField;

    IBOutlet OverlayWindow* overlayWindow;
    IBOutlet NoirOverlayView* controlsOverlay;
    IBOutlet NoirOverlayView* titleOverlay;

    IBOutlet NoirScrubber* theScrubBar;
    IBOutlet NSTextField* theTimeField;
    IBOutlet NSButton* thePlayButton;

    BOOL fullScreen;
    BOOL isFilling;

    id timeUpdaterTimer;
    NSRect beforeFullScreen;

    NSSize aspectRatio;
    NSPoint initialDrag;
}

-(NoirDocument*)noirDoc;

-(BOOL)validateMenuItem:(NSMenuItem*)anItem;
-(IBAction)performClose:(id)sender;
-(void)updateVolumeIndicator;
-(void)hideVolumeIndicator:(id)dummy;
-(void)performMiniaturize:(id)sender;
-(IBAction)updateByTime:(id)sender;

#pragma mark -
#pragma mark Overlays

-(void)initOverlayWindow;
-(void)hideControlsOverlay;
-(void)hideTitleOverlay;

-(void)mouseEnteredOverlayView:(NSView*)overlay;
-(void)mouseExitedOverlayView:(NSView*)overlay;

-(void)onSelfMovedOrResized:(NSNotification*)notification;

#pragma mark -
#pragma mark Window Toggles

-(BOOL)toggleWindowFullScreen;
-(void)unFullScreen;

#pragma mark Window Attributes

-(void)makeFullScreen;
-(void)makeNormalScreen;
-(BOOL)isFullScreen;
-(void)setLevel:(NSInteger)windowLevel;
-(void)resizeWithSize:(NSSize)aSize animate:(BOOL)animate;
-(NSRect)calcResizeSize:(NSSize)aSize;
-(void)adjustHeightRetainingAspectRatio:(float)amount;
- (void)setTitle:(NSString *)aString;
-(IBAction)halfSize:(id)sender;
-(IBAction)normalSize:(id)sender;
-(IBAction)doubleSize:(id)sender;
-(void)fillScreenSize;
-(void)setAspectRatio:(NSSize)ratio;
-(NSSize)getResizeAspectRatioSize;
-(void)resizeToAspectRatio;
-(void)resizeNormalByScaler:(float)aScaler;
-(NSRect)centerRect:(NSRect)aRect;

#pragma mark -
#pragma mark Mouse Events

-(void)mouseDown:(NSEvent *)anEvent;
-(void)mouseDragged:(NSEvent *)anEvent;
-(void)setInitialDrag:(NSEvent *)anEvent;
-(void)scrollWheel:(NSEvent *)ev;

#pragma mark -
#pragma mark Misc

-(void)updatePlayButton:(BOOL)isPlaying;

@end
