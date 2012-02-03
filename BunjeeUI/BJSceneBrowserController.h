//
//  BJCaseInfoController.h
//  Bunjee
//  Created by Luca Antiga on 8/17/09.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BJWorkspace;
@class BJWorkspaceController;

@interface BJSceneBrowserView : NSOutlineView {
}

@end

@interface BJSceneCell : NSTextFieldCell {
	BOOL isGroupCell;
}

@property(readwrite) BOOL isGroupCell;

@end

@interface BJSceneBrowserController : NSViewController {
	IBOutlet BJSceneBrowserView* sceneOutlineView;
	IBOutlet NSPopUpButton *sceneFilterButton;
	IBOutlet NSPopUpButton *dataTypeFilterButton;
	NSArray* sceneFilterItems;
	NSArray* dataTypeFilterItems;
	NSInteger selectedSceneFilterIndex;
	NSInteger selectedDataTypeFilterIndex;
	BOOL shouldSaveSceneAsTemplate;
	BJWorkspace* workspace;
	BJWorkspaceController* workspaceController;
}

@property(readonly) BJWorkspace* workspace;
@property(readwrite,retain) BJWorkspaceController* workspaceController;
@property(readonly) NSOutlineView* sceneOutlineView;
@property(readwrite,copy) NSArray* sceneFilterItems;
@property(readwrite,copy) NSArray* dataTypeFilterItems;
@property(readwrite) NSInteger selectedSceneFilterIndex;
@property(readwrite) NSInteger selectedDataTypeFilterIndex;
@property(readwrite) BOOL shouldSaveSceneAsTemplate;

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard;
- (BOOL)outlineView:(NSOutlineView *)sender isGroupItem:(id)item;
- (void)outlineView:(NSOutlineView *)sender willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item;

- (void)outlineViewSelectionChangedAction:(id)outlineView;

- (void)sceneDataHasChanged:(NSNotification*)notification;
- (void)outlineView:(NSOutlineView *)sender setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;

- (void)updateFilters;

- (IBAction)sceneFilterChanged:(id)sender;
- (IBAction)dataTypeFilterChanged:(id)sender;

- (IBAction)toggleDisplayed:(id)sender;

- (IBAction)sceneFileAction:(id)sender;

- (id)selectedSceneItem;
- (id)selectedScene;

- (IBAction)closeScene:(id)sender;
- (IBAction)saveSceneAs:(id)sender;
- (IBAction)saveScene:(id)sender;
- (IBAction)openScene:(id)sender;
- (IBAction)newScene:(id)sender;
- (IBAction)removeItemFromScene:(id)sender;
- (IBAction)removeAllItemsFromScene:(id)sender;


@end
