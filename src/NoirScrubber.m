/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NoirScrubber.h"

#define OFFSET 10

@implementation NoirScrubber

-(instancetype) initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        value = 0.0;
    }
    return self;
}

-(void) drawRect:(NSRect)rect {
    [self lockFocus];

    CGFloat y = floor(self.frame.size.height / 2.0);
    CGFloat x0 = 10;
    CGFloat x2 = self.frame.size.width - OFFSET;
    CGFloat x1 = (x2 - x0) * [self doubleValue] + x0;

    CGContextRef cgRef = [NSGraphicsContext currentContext].graphicsPort;
    CGContextSetAllowsAntialiasing(cgRef, YES);
    CGContextSetLineWidth(cgRef, 4);
    CGContextSetLineCap(cgRef, kCGLineCapRound);

    CGPoint points[2] = { CGPointMake(x0, y), CGPointMake(x2, y) };
    CGContextSetGrayStrokeColor(cgRef, 0.4, 1.0);
    CGContextStrokeLineSegments(cgRef, points, 2);

    points[1] = CGPointMake(x1, y);
    CGContextSetGrayStrokeColor(cgRef, 1.0, 1.0);
    CGContextStrokeLineSegments(cgRef, points, 2);

    [self unlockFocus];
}

-(void) setDoubleValue:(double)aValue {
    value = aValue;
}

-(double) doubleValue {
    return value;
}

-(void) mouseDragged:(NSEvent *)anEvent {
    [self _doUpdate:anEvent];
    [NSApp sendAction:self.action to:self.target from:self];
}

-(void) mouseUp:(NSEvent *)anEvent {
    [self setNeedsDisplay:YES];
}

-(void) mouseDown:(NSEvent *)anEvent {
    [self _doUpdate:anEvent];
    [NSApp sendAction:self.action to:self.target from:self];
}

-(void) _doUpdate:(NSEvent*)ev {
    float loc = [self convertPoint:ev.locationInWindow fromView:nil].x;
    if(loc <= OFFSET) {
        [self setDoubleValue:0.0];
    } else if(loc >= OFFSET && loc <= self.frame.size.width - OFFSET) {
        [self setDoubleValue: (loc - OFFSET) / (self.frame.size.width - OFFSET * 2)];
    } else {
        [self setDoubleValue:1.0];
    }
}

@end
