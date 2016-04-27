/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NoirRootView.h"

@implementation NoirRootView

-(BOOL)acceptsFirstResponder
{
    return YES;
}

-(BOOL)acceptsFirstMouse:(NSEvent *)ev {
    // So we can drag the windows even when the app is in the background.  Not sure why this needs to be here rather than in the overlay's view.
    return true;
}

@end
