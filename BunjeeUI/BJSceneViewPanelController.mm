//
//  BJSceneControlller.mm
//  Bunjee
//  Created by Luca Antiga on 3/6/09.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import "BJSceneViewPanelController.h"
#import "BJCaseBrowserController.h"
#import "Bunjee/BJWorkspace.h"
#import "BJSceneViewPanel.h"
#import "Bunjee/BJScene.h"
#import "Bunjee/VTKSceneView.h"

@implementation BJSceneViewPanelController

@synthesize synchronized;
//@synthesize scene;
@synthesize sceneView;
@synthesize sceneViewPanel;
@synthesize workspace;
@synthesize show3D;
@synthesize syncCamera;

- (id)init {
	self = [self initWithNibName:@"SceneView" bundle:[NSBundle bundleWithIdentifier:@"orobix.BunjeeUI"]];
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		scene = nil;
		workspace = nil;
		sceneName = nil;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataDisplayStatusHasChanged:) name:@"SceneDataDisplayStatusChanged" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sceneHasBeenAdded:) name:@"SceneHasBeenAdded" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sceneHasBeenRemoved:) name:@"SceneHasBeenRemoved" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sceneIsBeingRemoved:) name:@"SceneIsBeingRemoved" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(seedingStatusShouldChange:) name:@"SeedingStatusShouldChange" object:nil];
		[self setMipEnabled:NO];
		[self setSynchronized:YES];
		[self setShow3D:YES];
		[self setSyncCamera:NO];
	}
	return self;
}

- (void)finalize {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"SceneDataDisplayStatusChanged" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"SceneViewPanelSelected" object:[self view]];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"SliceViewAllowedChanged" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"SeedingStatusShouldChange" object:nil];

	[self setSynchronized:NO];
	[self setSyncCamera:NO];
	[super finalize];
}

- (void)awakeFromNib {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sceneViewPanelWasSelected:)
												 name:@"SceneViewPanelSelected" object:sceneViewPanel];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sliceViewAllowedHasChanged:)
												 name:@"SliceViewAllowedChanged" object:sceneView];
	
	[sceneViewPanel setDelegate:self];
	[self updateSceneChoice];
}

- (void)setWorkspace:(BJWorkspace*)theWorkspace {
	workspace = theWorkspace;
	[self updateSceneChoice];
}

- (void)seedingStatusShouldChange:(NSNotification *)notification {
	NSDictionary* userInfo = [notification userInfo];
	[self setSeedingEnabled:[[userInfo objectForKey:@"SeedingStatus"] boolValue]];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SeedingStatusChanged" object:self userInfo:userInfo];
}

- (void)setScene:(BJScene*)theScene {
	if (scene == theScene) {
		return;
	}
	scene = theScene;
	sceneName = [scene name];
	[sceneView setScene:scene];
	[self displayScene];
	
	[self disableSliceSlider];
	if ([sceneView sliceViewAllowed]) {
		[sliceSelector setEnabled:YES];
		[sliceSelector setSelectedSegment:0];
	}
	else {
		[self disableSliceSelector];
	}
	
	[sceneChoiceButton selectItemWithTitle:sceneName];
}

- (BJScene*)scene {
	return scene;
}

- (NSString*)sceneName {
	return sceneName;
}

- (void)addInvocation:(NSInvocation*)theInvocation forSignal:(NSString*)theSignal {
	[sceneView addInvocation:theInvocation forSignal:theSignal];
}

- (void)removeInvocation:(NSInvocation*)theInvocation forSignal:(NSString*)theSignal {
	[sceneView removeInvocation:theInvocation forSignal:theSignal];
}

- (void)updateSceneChoice {
	[sceneChoiceButton removeAllItems];
    [sceneChoiceButton addItemsWithTitles:[[NSArray arrayWithObject:@"No scene"] arrayByAddingObjectsFromArray:[workspace sceneNames]]];
	[sceneChoiceButton selectItemAtIndex:0];
	if (sceneName and [sceneName isEqualToString:@""] == NO and [[sceneChoiceButton titleOfSelectedItem] isEqualToString:sceneName] == NO) {
		[sceneChoiceButton selectItemWithTitle:sceneName];
	}
}

