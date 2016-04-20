/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@import Cocoa;

#import "NoirMovieQT.h"
#import "NoirMovieView.h"
#import "NoirWindow.h"

@class NoirWindow;
@class NoirMovieView;

enum PreStepingStates { PSS_INACTIVE, PSS_STOPPED, PSS_PLAYING };

@interface NoirDocument : NSDocument
{
    IBOutlet NoirMovieView *theMovieView;
    IBOutlet NoirWindow *theWindow;
    NSMutableArray *menuObjects;
    BOOL wasPlayingBeforeMini;
    enum PreStepingStates preSteppingState;
}

@property (readonly) NoirMovieQT* movie;

-(void)closeMovie;

-(NSData *)dataRepresentationOfType:(NSString *)aType;

#pragma mark Window Information

-(void)windowDidDeminiaturize:(NSNotification *)aNotification;
-(void)windowControllerDidLoadNib:(NSWindowController *) aController;
-(NSMenu *)movieMenu;
-(void)rebuildMenu;
-(NSMutableArray*)videoMenuItems;
-(NSMenu*)aspectRatioMenu;
-(id)window;

#pragma mark Play/Pause

-(void)togglePlayingMovie;
-(void)playMovie;
-(void)pauseMovie;

#pragma mark Stepping

-(void)startStepping;
-(void)stepBy:(int)aSeconds;
-(void)endStepping;

#pragma mark Time

-(double)currentTimeAsFraction;
-(void)setMovieTimeByFraction:(double)when;

#pragma mark Volume

-(float)volume;
-(void)setVolume:(float)aVolume;
-(void)incrementVolume;
-(void)decrementVolume;

@end
