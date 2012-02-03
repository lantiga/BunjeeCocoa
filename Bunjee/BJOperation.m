//
//  BJOperation.mm
//  Bunjee
//  Created by Luca Antiga on 5/3/09.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import "BJOperation.h"


@implementation BJOperation

@synthesize executionMessage;
@synthesize name;

- (id)initWithTarget:(id)target selector:(SEL)sel object:(id)arg {
	self = [super initWithTarget:target selector:sel object:arg];
	if (self) {
		executionMessage = [NSString string];
		name = NSStringFromSelector(sel);
	}
	return self;
}

@end
