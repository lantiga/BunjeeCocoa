//
//  BJCaseInfoController.h
//  Bunjee
//  Created by Luca Antiga on 8/17/09.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BJWorkspace;
@class BJWorkspaceController;

@interface BJCaseBrowserController : NSViewController<NSBrowserDelegate> {
	IBOutlet NSBrowser* caseBrowserView;
	IBOutlet NSView* caseBrowserPanel;
	BJWorkspace* workspace;
	BJWorkspaceController* workspaceController;
	BOOL smallFont;
}

@property(readonly) BJWorkspace* workspace;
@property(readwrite,retain) BJWorkspaceController* workspaceController;
@property(readonly) NSBrowser* caseBrowserView;
@property(readonly) NSView* caseBrowserPanel;
@property(readonly) NSPathControl* pathControl;
@property(readwrite) BOOL smallFont;

- (IBAction)browserClicked:(id)browser;

- (void)caseDataHasChanged:(NSNotification*)notification;

- (NSArray*)selectedCaseFolderAndName;

- (void)browserPathChanged:(NSString*)path;

- (void)reloadBrowser;

- (IBAction)caseFileAction:(id)sender;

- (id)selectedCase;
- (id)selectedCaseItem;

- (IBAction)newCase:(id)sender;
- (IBAction)newCaseFromImage:(id)sender;
- (IBAction)addImageToCase:(id)sender;
- (IBAction)addSurfaceToCase:(id)sender;
- (IBAction)openCase:(id)sender;
- (IBAction)saveCase:(id)sender;
- (IBAction)saveCaseAs:(id)sender;
- (IBAction)closeCase:(id)sender;
- (IBAction)removeItemFromCase:(id)sender;
- (IBAction)removeAllItemsFromCase:(id)sender;
- (IBAction)openStudyInOsiriX:(id)sender;
- (IBAction)openCaseDB:(id)sender;

@end
