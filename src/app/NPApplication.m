
/* ***** BEGIN LICENSE BLOCK *****
* Version: MPL 1.1/GPL 2.0/LGPL 2.1
*
* The contents of this file are subject to the Mozilla Public License Version
* 1.1 (the "License"); you may not use this file except in compliance with
* the License. You may obtain a copy of the License at
* http://www.mozilla.org/MPL/
*
* Software distributed under the License is distributed on an "AS IS" basis,
* WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
* for the specific language governing rights and limitations under the
* License.
*
* The Original Code is NicePlayer.
*
* The Initial Developer of the Original Code is
* Jay Tuley & Robert Chin.
* Portions created by the Initial Developer are Copyright (C) 2004-2005
* the Initial Developer. All Rights Reserved.
*
* Contributor(s):
*           Robert Chin <robert@osiris.laya.com> (NicePlayer Author)
*           James Tuley <jay+nicesource@tuley.name> (NicePlayer Author)
*
* Alternatively, the contents of this file may be used under the terms of
* either the GNU General Public License Version 2 or later (the "GPL"), or
* the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
* in which case the provisions of the GPL or the LGPL are applicable instead
* of those above. If you wish to allow use of your version of this file only
* under the terms of either the GPL or the LGPL, and not to allow others to
* use your version of this file under the terms of the MPL, indicate your
* decision by deleting the provisions above and replace them with the notice
* and other provisions required by the GPL or the LGPL. If you do not delete
* the provisions above, a recipient may use your version of this file under
* the terms of any one of the MPL, the GPL or the LGPL.
*
* ***** END LICENSE BLOCK ***** */

/**
 * The application subclass that allows for us to detect mouse movement when the application
 * is not in focus, allowing us to show and hide movie controls even when other apps are
 * active.
 */

#import "NPApplication.h"
#import "NiceUtilities.h"
#import "ArrayExtras.h"


@implementation NPApplication

- (void)finishLaunching
{
    [super finishLaunching];
    lastPoint = [NSEvent mouseLocation];
    [self setDelegate:self];
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
    if(![self isActive]) {
        // we do NOT get an NSRightMouseDown event
        if([anEvent type] == NSRightMouseUp || [anEvent type] == NSMouseMoved) {
            // there seems to be no window assigned with this event at the moment;
            // but just in case ...
            if((theWindow = [anEvent window])) {
                locationInWindow = [anEvent locationInWindow];
                theView = [[theWindow contentView] hitTest:locationInWindow];
            } else {
                // find window
                NSPoint locationOnScreen = [NSEvent mouseLocation];
                NSEnumerator *enumerator = [[self orderedWindows] objectEnumerator];
                while((theWindow = [enumerator nextObject])) {
                    if(!NSPointInRect(locationOnScreen, [theWindow frame])) continue;
                    locationInWindow = [theWindow convertScreenToBase:locationOnScreen];
                    NSView *contentView = [theWindow contentView];
                    if(!contentView) continue;
                    theView = [contentView hitTest:locationInWindow];
                    if(theView) break;
                }
            }
            if(theView) {
                // create new event with useful window, location and event values
                unsigned int flags = [anEvent modifierFlags];
                NSTimeInterval timestamp = [anEvent timestamp];
                int windowNumber = [theWindow windowNumber];
                NSGraphicsContext *context = [anEvent context];
                // original event is not a mouse down event so the following values are missing
                int eventNumber = 0; // [anEvent eventNumber]
                int clickCount = 0; // [anEvent clickCount]
                float pressure = 1.0; // [anEvent pressure]
                NSEvent *newEvent = [NSEvent mouseEventWithType:[anEvent type] location:locationInWindow modifierFlags:flags timestamp:timestamp windowNumber:windowNumber context:context eventNumber:eventNumber clickCount:clickCount pressure:pressure];
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
