/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "VolumeView.h"

@implementation VolumeView

-(instancetype)initWithCoder:(id)aCoder
{
    self = [super initWithCoder:aCoder];
    volume = 1.0;
    return self;
}

- (BOOL)acceptsFirstResponder
{
    return NO;
}

-(void)setVolume:(float)aVolume{
    volume = aVolume;
    [self setNeedsDisplay];

}

- (void)drawRect:(NSRect)aRect{
    [super drawRect:aRect];
    float hue = 0.0;
    float top = 2.0;
    if(volume <= 1.0) {
        hue = 117.0 / 360.0;
        top = 1.0;
    }
    [[NSColor colorWithDeviceHue:hue saturation:0.5 brightness:top/volume alpha:1.0] set];
    NSRectFill(NSMakeRect(20, 15, 32 * volume, 8));
}

@end
