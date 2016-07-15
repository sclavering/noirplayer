/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@import Cocoa;

@class NoirRootView;
@class NoirScrubber;
@class NoirDocument;
@class NoirOverlayView;
@class OverlayWindow;
@class LAVPMovie;

@interface NoirWindow : NSWindow
{
    IBOutlet NSTextField* statusMessage;

    IBOutlet OverlayWindow* overlayWindow;
    IBOutlet NoirOverlayView* controlsOverlay;
    IBOutlet NoirOverlayView* titleOverlay;

    IBOutlet NSTextField* titleField;
    IBOutlet NoirScrubber* theScrubBar;
    IBOutlet NSTextField* theTimeField;
    IBOutlet NSButton* thePlayButton;

    BOOL fullScreen;

    NSTimer* timeInterfaceUpdateTimer;

    NSRect beforeFullScreen;

    NSSize aspectRatio;
}

-(NoirDocument*) noirDoc;

-(BOOL) validateMenuItem:(NSMenuItem*)anItem;
-(IBAction) performClose:(id)sender;
-(void) performMiniaturize:(id)sender;

-(void) showMovie:(LAVPMovie*)movie;

#pragma mark -
#pragma mark Overlays

-(void) mouseEnteredOverlayView:(NSView*)overlay;
-(void) mouseExitedOverlayView:(NSView*)overlay;

#pragma mark -
#pragma mark Window Attributes

-(void) makeFullScreen;
-(void) makeNormalScreen;
-(void) setLevel:(NSInteger)windowLevel;
-(void) resizeWithSize:(NSSize)aSize animate:(BOOL)animate;
-(void) setTitle:(NSString *)aString;
-(IBAction) halfSize:(id)sender;
-(IBAction) normalSize:(id)sender;
-(IBAction) doubleSize:(id)sender;
-(void) setAspectRatio:(NSSize)ratio;
-(void) resizeToAspectRatio;

#pragma mark -
#pragma mark Mouse Events

-(void) mouseDown:(NSEvent *)anEvent;
-(void) scrollWheel:(NSEvent *)ev;

#pragma mark -
#pragma mark Play/Pause

@property bool paused;

#pragma mark -
#pragma mark Playback Speed

-(IBAction) playFaster:(id)sender;
-(IBAction) playSlower:(id)sender;

#pragma mark -
#pragma mark Volume

-(IBAction) incrementVolume:(id)sender;
-(IBAction) decrementVolume:(id)sender;

@end
