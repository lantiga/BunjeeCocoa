//
//  BJCaseInfoController.m
//  Bunjee
//  Created by Luca Antiga on 8/17/09.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import "BJCaseBrowserController.h"
#import "BJWorkspaceController.h"
#import "BJWorkspace.h"
#import "BJCase.h"
#import "BJData.h"
#import "BJScene.h"
#import "BJDataDisplay.h"

@implementation BJCaseBrowserController

@synthesize workspace;
@synthesize workspaceController;
@synthesize caseBrowserView;
@synthesize caseBrowserPanel;
@synthesize pathControl;
@synthesize smallFont;

- (id)init {
	self = [self initWithNibName:@"CaseBrowserView" bundle:[NSBundle bundleWithIdentifier:@"com.orobix.BunjeeKit"]];
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];	
	if (self) {
		workspace = nil;
		workspaceController = nil;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(caseHasBeenAdded:) name:@"CaseHasBeenAdded" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(caseHasBeenRemoved:) name:@"CaseHasBeenRemoved" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sceneBrowserSelectionHasChanged:) name:@"SceneBrowserSelectionChanged" object:nil];
		smallFont = YES;
		[self setTitle:@"Cases"];
	}
	
	return self;
}

- (void)finalize {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"CaseHasBeenAdded" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"CaseHasBeenRemoved" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"CaseDataChanged" object:nil];
	[super finalize];
}

- (void)awakeFromNib {
    //XCode4
//	[caseBrowserView setDelegate:self];
}

- (void)setWorkspaceController:(BJWorkspaceController *) theWorkspaceController {
	workspaceController = theWorkspaceController;
	workspace = [workspaceController workspace];
}

- (IBAction)caseFileAction:(id)sender {
	NSInteger selectedSegment = [sender selectedSegment];
    NSInteger clickedSegmentTag = [[sender cell] tagForSegment:selectedSegment];
	
    switch (clickedSegmentTag) {
		case 0: 
			[self newCase:nil]; 
			break;
		case 1: 
			[self openCase:nil]; 
			break;
		case 2: 
			[self saveCase:nil]; 
			break;
		case 3: 
			[self saveCaseAs:nil]; 
			break;
		case 4:
			[self closeCase:nil]; 
			break;
		case 5: 
			[self newCaseFromImage:nil]; 
			break;
		case 6: 
			[self openStudyInOsiriX:nil]; 
			break;
		case 7: 
			[self openCaseDB:nil]; 
			break;
    }	
}

- (IBAction)newCase:(id)sender {
	[workspaceController newCase];
}

- (IBAction)newCaseFromImage:(id)sender {
	[workspaceController newCaseFromImage];
}

- (IBAction)openCase:(id)sender {
	[workspaceController openCase];
}

- (IBAction)saveCaseAs:(id)sender {
	[workspaceController saveCaseAs:[self selectedCase]];
}

- (IBAction)saveCase:(id)sender {
	[workspaceController saveCase:[self selectedCase]];
}

- (IBAction)closeCase:(id)sender {
	[workspaceController closeCase:[self selectedCase]];
}

- (IBAction)removeItemFromCase:(id)sender {
	[workspaceController removeItem:[self selectedCaseItem] fromCase:[self selectedCase]];
}

- (IBAction)removeAllItemsFromCase:(id)sender {
	[workspaceController removeAllItemsFromCase:[self selectedCase]];
}

- (IBAction)addImageToCase:(id)sender {
	[workspaceController addImageToCase:[self selectedCase]];
}

- (IBAction)addSurfaceToCase:(id)sender {
	[workspaceController addSurfaceToCase:[self selectedCase]];
}

- (IBAction)openStudyInOsiriX:(id)sender {
	id selectedCase = [self selectedCase];
	if (selectedCase == nil) {
		return;
	}

	[workspaceController openStudyInOsiriX:selectedCase];
}

- (IBAction)openCaseDB:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldShowCaseDB" object:self userInfo:nil];
}

- (id)selectedCase {
	
	NSArray* caseFolderAndName = [self selectedCaseFolderAndName];
	
	id caseName = [caseFolderAndName objectAtIndex:0];
	if (caseName == [NSNull null]) {
		return nil;
	}
	
	return [workspace caseWithName:caseName];
}

- (id)selectedCaseItem {
	
	NSArray* caseFolderAndName = [self selectedCaseFolderAndName];
	
	id caseName = [caseFolderAndName objectAtIndex:0];
	id folderName = [caseFolderAndName objectAtIndex:1];
	id dataName = [caseFolderAndName objectAtIndex:2];
	if (caseName == [NSNull null] or folderName == [NSNull null] or dataName == [NSNull null]) {
		return nil;
	}
	
	return [[workspace caseWithName:caseName] dataForName:dataName folder:folderName];
}

- (void)sceneBrowserSelectionHasChanged:(NSNotification*)notification {
	NSDictionary* userInfo = [notification userInfo];
	id item = [userInfo objectForKey:@"Item"];
	if ([item isKindOfClass:[BJDataDisplay class]] == NO) {
		return;
	}
	NSString* caseName = [[workspace caseForDataWithUniqueIdentifier:[item dataUniqueIdentifier]] name];
	NSString* folder = [[item dataObject] folder];
	NSString* path = [NSString stringWithFormat:@"/%@/%@",caseName,[item dataName]];
	if ([folder isEqualToString:@""] == NO) {
		path = [NSString stringWithFormat:@"/%@/%@/%@",caseName,folder,[item dataName]];
	}

	[caseBrowserView setPath:path];
	[self browserPathChanged:path];
}

