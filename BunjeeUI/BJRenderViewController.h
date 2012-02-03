//
//  BJRenderingPanelController.h
//  Bunjee
//
//  Created by Luca Antiga on 5/10/11.
//  Copyright 2011 Orobix Srl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BJSceneViewPanelController;
@class BJWorkspace;
@class BJScene;

@interface BJRenderView : NSView {
}

@end

@interface BJRenderViewController : NSViewController {
	NSMutableArray* sceneViewPanelControllers;
	
	IBOutlet NSSegmentedControl *toolSelector;
	IBOutlet NSSegmentedControl *imageToolSelector;
	IBOutlet NSPopUpButton* layoutButton;
	IBOutlet NSView* sceneViewPanelContainer;

	NSUInteger nRows;
	NSUInteger nColumns;
	
	NSArray* layoutNames;
	NSString* activeLayoutName;
	NSString* activeArrangementName;

	BJWorkspace* workspace;

	NSInteger toolId;
	NSInteger lastNonModifierToolId;
	BOOL anyModifierDown;
	BOOL toolsEnabled;
	
	NSMutableDictionary* invocations;
}

@property(readwrite,retain) BJWorkspace* workspace;
@property(readonly) NSMutableArray* sceneViewPanelControllers;

@property(readwrite) NSInteger toolId;
@property(readwrite) BOOL toolsEnabled;
@property(readwrite,copy) NSArray* layoutNames;
@property(readwrite,copy) NSString* activeLayoutName;
@property(readwrite,copy) NSString* activeArrangementName;
@property(readonly) NSMutableDictionary* invocations;

- (BOOL)seedingEnabled;

- (void)addInvocation:(NSInvocation*)theInvocation forSignal:(NSString*)theSignal;
- (void)removeInvocation:(NSInvocation*)theInvocation forSignal:(NSString*)theSignal;

- (void)addInvocationsToScenePanelControllers;
- (void)removeInvocationsFromScenePanelControllers;

- (void)removeAllInvocations;

- (void)setUpSceneViewsWithRows:(NSUInteger)rows columns:(NSUInteger)columns;

- (void)updateSeedingToolStatus;
- (void)updateSceneViewsActiveStatus;

- (id)newSceneViewPanelController;

- (void)resetCameras;
- (void)resetCamerasForScene:(BJScene*)theScene;

- (void)synchronizeAll;
- (void)desynchronizeAll;

- (void)invalidateCameras;

- (void)setParallelProjectionEnabled:(BOOL)enabled;
- (void)setParallelProjectionEnabled:(BOOL)enabled forScene:(BJScene*)theScene;

- (void)setScene:(BJScene*)theScene atRow:(NSUInteger)row column:(NSUInteger)column;
- (id)sceneAtRow:(NSUInteger)row column:(NSUInteger)column;

- (BOOL)isSceneInAnyPanel:(BJScene*)theScene;
- (BOOL)isSceneInAnyPanelByName:(NSString*)theSceneName;

- (IBAction)changeLayout:(id)sender;

- (void)applyArrangement:(NSDictionary*)theArrangement;

@end
