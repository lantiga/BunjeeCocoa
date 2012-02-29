//
//  BJCaseInfoController.m
//  Bunjee
//  Created by Luca Antiga on 8/17/09.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import "BJSceneBrowserController.h"
#import "Bunjee/BJWorkspaceController.h"
#import "Bunjee/BJWorkspace.h"
#import "Bunjee/BJScene.h"
#import "Bunjee/BJData.h"
#import "Bunjee/BJDataDisplay.h"

//#define SINGLE_LINE_OUTLINEVIEW

@implementation BJSceneBrowserView

//- (BOOL)becomeFirstResponder {
//	[[NSNotificationCenter defaultCenter] postNotificationName:@"SceneBrowserGainedFocus" object:self];
//	return YES;
//}
//
//- (BOOL)resignFirstResponder {
//	[[NSNotificationCenter defaultCenter] postNotificationName:@"SceneBrowserLostFocus" object:self];
//	return YES;
//}

@end 

@implementation BJSceneCell

@synthesize isGroupCell;

-(void)awakeFromNib
{
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
//	NSRect buttonFrame = cellFrame;
//	
//	buttonFrame.size.width = 20;
//	buttonFrame.origin.x += cellFrame.size.width - 20;
//	NSButton* button = [[NSButton alloc] init];
//	[[self controlView] addSubview:button];
//	
//	[button setFrame:buttonFrame];
//	
//	cellFrame.size.width -= 20;
//	[super drawWithFrame:cellFrame inView:controlView];

//	NSGradient* activeFillGradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:[NSColor colorWithCalibratedWhite:169.0 / 256.0  alpha:1.0],
//																		 [NSColor colorWithCalibratedWhite:200.0 / 256.0 alpha:1.0],nil]];
//
//	if (isGroupCell) {
//		[activeFillGradient drawInRect:cellFrame angle:270.0];
//	}

	[super drawWithFrame:cellFrame inView:controlView];
}

@end


@implementation BJSceneBrowserController

@synthesize workspace;
@synthesize workspaceController;
@synthesize sceneOutlineView;
@synthesize sceneFilterItems;
@synthesize dataTypeFilterItems;
@synthesize selectedSceneFilterIndex;
@synthesize selectedDataTypeFilterIndex;
@synthesize shouldSaveSceneAsTemplate;

- (id)init {
	self = [self initWithNibName:@"SceneBrowserView" bundle:[NSBundle bundleWithIdentifier:@"orobix.BunjeeUI"]];
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];	
	
	if (self) {
		workspace = nil;
		workspaceController = nil;
		
		sceneFilterItems = nil;
		dataTypeFilterItems = nil;
		
		selectedSceneFilterIndex = -1;
		selectedDataTypeFilterIndex = -1;
		shouldSaveSceneAsTemplate = NO;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sceneHasBeenAdded:) name:@"SceneHasBeenAdded" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sceneIsBeingRemoved:) name:@"SceneIsBeingRemoved" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sceneHasBeenRemoved:) name:@"SceneHasBeenRemoved" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(caseNameIsChanging:) name:@"CaseNameChanging" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activeSceneHasChanged:) name:@"ActiveSceneChanged" object:nil];
		[self setTitle:@"Scenes"];
	}
	
	return self;
}

- (void)finalize {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"SceneHasBeenAdded" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"SceneIsBeingRemoved" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"SceneHasBeenRemoved" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"SceneDataDisplayChanged" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"CaseNameChanging" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"ActiveSceneChanged" object:nil];
	[super finalize];
}

- (void)awakeFromNib {
	[sceneOutlineView setDataSource:self];
	[sceneOutlineView registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];
	[sceneOutlineView setDoubleAction:@selector(toggleDisplayed:)];
	[sceneOutlineView setTarget:self];
#ifdef SINGLE_LINE_OUTLINEVIEW
	[sceneOutlineView setRowHeight:20.0];
#else
	[sceneOutlineView setRowHeight:32.0];
#endif
	[self updateFilters];
}

- (void)setWorkspaceController:(BJWorkspaceController *) theWorkspaceController {
	workspaceController = theWorkspaceController;
	workspace = [workspaceController workspace];
}

