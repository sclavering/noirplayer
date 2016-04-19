/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// The black window that forms the background behind a movie when it is displayed full screen.

#import "BlackWindow.h"

@implementation BlackWindow

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
    self.backgroundColor = [NSColor blackColor];
    presentingWindow =nil;
    [self setLevel:NSFloatingWindowLevel+1];
    return self;
}

- (BOOL)canBecomeMainWindow
{
    return NO;
}

- (BOOL)canBecomeKeyWindow
{
    return NO;
}

-(void)setPresentingWindow:(id)window
{
    presentingWindow = window;
}

- (BOOL)isExcludedFromWindowsMenu
{
    return YES;
}

-(void)mouseDown:(NSEvent *)anEvent
{
    if(presentingWindow != nil)
        [presentingWindow makeKeyAndOrderFront:anEvent];
}

-(void)mouseUp:(NSEvent *)anEvent
{
}

-(void)orderOut:(id)sender
{
    presentingWindow = nil;
    [super orderOut:sender];
}

@end
