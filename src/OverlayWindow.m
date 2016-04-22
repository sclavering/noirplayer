/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * The superclass that sets up all of the states necessary for the overlay to operate properly.
 */

#import "OverlayWindow.h"
#import "NoirWindow.h"

@implementation OverlayWindow

-(instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    if((self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES])) {
        self.backgroundColor = [[NSColor blackColor] colorWithAlphaComponent:0.55];
        [self setOpaque:NO];
    }
    return self;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

-(BOOL)canBecomeMainWindow
{
    return NO;
}

-(BOOL)canBecomeKeyWindow
{
    return NO;
}

-(void)awakeFromNib
{
    [self setHasShadow:NO];
    self.nextResponder = self.parentWindow;
}

-(void)mouseMoved:(NSEvent *)anEvent
{
    NSEvent *newEvent = [NSEvent mouseEventWithType:NSMouseMoved
        location:[((NoirWindow *)self.parentWindow) convertScreenToBase:[NSEvent mouseLocation]]
        modifierFlags:0
        timestamp:0
        windowNumber:0
        context:nil
        eventNumber:0
        clickCount:0
        pressure:1.0];
    [((NoirWindow *)self.parentWindow) mouseMoved:newEvent];
}

// mouseEntered/mouseLeaved are called because NoirOverlayRootView sets up a tracking-area with us as the "owner" (i.e. target).

-(void)mouseEntered:(NSEvent *)ev {
    // Do nothing.  NoirMovieMovie has its own tracking-area that's used to triggering showing the overlay window.
}

-(void)mouseExited:(NSEvent *)ev {
    [((NoirWindow*)self.parentWindow) mouseExitedOverlayWindow:self];
}

- (void)sendEvent:(NSEvent *)theEvent
{
    if(theEvent.type == NSScrollWheel)
        [((NoirWindow *)self.parentWindow) scrollWheel:theEvent];
    else
        [super sendEvent:theEvent];
}

@end
