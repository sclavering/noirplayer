/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <AppKit/AppKit.h>

@interface NoirController : NSDocumentController
{
    NSDate* lastCursorMoveDate;
    NSPoint lastMouseLocation;
    NSTimer* mouseMoveTimer;
    id antiSleepTimer;
}

+(id) controller;
+(void) setController:(id)aNoirController;

-(void) checkMouseLocation:(id)sender;

-(IBAction) openDocument:(id)sender;

@end