- (IBAction)sceneFileAction:(id)sender {
	NSInteger selectedSegment = [sender selectedSegment];
    NSInteger clickedSegmentTag = [[sender cell] tagForSegment:selectedSegment];
	
    switch (clickedSegmentTag) {
		case 0: 
			[self newScene:nil]; 
			break;
		case 1: 
			[self openScene:nil]; 
			break;
		case 2: 
			[self saveScene:nil]; 
			break;
		case 3: 
			[self saveSceneAs:nil]; 
			break;
		case 4: 
			[self closeScene:nil]; 
			break;
    }
}

- (IBAction)newScene:(id)sender {
	[workspaceController newScene];
}

- (IBAction)openScene:(id)sender {
	[workspaceController openScene];
}

- (IBAction)saveScene:(id)sender {
	[workspaceController saveScene:[self selectedScene]];
}

- (IBAction)saveSceneAs:(id)sender {
	[workspaceController saveSceneAs:[self selectedScene]];
}

- (IBAction)closeScene:(id)sender {
	[workspaceController closeScene:[self selectedScene]];
}

- (IBAction)removeItemFromScene:(id)sender {
	[workspaceController removeItem:[self selectedSceneItem] fromScene:[self selectedScene]];
}

- (IBAction)removeAllItemsFromScene:(id)sender {
	[workspaceController removeAllItemsFromScene:[self selectedScene]];
}

- (id)selectedScene {
	NSInteger selectedRow = [sceneOutlineView selectedRow];
	
	if (selectedRow == -1) {
		return nil;
	}
	
	id item = [sceneOutlineView itemAtRow:selectedRow];
	
	if ([sceneOutlineView parentForItem:item] != nil) {
		return [sceneOutlineView parentForItem:item];
	}
	else {
		return item;		
	}
}

- (id)selectedSceneItem {
	NSInteger selectedRow = [sceneOutlineView selectedRow];
	
	if (selectedRow == -1) {
		return nil;
	}
	
	id item = [sceneOutlineView itemAtRow:selectedRow];
	
	if ([sceneOutlineView parentForItem:item] != nil) {
		return item;
	}
	else {
		return nil;		
	}		
}

- (IBAction)sceneFilterChanged:(id)sender {
	[sceneOutlineView reloadData];
	[sceneOutlineView expandItem:nil expandChildren:YES];
	NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:0];
	[sceneOutlineView selectRowIndexes:indexSet byExtendingSelection:NO];	
}

- (IBAction)dataTypeFilterChanged:(id)sender {
	[sceneOutlineView reloadData];
}

- (void)updateFilters {
	NSString* currentSceneFilterSelection = nil;
	if (selectedSceneFilterIndex > 0) {
		currentSceneFilterSelection = [sceneFilterItems objectAtIndex:selectedSceneFilterIndex];
	}
	
	NSString* currentDataTypeFilterSelection = nil;
	if (selectedDataTypeFilterIndex > 0) {
		currentDataTypeFilterSelection = [dataTypeFilterItems objectAtIndex:selectedDataTypeFilterIndex];
	}
	
	NSArray* sortedSceneNames = [workspace sortedSceneNames];
	[self setSceneFilterItems:[[NSArray arrayWithObject:@"All scenes"] arrayByAddingObjectsFromArray:sortedSceneNames]];	
	NSMutableSet* typeSet = [[NSMutableSet alloc] init];
	for (id sceneName in sortedSceneNames) {
		[typeSet unionSet:[NSSet setWithArray:[[workspace sceneWithName:sceneName] listedDataTypeNames]]];
	}
    [self setDataTypeFilterItems:[[NSArray arrayWithObject:@"All data types"] arrayByAddingObjectsFromArray:[typeSet allObjects]]];

	[sceneFilterButton removeAllItems];
	[sceneFilterButton addItemsWithTitles:sceneFilterItems];

	[dataTypeFilterButton removeAllItems];
	[dataTypeFilterButton addItemsWithTitles:dataTypeFilterItems];
	
	if (currentSceneFilterSelection != nil) {
		if ([sceneFilterItems containsObject:currentSceneFilterSelection] == YES) {
			[sceneFilterButton selectItemWithTitle:currentSceneFilterSelection];
		}
	}

	if (currentDataTypeFilterSelection != nil) {
		if ([dataTypeFilterItems containsObject:currentDataTypeFilterSelection] == YES) {
			[dataTypeFilterButton selectItemWithTitle:currentDataTypeFilterSelection];
		}
	}
}

