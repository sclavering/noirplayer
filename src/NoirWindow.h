/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@import Cocoa;

@class NoirMovieView;
@class NoirScrubber;

@interface NoirWindow : NSWindow
{
    IBOutlet NoirMovieView* theMovieView;
    IBOutlet id theOverlayControllerWindow;
    IBOutlet id theOverlayTitleBar;
    IBOutlet id theOverlayVolume;
    IBOutlet id theVolumeView;
    IBOutlet id theTitleField;

    IBOutlet NoirScrubber* theScrubBar;
    IBOutlet id theTimeField;
    IBOutlet NSButton* thePlayButton;
	
    BOOL windowOverlayControllerIsShowing;
    BOOL titleOverlayIsShowing;

    BOOL fullScreen;
    BOOL isFilling;

    BOOL dropScreen;		/* Controls movie dropping onto other screens (not the primary display) */
    id timeUpdaterTimer;
    NSRect beforeFullScreen;

    NSSize aspectRatio;
    NSPoint initialDrag;
}

-(float)scrubberHeight;

-(float)titlebarHeight;

-(BOOL)validateMenuItem:(NSMenuItem*)anItem;
-(IBAction)performClose:(id)sender;
-(void)updateVolume;
-(void)performMiniaturize:(id)sender;
-(IBAction)updateByTime:(id)sender;

#pragma mark -
#pragma mark Overlays
-(void)setupOverlays;
-(void)putOverlay:(NSWindow*)anOverlay inFrame:(NSRect)aFrame;
-(void)hideOverlays;
-(void)showOverlayControlBar;
-(void)setOverlayControllerWindowLocation;
-(void)hideOverLayWindow;
-(void)showOverLayTitle;
-(void)setOverlayTitleLocation;
-(void)hideOverLayTitle;
-(void)showVolumeOverlay;
-(void)hideVolumeOverlay:(id)dummy;

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
-(void)resize:(float)amount animate:(BOOL)animate;
- (void)setTitle:(NSString *)aString;
-(void)initialDefaultSize;
-(IBAction)halfSize:(id)sender;
-(IBAction)normalSize:(id)sender;
-(IBAction)doubleSize:(id)sender;
-(void)fillScreenSize;
-(void)setAspectRatio:(NSSize)ratio;
-(NSSize)getResizeAspectRatioSize;
-(void)resizeToAspectRatio;
-(void)resizeNormalByScaler:(float)aScaler;
-(void)centerOnScreen;
-(NSRect)centerRect:(NSRect)aRect;

#pragma mark -
#pragma mark Mouse Events

-(void)mouseDown:(NSEvent *)anEvent;
-(void)mouseDragged:(NSEvent *)anEvent;
-(void)mouseMoved:(NSEvent *)anEvent;
-(void)mouseUp:(NSEvent *)anEvent;
-(void)setInitialDrag:(NSEvent *)anEvent;
-(void)scrollWheel:(NSEvent *)anEvent;

#pragma mark -
#pragma mark Accessor Methods

-(id)playButton;

#pragma mark -
#pragma mark Misc

-(void)updatePlayButton:(BOOL)isPlaying;

@end
