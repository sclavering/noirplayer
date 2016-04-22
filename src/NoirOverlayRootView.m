/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// This class just exists to use set up the tracking-area to hide the overlay-window when the mouse leaves it.

#import "NoirOverlayRootView.h"

@implementation NoirOverlayRootView

-(void)awakeFromNib {
    [self addTrackingArea: [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited|NSTrackingActiveInActiveApp|NSTrackingInVisibleRect owner:self.window userInfo:nil]];
}

@end
