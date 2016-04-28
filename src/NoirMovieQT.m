/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NoirMovieQT.h"


@interface QTMovie(IdlingAdditions)
-(QTTime)maxTimeLoaded;
@end


@implementation NoirMovieQT

-(instancetype)initWithURL:(NSURL*)url error:(NSError**)outError {
    if(!(self = [super init])) return nil;
    _qtmovie = [QTMovie movieWithURL:url error:outError];
    if(*outError) return nil;
    return self;
}

-(void)showInView:(NSView*)view {
    CALayer* layer = [QTMovieLayer layerWithMovie:_qtmovie];
    layer.frame = view.frame;
    [view setWantsLayer:true];
    view.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
    [view.layer insertSublayer:layer atIndex:0];
    layer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
}

-(void)close {
    // xxx formerly we did [qtlayer setMovie:nil] here, but it doesn't seem to matter
}

-(BOOL)isPlaying
{
    return [_qtmovie rate] != 0.0;
}

-(void)play {
    [_qtmovie play];
}

-(void)pause {
    [_qtmovie stop];
}

-(NSSize)naturalSize {
    NSSize sz = [[_qtmovie attributeForKey: QTMovieNaturalSizeAttribute] sizeValue];
    return sz.width && sz.height ? sz : NSMakeSize(320, 240);
}

-(double)currentTimeAsFraction {
    return [self _currentTime] / [self _totalTime];
}

-(void)setCurrentTimeAsFraction:(double)when {
    [self _setCurrentTime: [self _totalTime] * when];
}

-(void)adjustCurrentTimeBySeconds:(int)num {
    [self _setCurrentTime: MAX(0, MIN([self _totalTime], [self _currentTime] + num))];
}

-(NSString*)currentTimeString {
    int t = [self _totalTime];
    int c = [self _currentTime];
    int mc = c / 60, sc = c % 60;
    int mt = t / 60, st = t % 60;
    return [NSString stringWithFormat:@"%d:%02d / %d:%02d", mc, sc, mt, st];
}

-(double)_totalTime {
    QTTime duration = [_qtmovie duration];
    return duration.timeValue / duration.timeScale;
}

-(double)_currentTime {
    QTTime current = [_qtmovie currentTime];
    return current.timeValue / current.timeScale;
}

-(void)_setCurrentTime:(double)newMovieTime {
    [_qtmovie setCurrentTime:QTMakeTime(newMovieTime, 1)];
}

-(float)volume {
    return [_qtmovie volume];
}

-(void)setVolume:(float)val {
    [_qtmovie setVolume:val];
    [_qtmovie setMuted:false];
}

@end
