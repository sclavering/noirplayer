/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "TitleTextField.h"

@implementation TitleTextField


- (void)mouseDown:(NSEvent *)theEvent
{
    if(theEvent.clickCount>1)
        [theNoirWindow performMiniaturize:theEvent];
    else
        [theNoirWindow mouseDown:theEvent];
}



- (void)mouseDragged:(NSEvent *)theEvent
{
    [theNoirWindow mouseDragged:theEvent];
}

@end