- (IBAction)toggleDisplayed:(id)sender {
	NSInteger selectedRow = [sender clickedRow];
	id item = [sceneOutlineView itemAtRow:selectedRow];
	if ([item isKindOfClass:[BJDataDisplay class]] == NO) {
		return;
	}
	if ([item displayed] == YES) {
		[item setDisplayed:NO];
	}
	else {
		[item setDisplayed:YES];
	}
}

- (void)sceneHasBeenAdded:(NSNotification*)notification {
	NSDictionary* userInfo = [notification userInfo];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sceneDataHasChanged:) name:@"SceneDataDisplayChanged" object:[userInfo objectForKey:@"Scene"]];
	[self updateFilters];
	[sceneOutlineView reloadData];
	[sceneOutlineView expandItem:nil expandChildren:YES];
	if ([sceneOutlineView selectedRow] == -1) {
		NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:0];
		[sceneOutlineView selectRowIndexes:indexSet byExtendingSelection:NO];
	}
	[self outlineViewSelectionChangedAction:sceneOutlineView];
}

- (void)sceneIsBeingRemoved:(NSNotification*)notification {
	NSDictionary* userInfo = [notification userInfo];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"SceneDataDisplayChanged" object:[userInfo objectForKey:@"Scene"]];
}

- (void)sceneHasBeenRemoved:(NSNotification*)notification {
	[self updateFilters];
	if ([[workspace scenes] count] > 0) {
		[sceneOutlineView reloadData];
		[self outlineViewSelectionChangedAction:sceneOutlineView];
	}
	else {
		[sceneOutlineView reloadData];
		[self outlineViewSelectionChangedAction:sceneOutlineView];
	}
}

- (void)sceneDataHasChanged:(NSNotification*)notification {
	[self updateFilters];
	[sceneOutlineView reloadData];
	[self outlineViewSelectionChangedAction:sceneOutlineView];
}

- (void)caseNameIsChanging:(NSNotification*)notification {
	[sceneOutlineView reloadData];
}

