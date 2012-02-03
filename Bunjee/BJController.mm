//
//  BJController.m
//  Bunjee
//  Created by Luca Antiga on 6/27/09.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import "BJController.h"

#import "BJWorkspaceController.h"
#import "BJWorkspace.h"
#import "BJScene.h"
#import "BJDataDisplay.h"
#import "BJCase.h"
#import "BJData.h"


@implementation BJController

@synthesize mainWindowController;
@synthesize workspaceController;

- (id)initWithMainWindowController:(id<BJMainWindowControllerProtocol>)theMainWindowController {
	self = [self init];
	if (self) {
		mainWindowController = theMainWindowController;
		[mainWindowController setWorkspaceController:workspaceController];
	}
	
	return self;
}

- (id)init {
	self = [super init];
	if (self) {
		workspaceController = [[BJWorkspaceController alloc] init];		
	}
	
	return self;
}

- (id)workspace {
	return [workspaceController workspace];
}

@end