- (void)browserPathChanged:(NSString*)path {
	NSArray* selectedCaseFolderAndName = [self selectedCaseFolderAndName];
	if (selectedCaseFolderAndName != nil) {
		NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:path,@"Path",[selectedCaseFolderAndName objectAtIndex:0],@"CaseName",[selectedCaseFolderAndName objectAtIndex:1],@"Folder",[selectedCaseFolderAndName objectAtIndex:2],@"DataName",nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldShowInfoForCase" object:self userInfo:userInfo];
	}
}

- (IBAction)browserClicked:(id)browser {
	[self browserPathChanged:[browser path]];
}

- (void)caseHasBeenAdded:(NSNotification*)notification {
	NSDictionary* userInfo = [notification userInfo];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(caseDataHasChanged:) name:@"CaseDataChanged" object:[userInfo objectForKey:@"Case"]];
	[self reloadBrowser];
}

- (void)caseHasBeenRemoved:(NSNotification*)notification {
	NSDictionary* userInfo = [notification userInfo];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"CaseDataChanged" object:[userInfo objectForKey:@"Case"]];
	[self reloadBrowser];
}

- (void)caseDataHasChanged:(NSNotification*)notification {
	[self reloadBrowser];
}

- (void)reloadBrowser {
	NSString *path = [caseBrowserView path];
    [caseBrowserView loadColumnZero];
    [caseBrowserView setPath:path];
}

- (void)browser:(NSBrowser *)sender createRowsForColumn:(NSInteger)column inMatrix:(NSMatrix*)matrix {

	if (column == 0) {
		for (id caseName in [workspace sortedCaseNames]) {
			NSBrowserCell* cell = [[NSBrowserCell alloc] init];
			[cell setStringValue:caseName];
			[cell setRepresentedObject:[workspace caseWithName:caseName]];
			NSImage* folderImage = [NSImage imageNamed:NSImageNameFolder];
			[folderImage setSize:NSMakeSize(16.0,16.0)];
			[cell setImage:folderImage];
			if (smallFont == YES) {
				[cell setFont:[NSFont controlContentFontOfSize:11.0]];
			}
			[matrix addRowWithCells:[NSArray arrayWithObject:cell]];
		}
		return;
	}

	NSString* path = [sender pathToColumn:column];		
	NSArray* fullSplitPath = [path componentsSeparatedByString:@"/"];
	NSArray* splitPath = [fullSplitPath subarrayWithRange:NSMakeRange(1,[fullSplitPath count]-1)];
	NSUInteger pathCount = [splitPath count];
	
	if (column > pathCount) {
		return;
	}

	id theCase = [workspace caseWithName:[splitPath objectAtIndex:0]];
	NSArray* folderComponents = [splitPath subarrayWithRange:NSMakeRange(1,column-1)];
	
	NSString* folder = [theCase joinFolderComponents:folderComponents];
	NSArray* folderContents = [theCase listedContentsOfFolder:folder];

	for (id content in folderContents) {
		
		NSArray* contentComponents = [content componentsSeparatedByString:@"/"];
		NSArray* contentComponentsButLast = [contentComponents subarrayWithRange:NSMakeRange(0,[contentComponents count]-1)];
		NSString* lastContentComponent = [contentComponents objectAtIndex:[contentComponents count]-1];
		
		id theData = [theCase dataForName:lastContentComponent folder:[theCase joinFolderComponents:contentComponentsButLast]];
		
		NSBrowserCell* cell = [[NSBrowserCell alloc] init];

		[cell setStringValue:lastContentComponent];
		[cell setRepresentedObject:theCase];
		
		if (theData != nil) {
			[cell setRepresentedObject:theData];
			[cell setLeaf:YES];
			NSImage* documentImage = [NSImage imageNamed:@"NSMysteryDocument.tiff"];
			[documentImage setSize:NSMakeSize(16.0,16.0)];
			[cell setImage:documentImage];
		}
		else {
			NSImage* folderImage = [NSImage imageNamed:NSImageNameFolder];
			[folderImage setSize:NSMakeSize(16.0,16.0)];
			[cell setImage:folderImage];
		}
		if (smallFont == YES) {
			[cell setFont:[NSFont controlContentFontOfSize:11.0]];
		}
		[matrix addRowWithCells:[NSArray arrayWithObject:cell]];
	}
}

- (NSArray*)selectedCaseFolderAndName {
	return [workspace caseFolderAndNameFromPath:[caseBrowserView path]];
}

- (BOOL)browser:(NSBrowser *)browser canDragRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)column withEvent:(NSEvent *)event {
	return YES;
}

- (BOOL)browser:(NSBrowser *)browser writeRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)column toPasteboard:(NSPasteboard *)pasteboard {

	id cell = [browser loadedCellAtRow:[rowIndexes firstIndex] column:column];
	id item = [cell representedObject];

	NSString* stringForPasteboard = nil;
	if ([item isKindOfClass:[BJCase class]] == YES) {
		stringForPasteboard = [NSString stringWithFormat:@"%@\t%@",[item className],[NSString stringWithFormat:@"%@/%@",[browser pathToColumn:column],[cell stringValue]]];		
	}
	else if ([item isKindOfClass:[BJData class]] == YES) {
		stringForPasteboard = [NSString stringWithFormat:@"%@\t%@",[item className],[item uniqueIdentifier]];
	}
	else {
		stringForPasteboard = [NSString string];
	}

	[pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[pasteboard setPropertyList:stringForPasteboard forType:NSStringPboardType];

	return YES;	
}

@end
