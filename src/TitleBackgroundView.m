/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "TitleBackgroundView.h"


@implementation TitleBackgroundView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(rebuildTrackingRects)
													 name:NSViewFrameDidChangeNotification
		 												   object:nil];
    }
    return self;
}

-(void)drawRect:(NSRect)rect
{
}

- (void)mouseDown:(NSEvent *)theEvent
{
		if(theEvent.clickCount>1)
			[self.window performMiniaturize:theEvent];
		else
			[self.window mouseDown:theEvent];
}


- (void)mouseDragged:(NSEvent *)theEvent
{
    [self.window mouseDragged:theEvent];
}


-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

-(void)rebuildTrackingRects
{
	[self viewWillMoveToWindow:self.window];
}

-(void)viewWillMoveToWindow:(NSWindow *)window
{
	if(self.window)
		[self removeTrackingRect:trackingRect];
	if(window)
		trackingRect = [self addTrackingRect:self.bounds owner:window userData:nil assumeInside:NO];
}


@end
