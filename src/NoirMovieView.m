/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NoirMovieView.h"

#import "NoirWindow.h"

@implementation NoirMovieView

-(void)displayMovieLayer:(CALayer*)layer
{
    layer.frame = self.frame;
    [self setWantsLayer:true];
    self.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
    [self.layer insertSublayer:layer atIndex:0];
    layer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
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
