/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "libavPlayer/libavPlayer.h"

@interface NoirMovieLAVP : NSObject
{
    LAVPView* _view;
@public
    LAVPMovie* _movie;
}

-(instancetype)initWithURL:(NSURL*)url error:(NSError**)outError;

-(void)showInView:(NSView*)view;
-(void)close;

@end
