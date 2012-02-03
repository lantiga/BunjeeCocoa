//
//  BJCaseDBController.h
//  Bunjee
//
//  Created by Luca Antiga on 7/21/11.
//  Copyright 2011 Orobix Srl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BJWorkspaceController;

@interface BJCaseDBController : NSViewController {
	IBOutlet NSArrayController* caseDBArrayController;
	IBOutlet NSTableView* caseTableView;
	NSArray* columnProperties;
	BJWorkspaceController* workspaceController;
	BOOL columnsNeedUpdate;
}

@property(readwrite,retain) BJWorkspaceController* workspaceController;
@property(readwrite) BOOL columnsNeedUpdate;
@property(readonly) NSArrayController* caseDBArrayController;
@property(readonly) NSTableView* caseTableView;
@property(readwrite,copy) NSArray* columnProperties;

- (void)updateTable;
- (IBAction)shouldOpenCase:(id)sender;

@end
