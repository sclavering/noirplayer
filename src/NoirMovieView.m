/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NoirMovieView.h"

@implementation NoirMovieView

-(instancetype)initWithFrame:(NSRect)aRect
{
    if ((self = [super initWithFrame:aRect])) {
        [self setAutoresizesSubviews:YES];
    }
    return self;
}

-(void)close
{
    [qtlayer setMovie:nil];
    qtlayer = nil;
    movie = nil;
}

-(void)dealloc
{
    [self close];
    [super dealloc];
}

-(void)openMovie:aMovie
{
    qtlayer = [QTMovieLayer layerWithMovie:aMovie];
    qtlayer.frame = self.frame;
    [self setWantsLayer:true];
    self.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
    [self.layer insertSublayer:qtlayer atIndex:0];
    qtlayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    movie = aMovie;
}

-(NSView *)hitTest:(NSPoint)aPoint
{
    if(NSMouseInRect(aPoint, self.frame, NO))
        return self;
    return nil;
}

-(BOOL)acceptsFirstResponder
{
    return YES;
}

#pragma mark -
#pragma mark Mouse Events

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

@end
