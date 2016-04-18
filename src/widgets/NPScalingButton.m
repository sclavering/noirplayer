//  Created by James Tuley on 11/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NPScalingButton.h"

@implementation NPScalingButton

-(instancetype)initWithCoder:(id)aCoder{
    self =[super initWithCoder:aCoder];
    [self.cell setImageScaling:NSImageScaleProportionallyDown];
    return self;
}


@end