- (void)sceneHasBeenAdded:(NSNotification*)notification {
	[self updateSceneChoice];
}

- (void)sceneHasBeenRemoved:(NSNotification*)notification {
	[self updateSceneChoice];
}

- (void)sceneIsBeingRemoved:(NSNotification*)notification {
	if ([[notification userInfo] objectForKey:@"Scene"] == scene) {
		[self setScene:nil];
	}
}

- (IBAction)selectScene:(id)sender {
	NSString* newSceneName = [sceneChoiceButton titleOfSelectedItem];
	NSDictionary* userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:newSceneName, @"SceneName", sceneViewPanel, @"SceneViewPanel", self, @"SceneViewPanelController", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SceneAssociatedToSceneViewPanel" object:self userInfo:userInfo];
}

- (void)sceneViewPanelWasSelected:(NSNotification*)notification {
	[workspace setActiveSceneName:[scene name]];
}

- (void)dataDisplayStatusHasChanged:(NSNotification*)notification {
	if ([[notification userInfo] objectForKey:@"Scene"] != scene) {
		return;
	}
	[self displayScene];
}

- (void)sliceViewAllowedHasChanged:(NSNotification*)notification {
	if ([sceneView sliceViewAllowed]) {
		[sliceSelector setEnabled:YES];
	}
	else {
		[sliceSelector setSelectedSegment:0];
		[self disableSliceSelector];
		[self disableSliceSlider];
	}	
}

- (void)setSeedingEnabled:(BOOL)seedingEnabled {
	[sceneView setSeedingEnabled:seedingEnabled];
}

- (BOOL)seedingEnabled {
	return [sceneView seedingEnabled];
}

- (void)displayScene {
	[sceneView displayScene];
}

- (IBAction)changeSlice:(id)sender {
	[sceneView setSlice:[sender intValue]];
}

- (void)sliceHasChanged:(NSNotification*)notification {
	if ([notification object] == sceneView) {
		if ([sceneView viewAxis] != -1) {
			int sliceNumber = [sceneView getSlice];
			if ([sliceSlider intValue] != sliceNumber) {
				[sliceSlider setIntValue:sliceNumber];
			}
		}
		return;
	}
	NSDictionary* userInfo = [notification userInfo];
	if ([userInfo objectForKey:@"Scene"] != scene) {
		return;
	}
	int sliceNumberX = [[userInfo objectForKey:@"X"] intValue];
	int sliceNumberY = [[userInfo objectForKey:@"Y"] intValue];
	int sliceNumberZ = [[userInfo objectForKey:@"Z"] intValue];
	int notificationViewAxis = [[userInfo objectForKey:@"ViewAxis"] intValue];
	int notificationViewMode = [[userInfo objectForKey:@"ViewMode"] intValue];
	if ([sceneView getSlice:0] != sliceNumberX and (notificationViewMode == 0 or notificationViewAxis == 0)) {
		[sceneView setSliceNoNotify:sliceNumberX forAxis:0];
		if ([sceneView viewAxis] == 0) {
			[sliceSlider setIntValue:sliceNumberX];
		}
	}
	if ([sceneView getSlice:1] != sliceNumberY and (notificationViewMode == 0 or notificationViewAxis == 1)) {
		[sceneView setSliceNoNotify:sliceNumberY forAxis:1];
		if ([sceneView viewAxis] == 1) {
			[sliceSlider setIntValue:sliceNumberY];
		}
	}
	if ([sceneView getSlice:2] != sliceNumberZ and (notificationViewMode == 0 or notificationViewAxis == 2)) {
		[sceneView setSliceNoNotify:sliceNumberZ forAxis:2];
		if ([sceneView viewAxis] == 2) {
			[sliceSlider setIntValue:sliceNumberZ];
		}
	}
}

