//
//  BJController.h
//  Bunjee
//  Created by Luca Antiga on 3/6/09.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BJScene;
@class BJSceneViewPanel;
@class BJWorkspace;
@class VTKSceneView;

@interface BJSceneViewPanelController : NSViewController {
	IBOutlet BJSceneViewPanel *sceneViewPanel;
	IBOutlet VTKSceneView *sceneView;
	IBOutlet NSSegmentedControl *sliceSelector;
	IBOutlet NSSlider *sliceSlider;	
	IBOutlet NSButton *synchronizedButton;
	IBOutlet NSPopUpButton *sceneChoiceButton;
	BJScene *scene;
	NSString *sceneName;
	BJWorkspace *workspace;
	BOOL synchronized;
	BOOL syncCamera;
	BOOL show3D;
}

//@property(readwrite,retain) BJScene* scene;
@property(readonly) BJWorkspace* workspace;
@property(readwrite) BOOL synchronized;
@property(readonly) BOOL syncCamera;
@property(readwrite) BOOL mipEnabled;
@property(readwrite) BOOL show3D;
@property(readonly) BJSceneViewPanel* sceneViewPanel;
@property(readonly) VTKSceneView* sceneView;
@property(readonly) NSString* sceneName;

- (void)setWorkspace:(BJWorkspace*)theWorkspace;

- (void)setScene:(BJScene*)theScene;
- (BJScene*)scene;

- (void)setSyncCamera:(BOOL)sync;

- (void)updateSceneChoice;

- (IBAction)selectScene:(id)sender;

- (IBAction)changeSlice:(id)sender;
- (IBAction)changeView:(id)sender;

- (IBAction)resetCamera:(id)sender;
- (IBAction)toggleMIP:(id)sender;

- (IBAction)toggleParallelProjection:(id)sender;
- (BOOL)parallelProjectionEnabled;
- (void)setParallelProjectionEnabled:(BOOL)enabled;

- (IBAction)toggleSynchronized:(id)sender;
- (void)setSynchronized:(BOOL)sync;
- (BOOL)synchronized;
- (void)setMipEnabled:(BOOL)mip;
- (BOOL)mipEnabled;

- (void)invalidateCamera;

//- (void)initializeSceneView;
- (void)displayScene;
- (void)setViewTo3D;
- (void)setViewToSliceWithAxis:(int)axis;

- (BOOL)inSceneViewMode;

- (void)copyCameraFromSceneViewPanelController:(BJSceneViewPanelController*)theSceneViewPanelController;

- (void)setViewTo3DWithAnimation:(BOOL)animation;
- (void)setViewToSliceWithAxis:(int)axis withAnimation:(BOOL)animation;

- (void)disableSliceSlider;
- (void)disableSliceSelector;

- (void)sliceHasChanged:(NSNotification*)notification;
- (void)windowLevelHasChanged:(NSNotification*)notification;

- (BOOL)seedingEnabled;
- (void)setSeedingEnabled:(BOOL)seedingEnabled;

@end
