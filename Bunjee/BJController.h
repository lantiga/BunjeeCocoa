//
//  BJController.h
//  Bunjee
//  Created by Luca Antiga on 6/27/09.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BJWorkspaceController;

@protocol BJMainWindowControllerProtocol
- (void)setWorkspaceController:(id)theWorkspaceController;

@end

@interface BJController : NSObject {
	BJWorkspaceController* workspaceController;
	id<BJMainWindowControllerProtocol> mainWindowController;
}

@property(readonly) BJWorkspaceController* workspaceController;
@property(readonly) id<BJMainWindowControllerProtocol> mainWindowController;

- (id)initWithMainWindowController:(id<BJMainWindowControllerProtocol>)theMainWindowController;

- (id)workspace;

@end
