/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <AppKit/AppKit.h>
#import "NoirController.h"
#import "NoirWindow.h"

@interface BlackWindow : NSWindow {
    id presentingWindow;
}

-(void)setPresentingWindow:(id)window;

@end