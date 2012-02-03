//
//  BJOperation.h
//  Bunjee
//  Created by Luca Antiga on 5/3/09.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BJOperation : NSInvocationOperation {
	NSString* executionMessage;
	NSString* name;
}

@property(readwrite,copy) NSString* executionMessage;
@property(readonly) NSString* name;

@end