- (void)activeSceneHasChanged:(NSNotification*)notification {
	BJScene* scene = [[notification userInfo] objectForKey:@"Scene"];

	if (scene == nil) {
		return;
	}
	
	if (selectedSceneFilterIndex > 0) {
		if ([[sceneFilterItems objectAtIndex:selectedSceneFilterIndex] isEqualToString:[scene name]] == NO) {
			[self setSelectedSceneFilterIndex:[sceneFilterItems indexOfObject:[scene name]]];
			[sceneOutlineView reloadData];
			[sceneOutlineView expandItem:nil expandChildren:YES];
			NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:0];
			[sceneOutlineView selectRowIndexes:indexSet byExtendingSelection:NO];
			return;
		}
	}
	
	NSInteger selectedRow = [sceneOutlineView selectedRow];
	if (selectedRow != -1) {
		BJScene* currentScene = nil;
		id item = [sceneOutlineView itemAtRow:selectedRow];
		if ([item isKindOfClass:[BJScene class]]) {
			currentScene = item;
		}
		else {
			currentScene = [sceneOutlineView parentForItem:item];
		}
		if (scene == currentScene) {
			return;
		}
	}

	NSInteger index = [sceneOutlineView rowForItem:scene];
	if (index == -1) {
		return;
	}

	NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:index];
	[sceneOutlineView selectRowIndexes:indexSet byExtendingSelection:NO];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	if (item == nil) {
		if ([[workspace scenes] count] == 0) {
			return nil;
		}
		if (selectedSceneFilterIndex > 0) {
			return [[workspace scenes] objectForKey:[sceneFilterItems objectAtIndex:selectedSceneFilterIndex]];
		}
		NSString* sceneName = [[workspace sortedSceneNames] objectAtIndex:index];
		return [workspace sceneWithName:sceneName];
	}
	else if ([item isKindOfClass:[BJScene class]]) {
		if (selectedDataTypeFilterIndex > 0) {
			id key = [item listedKeyWithIndex:index withType:[dataTypeFilterItems objectAtIndex:selectedDataTypeFilterIndex]];
			return [[item dataDisplayDictionary] objectForKey:key];
		}
		id key = [item listedKeyWithIndex:index];
		return [[item dataDisplayDictionary] objectForKey:key];
	}
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	if (item == nil) {
		return YES;
	}
	else if ([item isKindOfClass:[BJScene class]]) {
		return YES;
	}
	return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	if (item == nil) {
		if (selectedSceneFilterIndex > 0) {
			return 1;
		}
		return [[workspace scenes] count];
	}
	else if ([item isKindOfClass:[BJScene class]]) {
		if (selectedDataTypeFilterIndex > 0) {
			return [item numberOfListedKeysWithType:[dataTypeFilterItems objectAtIndex:selectedDataTypeFilterIndex]];
		}
		return [item numberOfListedKeys];
	}
	return 0;
}
#ifdef SINGLE_LINE_OUTLINEVIEW
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	if ([item isKindOfClass:[BJScene class]]) {
		return [item name];
	}
	else if ([item isKindOfClass:[BJDataDisplay class]]) {
		NSString* name = [item name];
		NSString* caseName = [[workspace caseForDataWithUniqueIdentifier:[item dataUniqueIdentifier]] name];
		NSString* value = [NSString stringWithFormat:@"%@",name];
		if (caseName == nil) {
			value = [NSString stringWithFormat:@"%@ (not loaded)",name];
		}
		return value;
	}
	return nil;
}
#else
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	if ([item isKindOfClass:[BJScene class]]) {
		return [item name];
	}
	else if ([item isKindOfClass:[BJDataDisplay class]]) {
		NSString* name = [item name];
		NSString* dataCode = [item dataCode];
		NSString* location;
		NSString* caseName = [[workspace caseForDataWithUniqueIdentifier:[item dataUniqueIdentifier]] name];
		if (caseName == nil) {
			location = @"Data not found";
		}
		else {
			NSString* folder = [[item dataObject] folder];
			if ([folder isEqualToString:@""] == YES) {
				location = [NSString stringWithFormat:@"%@/%@",caseName,[item dataName]];
			}
			else {
				location = [NSString stringWithFormat:@"%@/%@/%@",caseName,folder,[item dataName]];
			}
		}
		NSString* value = [NSString stringWithFormat:@"[%@] %@\n%@",dataCode,name,location];
		return value;
	}
	return nil;
}
#endif
- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
	if ([items count] != 1) {
		return NO;
	}
	id item = [items objectAtIndex:0];
	NSString* stringForPasteboard = nil;
	if ([item isKindOfClass:[BJScene class]] == YES) {
		stringForPasteboard = [NSString stringWithFormat:@"%@\t%@",[item className],[item name]];
	}
	else {
		id scene = [outlineView parentForItem:item];
		stringForPasteboard = [NSString stringWithFormat:@"%@\t%@\t%@\t%@",[item className],[item dataUniqueIdentifier],[scene name],[item name]];
	}
	[pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[pboard setPropertyList:stringForPasteboard forType:NSStringPboardType];
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)sender isGroupItem:(id)item {
	if ([item isKindOfClass:[BJScene class]] == YES) {
		return YES;
	}
	return NO;
}

