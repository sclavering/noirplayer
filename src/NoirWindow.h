/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@import Cocoa;

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

    NSTimer* timeInterfaceUpdateTimer;

    bool fullScreen;
    NSRect beforeFullScreen;
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

-(void) setLevel:(NSInteger)windowLevel;
-(void) setTitle:(NSString *)aString;

#pragma mark -
#pragma mark Window Sizing

-(IBAction) selectAspectRatio:(id)sender;
-(IBAction) halfSize:(id)sender;
-(IBAction) normalSize:(id)sender;
-(IBAction) doubleSize:(id)sender;

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

#pragma mark -
#pragma mark Full Screen

-(IBAction) toggleNoirFullScreen:(id)sender;

@end
