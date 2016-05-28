/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NoirMovieLAVP.h"


@implementation NoirMovieLAVP

-(instancetype)initWithURL:(NSURL*)url error:(NSError**)outError {
    if(!(self = [super init])) return nil;
    _movie = [[LAVPMovie alloc] initWithURL:url error:outError];
    if(*outError) return nil;
    return self;
}

-(void)showInView:(NSView*)view {
    [view setWantsLayer:YES];
    CALayer *rootLayer = view.layer;
    rootLayer.needsDisplayOnBoundsChange = YES;
    _layer = [LAVPLayer layer];
    [_layer setMovie:_movie];
    _layer.stretchVideoToFitLayer = true;
    _layer.frame = rootLayer.frame;
    _layer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    _layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
    [rootLayer addSublayer:_layer];
}

-(void)close {
    [_layer setMovie:nil];
}

@end
