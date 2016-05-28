/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NoirMovieLAVP.h"


@interface NoirLAVPView : LAVPView
@end

@implementation NoirLAVPView
// So we can start dragging the video window even when the app is in the background.
-(BOOL)acceptsFirstMouse:(NSEvent *)ev {
    return true;
}
@end


@implementation NoirMovieLAVP

-(instancetype)initWithURL:(NSURL*)url error:(NSError**)outError {
    if(!(self = [super init])) return nil;
    _movie = [[LAVPMovie alloc] initWithURL:url error:outError];
    if(*outError) return nil;
    return self;
}

-(void)showInView:(NSView*)view {
    _view = [[NoirLAVPView alloc] init];
    [_view setMovie:_movie];
    _view.frame = view.frame;
    [view addSubview:_view];
    view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    // view.layer.needsDisplayOnBoundsChange = YES;
    _view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
}

-(void)close {
    _movie.paused = true;
    [_view setMovie:nil];
}

-(NSSize)naturalSize {
    return [_movie frameSize];
}

-(double)currentTimeAsFraction {
    return [_movie position];
}

-(void)setCurrentTimeAsFraction:(double)when {
    [_movie setPosition:when];
}

-(void)adjustCurrentTimeBySeconds:(int)num {
    _movie.currentTimeInMicroseconds += num * 1000000;
}

-(NSString*)currentTimeString {
    int t = _movie.durationInMicroseconds / 1000000;
    int c = _movie.currentTimeInMicroseconds / 1000000;
    int mc = c / 60, sc = c % 60;
    int mt = t / 60, st = t % 60;
    return [NSString stringWithFormat:@"%d:%02d / %d:%02d", mc, sc, mt, st];
}

@end
