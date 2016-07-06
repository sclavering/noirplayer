/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@import Cocoa;

#import "NoirWindow.h"
#import "libavPlayer/libavPlayer.h"


@class NoirWindow;

@interface NoirDocument : NSDocument
{
    IBOutlet NoirWindow *theWindow;
    BOOL wasPlayingBeforeMini;
    bool _isStepping;
    bool _wasPlayingBeforeStepping;
}

@property (readonly) LAVPMovie* movie;

-(NSData *) dataRepresentationOfType:(NSString *)aType;

#pragma mark Window Information

-(void) windowDidDeminiaturize:(NSNotification *)aNotification;
-(void) windowControllerDidLoadNib:(NSWindowController *) aController;
-(IBAction) selectAspectRatio:(id)sender;

#pragma mark Play/Pause

@property bool paused;
-(IBAction) togglePlayingMovie:(id)sender;

#pragma mark Stepping

-(void) stepBy:(int)aSeconds;

#pragma mark Volume

-(int) volumePercent;
-(IBAction) incrementVolume:(id)sender;
-(IBAction) decrementVolume:(id)sender;

@end
