/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <AppKit/AppKit.h>
#import "BlackWindow.h"
#import "NoirWindow.h"

@interface NoirController : NSDocumentController {
    bool fullScreenMode;
    NSDate* lastCursorMoveDate;
    NSPoint lastMouseLocation;
    NSTimer* mouseMoveTimer;
    id backgroundWindow;
    id antiSleepTimer;
}

+(id)controller;
+(void)setController:(id)aNoirController;

-(void)checkMouseLocation:(id)sender;
-(id)mainDocument;

-(IBAction)openDocument:(id)sender;

-(IBAction)toggleFullScreen:(id)sender;
-(void)enterFullScreen;
-(void)exitFullScreen;

-(id)backgroundWindow;

@end
