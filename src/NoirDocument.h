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

-(void) windowDidDeminiaturize:(NSNotification *)aNotification;
-(void) windowControllerDidLoadNib:(NSWindowController *) aController;

@end
