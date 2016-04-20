/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NoirScrubber.h"

#define OFFSET 10

@implementation NoirScrubber

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
        scrub = [[NSImage imageNamed:@"scrubber"] retain];
        value = 0.0;
        target = nil;
        action = NULL;
        dragging = NO;
    }
    return self;
}

-(void)dealloc
{
    [scrub release];
    [target release];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect
{
        [self lockFocus];

        CGPoint points[2];
        points[0] = CGPointMake(OFFSET, floor(self.frame.size.height / 2.0));
        points[1] = CGPointMake(self.frame.size.width - OFFSET, floor(self.frame.size.height / 2.0));

        CGContextRef cgRef = [NSGraphicsContext currentContext].graphicsPort;
        CGContextSetAllowsAntialiasing(cgRef, NO);
        CGContextSetGrayStrokeColor(cgRef, 1.0, 1.0);
        CGContextSetLineWidth(cgRef, 1);
        CGContextSetLineCap(cgRef, kCGLineCapRound);
        CGContextStrokeLineSegments(cgRef, points, 2);
        CGContextSetAllowsAntialiasing(cgRef, YES);

        float scrubWidth = self.frame.size.height;
        float scrubHeight = self.frame.size.height;

        [[NSGraphicsContext currentContext] saveGraphicsState];
        [NSGraphicsContext currentContext].imageInterpolation = NSImageInterpolationHigh;
        NSPoint tPoint = NSMakePoint(OFFSET + ([self doubleValue] * (self.frame.size.width - (OFFSET * 2))), self.frame.size.height / 2);
        NSRect tScrubRect = NSMakeRect(tPoint.x, tPoint.y, scrubWidth, scrubHeight);
        [scrub drawInRect:NSIntegralRect(NSOffsetRect(tScrubRect, -tScrubRect.size.width / 2.0, -tScrubRect.size.height / 2.0)) fromRect:NSMakeRect(0, 0, scrub.size.width, scrub.size.height) operation:NSCompositeSourceOver fraction:1.0];
        [[NSGraphicsContext currentContext] restoreGraphicsState];

        [self unlockFocus];
}

-(void)setDoubleValue:(double)aValue
{
    value = aValue;
}

-(double)doubleValue
{
    return value;
}

-(void)setTarget:(id)aTarget
{
    [target release];
    target = [aTarget retain];
}

-(id)target
{
    return target;
}

-(void)setAction:(SEL)anAction
{
    action = anAction;
}

-(SEL)action
{
    return action;
}

- (void)mouseDragged:(NSEvent *)anEvent
{
    [self _doUpdate:anEvent];
    [self.target performSelector:self.action withObject:self];
}

-(void)mouseUp:(NSEvent *)anEvent
{
    dragging = NO;
    [self setNeedsDisplay:YES];
}

-(void)mouseDown:(NSEvent *)anEvent
{
    dragging = YES;
    [self _doUpdate:anEvent];
    [self.target performSelector:self.action withObject:self];
}

-(void)_doUpdate:(NSEvent*)ev
{
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