#ifdef SINGLE_LINE_OUTLINEVIEW
- (void)outlineView:(NSOutlineView *)sender willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {	
	if ([item isKindOfClass:[BJScene class]] == YES) {
		NSMutableAttributedString *newTitle = [[cell attributedStringValue] mutableCopy];		
		[cell setAttributedStringValue:newTitle];
		[cell setIsGroupCell:YES];
	}
	else {
		NSMutableAttributedString *newTitle = [[cell attributedStringValue] mutableCopy];
		NSString* titleRange = [newTitle string];
		NSRange firstRange = [titleRange lineRangeForRange:NSMakeRange(0,1)];

		if ([item displayed] == YES) {
			if ([sceneOutlineView isRowSelected:[sceneOutlineView rowForItem:item]] == NO) {
				[newTitle addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:firstRange];
			}
			else {
				[newTitle addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:firstRange];
			}
		}
		else {
			if ([sceneOutlineView isRowSelected:[sceneOutlineView rowForItem:item]] == NO) {
				[newTitle addAttribute:NSForegroundColorAttributeName value:[NSColor darkGrayColor] range:firstRange];
			}
			else {
				[newTitle addAttribute:NSForegroundColorAttributeName value:[NSColor lightGrayColor] range:firstRange];
			}
		}
		
		NSImage* documentImage = [NSImage imageNamed:@"NSMysteryDocument.tiff"];
		[documentImage setSize:NSMakeSize(10.0,10.0)];
		NSTextAttachmentCell* attachmentCell = [[NSTextAttachmentCell alloc] initImageCell:documentImage];

		NSTextAttachment* attachment = [[NSTextAttachment alloc] init];
		[attachment setAttachmentCell:attachmentCell];

		NSAttributedString* titleWithAttachment = [NSAttributedString attributedStringWithAttachment:attachment];
		NSMutableAttributedString* completeTitle = [[NSMutableAttributedString alloc] initWithAttributedString:titleWithAttachment];
		[completeTitle appendAttributedString:newTitle];

		[cell setAttributedStringValue:completeTitle];
		[cell setIsGroupCell:NO];
	}
}
#else
- (void)outlineView:(NSOutlineView *)sender willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {	
	if ([item isKindOfClass:[BJScene class]] == YES) {
		NSMutableAttributedString *newTitle = [[cell attributedStringValue] mutableCopy];		
		[cell setAttributedStringValue:newTitle];
		[cell setIsGroupCell:YES];
	}
	else {
		NSMutableAttributedString *newTitle = [[cell attributedStringValue] mutableCopy];
		NSString* titleRange = [newTitle string];
		NSRange firstRange = [titleRange lineRangeForRange:NSMakeRange(0,1)];
		NSRange secondRange = [titleRange lineRangeForRange:NSMakeRange([titleRange length]-2,1)];
		[newTitle addAttribute:NSFontAttributeName value:[NSFont fontWithName: @"LucidaGrande" size: 10.0f] range:secondRange];		
		if ([item displayed] == YES) {
			if ([sceneOutlineView isRowSelected:[sceneOutlineView rowForItem:item]] == NO) {
				[newTitle addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:firstRange];
				[newTitle addAttribute:NSForegroundColorAttributeName value:[NSColor darkGrayColor] range:secondRange];
			}
			else {
				[newTitle addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:firstRange];
				[newTitle addAttribute:NSForegroundColorAttributeName value:[NSColor lightGrayColor] range:secondRange];
			}
		}
		else {
			if ([sceneOutlineView isRowSelected:[sceneOutlineView rowForItem:item]] == NO) {
				[newTitle addAttribute:NSForegroundColorAttributeName value:[NSColor darkGrayColor] range:firstRange];
				[newTitle addAttribute:NSForegroundColorAttributeName value:[NSColor darkGrayColor] range:secondRange];
			}
			else {
				[newTitle addAttribute:NSForegroundColorAttributeName value:[NSColor lightGrayColor] range:firstRange];
				[newTitle addAttribute:NSForegroundColorAttributeName value:[NSColor lightGrayColor] range:secondRange];
			}
		}
		[cell setAttributedStringValue:newTitle];
		[cell setIsGroupCell:NO];
	}
}
#endif

- (void)outlineViewSelectionChangedAction:(id)outlineView {
	NSInteger selectedRow = [outlineView selectedRow];
	
	if (selectedRow == -1) {
		id userInfo = [NSDictionary dictionary];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SceneBrowserSelectionChanged" object:self userInfo:userInfo];
		return;
	}
	
	id item = [outlineView itemAtRow:selectedRow];

	if (item == nil) {
		id userInfo = [NSDictionary dictionary];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SceneBrowserSelectionChanged" object:self userInfo:userInfo];
		return;
	}
	
	BJScene* scene = nil;
	if ([item isKindOfClass:[BJScene class]]) {
		scene = item;
	}
	else {
		scene = [outlineView parentForItem:item];
	}

	[workspace setActiveSceneName:[scene name]];

	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:item forKey:@"Item"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SceneBrowserSelectionChanged" object:self userInfo:userInfo];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	id outlineView = [notification object];
	[self outlineViewSelectionChangedAction:outlineView];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	if ([item isKindOfClass:[BJScene class]]) {
		return YES;
	}
	return NO;
}