- (void)windowLevelHasChanged:(NSNotification*)notification {
	if ([notification object] == sceneView) {
		return;
	}
	NSDictionary* userInfo = [notification userInfo];
	if ([userInfo objectForKey:@"Scene"] != scene) {
		return;
	}
	double window = [[userInfo objectForKey:@"Window"] doubleValue];
	double level = [[userInfo objectForKey:@"Level"] doubleValue];
	[sceneView setWindow:window level:level];
}

- (void)setViewTo3D {
	[self setViewTo3DWithAnimation:YES];
}

- (void)setViewTo3DWithAnimation:(BOOL)animation {
	BOOL backupAnimation = [sceneView cameraAnimation];
	[sceneView setCameraAnimation:animation];
	[sceneView setSceneMode];
	[sceneView setCameraAnimation:backupAnimation];
	[self disableSliceSlider];
	[sliceSelector setSelectedSegment:0];
}

- (void)setViewToSliceWithAxis:(int)axis {
	[self setViewToSliceWithAxis:axis withAnimation:YES];
}

- (void)setViewToSliceWithAxis:(int)axis withAnimation:(BOOL)animation {
	BOOL backupAnimation = [sceneView cameraAnimation];
	[sceneView setCameraAnimation:animation];
	[sceneView setSliceMode:axis];
	[sceneView setCameraAnimation:backupAnimation];
	[sliceSlider setEnabled:YES];
	[sliceSlider setMinValue: [sceneView getSliceMin:axis]];
	[sliceSlider setMaxValue: [sceneView getSliceMax:axis]];
	[sliceSlider setNumberOfTickMarks: [sceneView getNumberOfSlices:axis]];
	[sliceSlider setIntValue: [sceneView getSlice:axis]];	
	[sliceSelector setSelectedSegment:1+axis];
}

- (void)disableSliceSlider {
	[sliceSlider setEnabled:NO];
	[sliceSlider setMinValue:0.0];
	[sliceSlider setMaxValue:1.0];
	[sliceSlider setNumberOfTickMarks:2];
	[sliceSlider setIntValue:0];
}

- (void)disableSliceSelector {
	[sliceSelector setSelectedSegment:0]; 
	[sliceSelector setEnabled:NO];
}

- (IBAction)changeView:(id)sender {
	switch ([sender selectedSegment]) {
		case 0:
			[self setViewTo3D];
			break;
		case 1:
			[self setViewToSliceWithAxis:0];
			break;
		case 2:
			[self setViewToSliceWithAxis:1];
			break;
		case 3:
			[self setViewToSliceWithAxis:2];
			break;
		default:
			break;
	}
}

- (IBAction)resetCamera:(id)sender {
	[sceneView resetCamera];
}

- (void)invalidateCamera {
	[sceneView invalidateCamera];
}

- (IBAction)toggleMIP:(id)sender {
	if ([self mipEnabled]) {
		[self setMipEnabled:NO];
	}
	else {
		[self setMipEnabled:YES];
	}
}

- (IBAction)toggleParallelProjection:(id)sender {
	if ([self parallelProjectionEnabled] == YES) {
		[self setParallelProjectionEnabled:NO];
	}
	else {
		[self setParallelProjectionEnabled:YES];
	}

}

- (BOOL)parallelProjectionEnabled {
	return [sceneView parallelProjectionEnabled];
}

- (void)setParallelProjectionEnabled:(BOOL)enabled {
	[sceneView setParallelProjectionEnabled:enabled];
}

- (void)setMipEnabled:(BOOL)mip {
	[sceneView setMipEnabled:mip];
}

- (BOOL)mipEnabled {
	return [sceneView mipEnabled];
}

- (BOOL)inSceneViewMode {
	if ([sceneView viewMode] == 0) {
		return YES;
	}
	
	return NO;
}

- (void)copyCameraFromSceneViewPanelController:(BJSceneViewPanelController*)theSceneViewPanelController {
	[[self sceneView] copyCameraFromSceneView:[theSceneViewPanelController sceneView]];
}

