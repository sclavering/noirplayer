/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@import Cocoa;

#import "NoirMovieLAVP.h"
#import "NoirWindow.h"

@class NoirWindow;

@interface NoirDocument : NSDocument
{
    IBOutlet NoirWindow *theWindow;
    BOOL wasPlayingBeforeMini;
    bool _isStepping;
    bool _wasPlayingBeforeStepping;
}

@property (readonly) NoirMovieLAVP* movie;

-(void)closeMovie;

-(NSData *)dataRepresentationOfType:(NSString *)aType;

#pragma mark Window Information

-(void)windowDidDeminiaturize:(NSNotification *)aNotification;
-(void)windowControllerDidLoadNib:(NSWindowController *) aController;
-(IBAction)selectAspectRatio:(id)sender;

#pragma mark Play/Pause

-(IBAction)togglePlayingMovie:(id)sender;
-(void)playMovie;
-(void)pauseMovie;

#pragma mark Stepping

-(void)startStepping;
-(void)stepBy:(int)aSeconds;
-(void)endStepping;

#pragma mark Volume

-(float)volume;
-(void)setVolume:(float)aVolume;
-(IBAction)incrementVolume:(id)sender;
-(IBAction)decrementVolume:(id)sender;

@end
