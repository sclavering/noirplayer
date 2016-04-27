/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// This class just exists to use set up the tracking-area to hide the overlay-window when the mouse leaves it.

#import "NoirOverlayView.h"

#import "NoirWindow.h"

@implementation NoirOverlayView

-(void)awakeFromNib {
    [self setWantsLayer:true];
    CGColorRef bg = CGColorCreateGenericGray(0.0, 0.55);
    self.layer.backgroundColor = bg;
    CFRelease(bg);

    [self addTrackingArea: [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited|NSTrackingActiveInActiveApp|NSTrackingInVisibleRect owner:self userInfo:nil]];
}

-(void)mouseEntered:(NSEvent *)ev {
    [((NoirWindow*)self.window.parentWindow) mouseEnteredOverlayView:self];
}

-(void)mouseExited:(NSEvent *)ev {
    [((NoirWindow*)self.window.parentWindow) mouseExitedOverlayView:self];
}

@end