- (void)setShow3D:(BOOL)show {
	[sceneView setShow3D:show];
}

- (BOOL)show3D {
	return [sceneView show3D];
}

- (IBAction)toggleSynchronized:(id)sender {
	if (synchronized) {
		[self setSynchronized:NO];
	}
	else {
		[self setSynchronized:YES];
	}
}

- (void)setSynchronized:(BOOL)sync {
	synchronized = sync;
	if (synchronized) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sliceHasChanged:) name:@"SliceChanged" object:nil];		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowLevelHasChanged:) name:@"WindowLevelChanged" object:nil];		
	}
	else {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"SliceChanged" object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"WindowLevelChanged" object:nil];		
	}
}

- (BOOL)synchronized {
	return synchronized;
}

- (void)setSyncCamera:(BOOL)sync {
	syncCamera = sync;
	[sceneView setSyncCamera:sync];
}

- (void)windowWillClose:(NSNotification *)notification {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SceneWindowWillCloseNotification" object:self];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {	
	NSPasteboard *pboard;
	NSDragOperation sourceDragMask;
	
	sourceDragMask = [sender draggingSourceOperationMask];
	pboard = [sender draggingPasteboard];
	
	if ([[pboard types] containsObject:NSStringPboardType]) {
		NSString* className = [[[pboard propertyListForType:NSStringPboardType] componentsSeparatedByString:@"\t"] objectAtIndex:0];
		if (not ([NSClassFromString(className) isSubclassOfClass:NSClassFromString(@"BJDataDisplay")] or
			[NSClassFromString(className) isSubclassOfClass:NSClassFromString(@"BJData")] or
			[NSClassFromString(className) isSubclassOfClass:NSClassFromString(@"BJScene")])) {
			return NSDragOperationNone;
		}
		if (sourceDragMask & NSDragOperationCopy) {
			return NSDragOperationCopy;
		}
	}
	return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	NSPasteboard *pboard;
	NSDragOperation sourceDragMask;
	
	sourceDragMask = [sender draggingSourceOperationMask];
	pboard = [sender draggingPasteboard];
	
	if ([[pboard types] containsObject:NSStringPboardType]) {
		NSArray* stringComponents = [[pboard propertyListForType:NSStringPboardType] componentsSeparatedByString:@"\t"];
		NSString* className = [stringComponents objectAtIndex:0];
		
		if ([NSClassFromString(className) isSubclassOfClass:NSClassFromString(@"BJDataDisplay")]) {
			NSString* dataUniqueIdentifier = [stringComponents objectAtIndex:1];
			NSString* newSceneName = [stringComponents objectAtIndex:2];
			NSDictionary* userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:newSceneName, @"SceneName", dataUniqueIdentifier, @"DataUniqueIdentifier", sceneViewPanel, @"SceneViewPanel", self, @"SceneViewPanelController", nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"DataDisplayDraggedInSceneViewPanel" object:self userInfo:userInfo];
		}
		else if ([NSClassFromString(className) isSubclassOfClass:NSClassFromString(@"BJData")]) {
			NSString* dataUniqueIdentifier = [stringComponents objectAtIndex:1];
			NSDictionary* userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:dataUniqueIdentifier, @"DataUniqueIdentifier", sceneViewPanel, @"SceneViewPanel", self, @"SceneViewPanelController", nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"DataDraggedInSceneViewPanel" object:self userInfo:userInfo];
		}
		else if ([NSClassFromString(className) isSubclassOfClass:NSClassFromString(@"BJScene")]) {
			NSString* newSceneName = [stringComponents objectAtIndex:1];
			[sceneChoiceButton selectItemWithTitle:newSceneName];
			NSDictionary* userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:newSceneName, @"SceneName", sceneViewPanel, @"SceneViewPanel", self, @"SceneViewPanelController", nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"SceneAssociatedToSceneViewPanel" object:self userInfo:userInfo];
		}		
	}
	
	return YES;
}

@end
