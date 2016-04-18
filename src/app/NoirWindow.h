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

@import Cocoa;

@class NPMovieView;
@class NoirScrubber;

@interface NoirWindow : NSWindow
{
    IBOutlet NPMovieView* theMovieView;
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