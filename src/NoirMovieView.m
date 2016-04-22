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

// Set up tracking areas to trigger showing the title bar and control bars.
-(void)updateTrackingAreas {
    while(self.trackingAreas.count) [self removeTrackingArea:self.trackingAreas[0]];

    NSRect titleRect = self.bounds;
    float titlebarHeight = [((NoirWindow*)self.window) titlebarHeight];
    titleRect.origin.y = titleRect.size.height - titlebarHeight;
    titleRect.size.height = titlebarHeight;
    [self addTrackingArea: [[NSTrackingArea alloc] initWithRect:titleRect options:NSTrackingMouseEnteredAndExited|NSTrackingActiveInActiveApp owner:self userInfo:nil]];

    NSRect controlsRect = self.bounds;
    controlsRect.size.height = [((NoirWindow*)self.window) scrubberHeight];
    [self addTrackingArea: [[NSTrackingArea alloc] initWithRect:controlsRect options:NSTrackingMouseEnteredAndExited|NSTrackingActiveInActiveApp owner:self userInfo:nil]];
}

-(void)mouseEntered:(NSEvent*)ev {
    NoirWindow* win = (NoirWindow*)self.window;
    if(ev.locationInWindow.y > [win scrubberHeight]) {
        [win showOverLayTitle];
    } else {
        [win showOverlayControlBar];
    }
}

-(void)mouseExited:(NSEvent*)ev {
    // We don't do anything here, because showing the child window will cause an immediate exit of the tracking area.
}


@end
