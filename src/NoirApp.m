/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * The application subclass that allows for us to detect mouse movement when the application
 * is not in focus, allowing us to show and hide movie controls even when other apps are
 * active.
 */

#import "NoirApp.h"


@implementation NoirApp

- (void)finishLaunching
{
    [super finishLaunching];
    lastPoint = [NSEvent mouseLocation];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    [self testCursorMovement];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	[self testCursorMovement];
}

/**
* This method tests to see if the mouse has moved to a different location. If so, inject the event into
 * our applications loop in order to determine of the mouse is in a place where the controls should appear
 * for the movie controller or title bar.
 */
-(void)testCursorMovement
{
    if(!NSEqualPoints(lastPoint, [NSEvent mouseLocation])){
        lastPoint = [NSEvent mouseLocation];
        NSEvent *newEvent = [[NSEvent mouseEventWithType:NSMouseMoved
                                               location:lastPoint
                                          modifierFlags:0
                                              timestamp:0
                                           windowNumber:0
                                                context:nil
                                            eventNumber:0
                                             clickCount:0
                                               pressure:1.0] retain];
        [self sendEvent:newEvent];
		[newEvent release];
    }
}

/* Ripped from http://www.cocoabuilder.com/archive/message/cocoa/2004/9/1/116398 */

- (void)sendEvent:(NSEvent *)anEvent
{
    // Catch first right mouse click, activate app and hand the event on to the window for further processing
    BOOL done = NO;
    NSPoint locationInWindow;
    NSWindow *theWindow;
    NSView *theView = nil;
    if(!self.active) {
        // we do NOT get an NSRightMouseDown event
        if(anEvent.type == NSRightMouseUp || anEvent.type == NSMouseMoved) {
            // there seems to be no window assigned with this event at the moment;
            // but just in case ...
            if((theWindow = anEvent.window)) {
                locationInWindow = anEvent.locationInWindow;
                theView = [theWindow.contentView hitTest:locationInWindow];
            } else {
                // find window
                NSPoint locationOnScreen = [NSEvent mouseLocation];
                NSEnumerator *enumerator = [self.orderedWindows objectEnumerator];
                while((theWindow = [enumerator nextObject])) {
                    if(!NSPointInRect(locationOnScreen, theWindow.frame)) continue;
                    locationInWindow = [theWindow convertScreenToBase:locationOnScreen];
                    NSView *contentView = theWindow.contentView;
                    if(!contentView) continue;
                    theView = [contentView hitTest:locationInWindow];
                    if(theView) break;
                }
            }
            if(theView) {
                // create new event with useful window, location and event values
                unsigned int flags = anEvent.modifierFlags;
                NSTimeInterval timestamp = anEvent.timestamp;
                int windowNumber = theWindow.windowNumber;
                NSGraphicsContext *context = anEvent.context;
                // original event is not a mouse down event so the following values are missing
                int eventNumber = 0; // [anEvent eventNumber]
                int clickCount = 0; // [anEvent clickCount]
                float pressure = 1.0; // [anEvent pressure]
                NSEvent *newEvent = [NSEvent mouseEventWithType:anEvent.type location:locationInWindow modifierFlags:flags timestamp:timestamp windowNumber:windowNumber context:context eventNumber:eventNumber clickCount:clickCount pressure:pressure];
                if([theView acceptsFirstMouse:newEvent]) {
                    // activate app and send event to the window
                    //[self activateIgnoringOtherApps:YES];
                    [theWindow sendEvent:newEvent];
                    done = YES;
                }
            }
        }
    }
    
    if (!done) {
        // we did not catch this one
        [super sendEvent:anEvent];
    }
}

@end