- (void)outlineView:(NSOutlineView *)sender setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item  {
	//TODO: check to avoid replication
	NSLog(@"TODO: check to avoid replication during renaming");
	if ([item isKindOfClass:[BJScene class]]) {
		BJScene* scene = item;
		[[workspace scenes] removeObjectForKey:[scene name]];
		[scene setName:object];
		[[workspace scenes] setObject:scene forKey:[scene name]];
	}
	else if ([item isKindOfClass:[BJDataDisplay class]]) {
		[(BJDataDisplay*)item setName:object];
	}
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
	NSPasteboard *pboard;
	NSDragOperation sourceDragMask;
		
	sourceDragMask = [info draggingSourceOperationMask];
	pboard = [info draggingPasteboard];
	
	if (item != nil and [item isKindOfClass:[BJScene class]] == NO) {
		return NSDragOperationNone;	
	}
	
	if ([[pboard types] containsObject:NSStringPboardType]) {
		NSString* className = [[[pboard propertyListForType:NSStringPboardType] componentsSeparatedByString:@"\t"] objectAtIndex:0];
		if (not ([NSClassFromString(className) isSubclassOfClass:NSClassFromString(@"BJDataDisplay")] or
				 [NSClassFromString(className) isSubclassOfClass:NSClassFromString(@"BJData")] or
				 [NSClassFromString(className) isSubclassOfClass:NSClassFromString(@"BJCase")])) {
			return NSDragOperationNone;
		}
		if (sourceDragMask & NSDragOperationCopy) {
			[outlineView setDropItem:item dropChildIndex:-1];
			return NSDragOperationCopy;
		}
	}
	return NSDragOperationNone;	
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index {
	NSPasteboard *pboard;
	NSDragOperation sourceDragMask;
	
	sourceDragMask = [info draggingSourceOperationMask];
	pboard = [info draggingPasteboard];
	
	if ([[pboard types] containsObject:NSStringPboardType]) {
		NSArray* stringComponents = [[pboard propertyListForType:NSStringPboardType] componentsSeparatedByString:@"\t"];
		NSString* className = [stringComponents objectAtIndex:0];

		if ([NSClassFromString(className) isSubclassOfClass:NSClassFromString(@"BJDataDisplay")]) {
			NSString* dataUniqueIdentifier = [stringComponents objectAtIndex:1];

			if ([item isKindOfClass:[BJScene class]] == NO) {
				return NO;
			}
			
			BJScene* scene = item;
			BJData* theData = [workspace dataForUniqueIdentifier:dataUniqueIdentifier];
			id theKey = [theData uniqueIdentifier];
			
			id dataDisplayObject = [theData createDisplayObject];
			[scene setDataDisplay:dataDisplayObject forKey:theKey];
			[scene setDataDisplayed:YES forKey:theKey];
			
		}
		else if ([NSClassFromString(className) isSubclassOfClass:NSClassFromString(@"BJData")]) {
			NSString* dataUniqueIdentifier = [stringComponents objectAtIndex:1];

			if ([item isKindOfClass:[BJScene class]] == NO) {
				return NO;
			}
			
			BJScene* scene = item;
			BJData* theData = [workspace dataForUniqueIdentifier:dataUniqueIdentifier];
			id theKey = [theData uniqueIdentifier];
			id dataDisplayObject = [theData createDisplayObject];
			[scene setDataDisplay:dataDisplayObject forKey:theKey];
			[scene setDataDisplayed:YES forKey:theKey];
		}
		else if ([NSClassFromString(className) isSubclassOfClass:NSClassFromString(@"BJCase")]) {
			NSString* path = [stringComponents objectAtIndex:1];
			NSArray* caseFolderAndName = [workspace caseFolderAndNameFromPath:path];
			NSString* sceneName = [workspace pathWithoutRoot:path];
			BJScene* theScene = [workspace sceneWithName:path];
			if (theScene != nil) {
				[theScene removeAllDataDisplay];
			}
			else {
				theScene = [workspace newSceneWithName:sceneName];
			}
			BJCase* theCase = [workspace caseWithName:[caseFolderAndName objectAtIndex:0]];
			id theFolder = [caseFolderAndName objectAtIndex:1];
			//TODO: use template mechanism here
			for (id theKey in [theCase allListedKeys]) {
				id theData = [theCase dataForKey:theKey];
				if (theFolder != [NSNull null]) {
					if ([[theData folder] isEqualToString:theFolder] == NO) {
						continue;
					}
				}
				id dataDisplayObject = [theData createDisplayObject];
				[theScene setDataDisplay:dataDisplayObject forKey:[theData uniqueIdentifier]];
				[theScene setDataDisplayed:YES forKey:[theData uniqueIdentifier]];
			}
		}
	}
	
	return YES;
}

@end
