/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <AppKit/AppKit.h>


@interface NoirScrubber : NSControl
{
    NSImage* scrub;
    double value;
    id target;
    SEL action;
}

-(double) doubleValue;
-(void) setDoubleValue:(double)aValue;

-(void) _doUpdate:(NSEvent*)ev;

@end
