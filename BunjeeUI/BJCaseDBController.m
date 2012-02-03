//
//  BJCaseDBController.m
//  Bunjee
//
//  Created by Luca Antiga on 7/21/11.
//  Copyright 2011 Orobix Srl. All rights reserved.
//

#import "BJCaseDBController.h"
#import "BJWorkspaceController.h"
#import "BJWorkspace.h"

@implementation BJCaseDBController

@synthesize workspaceController;
@synthesize caseDBArrayController;
@synthesize caseTableView;
@synthesize columnProperties;
@synthesize columnsNeedUpdate;

- (id)init {
	self = [self initWithNibName:@"CaseDBView" bundle:[NSBundle bundleWithIdentifier:@"com.orobix.BunjeeKit"]];
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];	
    if (self) {
		workspaceController = nil;
		columnProperties = nil;
		columnsNeedUpdate = YES;
    }
    return self;
}

- (void)awakeFromNib {
	//FIXME: it doesn't work
	[caseTableView setDoubleAction:@selector(shouldOpenCase:)];
}
/*
- (void)setColumnProperties:(NSArray *)props {
	columnProperties = [props copy];
	[self setColumnsNeedUpdate:YES];
}
*/
- (void)updateTable {
	CGFloat tableWidth = [[self view] frame].size.width;
	CGFloat columnWidth = tableWidth / [columnProperties count];
	
	[[caseDBArrayController mutableArrayValueForKey:@"content"] removeAllObjects];
//	if (columnsNeedUpdate == YES) {
	{
		NSArray* tableColumns = [[caseTableView tableColumns] copy];
		for (id tableColumn in tableColumns) {
			[caseTableView removeTableColumn:tableColumn];
		}
		
		NSMutableArray* columnNames = [[NSMutableArray alloc] init];
		for (id prop in columnProperties) {
			[columnNames addObject:[prop objectForKey:@"Name"]];
		}
		
		for (id columnName in columnNames) {
			NSTableColumn *aColumn = [[NSTableColumn alloc] initWithIdentifier:columnName];
			[aColumn setWidth:columnWidth];
			[aColumn setMinWidth:50];
			[aColumn setEditable:NO];
			[[aColumn dataCell] setControlSize:NSSmallControlSize];
			[[aColumn dataCell] setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
			[[aColumn headerCell] setStringValue:columnName];
			NSString* keyPath = [NSString stringWithFormat:@"arrangedObjects.%@",columnName];
			[aColumn bind:NSValueBinding toObject:caseDBArrayController withKeyPath:keyPath options:nil];		
			[caseTableView addTableColumn:aColumn];
		}
		[self setColumnsNeedUpdate:NO];
	}
	
	NSArray* allCasesPropertyList = [[workspaceController workspace] allCasesPropertyList];

	for (id casePropertyList in allCasesPropertyList) {
		NSMutableDictionary* row = [[NSMutableDictionary alloc] init];
		id value = [casePropertyList valueForKeyPath:@"CasePath"];
		if (value) {
			[row setObject:[casePropertyList valueForKeyPath:@"CasePath"] forKey:@"CasePath"];
		}
		else {
			[row setObject:@"" forKey:@"CasePath"];
		}

		for (id prop in columnProperties) {
			id value = [casePropertyList valueForKeyPath:[prop objectForKey:@"KeyPath"]];
			if (value == nil) {
				[row setObject:@"" forKey:[prop objectForKey:@"Name"]];
				continue;
			}
			[row setObject:value forKey:[prop objectForKey:@"Name"]];
		}
		[caseDBArrayController addObject:row];		
	}
	
	[caseTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
}

- (IBAction)shouldOpenCase:(id)sender {
	NSArray* selectedObjects = [caseDBArrayController selectedObjects];
	if ([selectedObjects count] == 0) {
		return;
	}
	NSString* casePath = [[selectedObjects objectAtIndex:0] objectForKey:@"CasePath"];
	[workspaceController openCaseFromPath:casePath];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CaseDBShouldClose" object:self userInfo:nil];
}

@end
