/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * The class that determines which overlays should be showing in which window.
 */

#import "OverlaysControl.h"
#import "NoirWindow.h"

static id overlayControl = nil;

@implementation OverlaysControl

+(id)control
{
	static BOOL tooLate = NO;
	
    if ( !tooLate ) {
        overlayControl = [OverlaysControl new];
        tooLate = YES;
    }
	
	return overlayControl;
}

-(instancetype)init
{
	if(overlayControl)
		return overlayControl;
	
	if((self = [super init])){
	}
	
	return self;
}

-(BOOL)isLocation:(NSPoint)aScreenPoint inWindow:(id)aWindow
{
	return NSMouseInRect(aScreenPoint, [aWindow frame], NO);
}

-(BOOL)inControlRegion:(NSPoint)aScreenPoint forWindow:(NoirWindow *)aWindow
{
    if([aWindow isFullScreen]){
	NSRect mainScreenFrame = [NSScreen mainScreen].frame;
	return (aScreenPoint.y <= (mainScreenFrame.origin.y + [aWindow scrubberHeight])
		&& aScreenPoint.y >= (mainScreenFrame.origin.y)
		&& aScreenPoint.x >= mainScreenFrame.origin.x
		&& aScreenPoint.x <= mainScreenFrame.size.width);
    }
    
    NSRect windowFrame = aWindow.frame;
    NSRect mainVisibleFrame = [NSScreen mainScreen].visibleFrame;
    NSRect tempRect = NSMakeRect(windowFrame.origin.x, windowFrame.origin.y, windowFrame.size.width, [aWindow scrubberHeight]);
    
    if (mainVisibleFrame.origin.y < windowFrame.origin.y){
	tempRect.origin = NSMakePoint(0, 0);
    } else {
	tempRect.origin = [aWindow convertScreenToBase:NSMakePoint(windowFrame.origin.x, mainVisibleFrame.origin.y)];
    }
    return NSMouseInRect([aWindow convertScreenToBase:aScreenPoint], tempRect, NO);
}

-(BOOL)inTitleRegion:(NSPoint)aScreenPoint forWindow:(NoirWindow*)aWindow
{
    if([aWindow isFullScreen]){
		NSRect mainScreenFrame = [NSScreen mainScreen].frame;
		return (aScreenPoint.y <= (mainScreenFrame.origin.y + mainScreenFrame.size.height) 
				&& aScreenPoint.y >= mainScreenFrame.origin.y + mainScreenFrame.size.height - [aWindow titlebarHeight] - NSApp.mainMenu.menuBarHeight
				&& aScreenPoint.x >= mainScreenFrame.origin.x
				&& aScreenPoint.x <= mainScreenFrame.size.width);
	}
	
	NSRect windowFrame = aWindow.frame;
	NSRect mainVisibleFrame = [NSScreen mainScreen].visibleFrame;
	NSRect tempRect = NSMakeRect(windowFrame.origin.x, windowFrame.origin.y + windowFrame.size.height - [aWindow titlebarHeight], windowFrame.size.width, [aWindow titlebarHeight]);

	if(mainVisibleFrame.origin.y + mainVisibleFrame.size.height > windowFrame.origin.y + windowFrame.size.height) {
		tempRect.origin = NSMakePoint(0, windowFrame.size.height - [aWindow titlebarHeight]);
	} else {
	    tempRect.origin = [aWindow convertScreenToBase:NSMakePoint(windowFrame.origin.x, mainVisibleFrame.origin.y + mainVisibleFrame.size.height - [aWindow titlebarHeight])];
	}
	return NSMouseInRect([aWindow convertScreenToBase:aScreenPoint], tempRect, NO);
}

-(void)mouseMovedInScreenPoint:(NSPoint)aScreenPoint
{
    id someWindows = NSApp.orderedWindows;
    BOOL hitTopMost = NO;
    for(unsigned i = 0; i < [someWindows count]; i++) {
        id aWindow = someWindows[i];
        if(![aWindow isKindOfClass:[NoirWindow class]]) continue;
        if(!hitTopMost) {
            if([self showOverlayForWindow:aWindow atPoint:aScreenPoint]) {
                hitTopMost = YES;
                continue;
            }
            if([self isLocation:aScreenPoint inWindow:aWindow]) {
                hitTopMost = YES;
            }
        }
        [aWindow hideOverlays];
    }
}

-(BOOL)showOverlayForWindow:(NoirWindow *)aWindow atPoint:(NSPoint)aScreenPoint
{
    if([self inControlRegion:aScreenPoint forWindow:aWindow]){
		[aWindow showOverlayControlBar];
		return YES;
    } else if([self inTitleRegion:aScreenPoint forWindow:aWindow]){
		[aWindow showOverLayTitle];
		return YES;
    }
    return NO;
}

@end
