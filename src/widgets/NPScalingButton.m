//  Created by James Tuley on 11/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NPScalingButton.h"
#import "NPScalingButtonCell.h"

@implementation NPScalingButton

-(instancetype)initWithCoder:(id)aCoder{
    self =[super initWithCoder:aCoder];
	 NSButtonCell* tCell =[ [[NPScalingButtonCell alloc] init] autorelease];
	tCell.bezelStyle = NSRegularSquareBezelStyle;
	tCell.image = self.cell.image;
    [tCell setAlternateImage:[self.cell alternateImage]];
	tCell.highlightsBy = NSContentsCellMask;

	[tCell setBordered:NO];
	self.cell = tCell;
	
    return self;
}


@end
