//
//  BJRenderViewController.mm
//  Bunjee
//
//  Created by Luca Antiga on 5/10/11.
//  Copyright 2011 Orobix Srl. All rights reserved.
//

#import "BJWorkspace.h"
#import "BJScene.h"
#import "BJData.h"
#import "BJDataDisplay.h"
#import "BJRenderViewController.h"
#import "BJSceneViewPanelController.h"
#import "VTKSceneView.h"

@implementation BJRenderView
//- (void)drawRect:(NSRect)rect {
//	[[NSColor colorWithCalibratedWhite:64.0 / 256.0  alpha:1.0] set];
//	NSRectFill(rect);
//}
- (BOOL)acceptsFirstResponder {
	return YES;
}

- (void)flagsChanged:(NSEvent *)theEvent {
	int modifier = 0;
	
	int shiftDown = ([theEvent modifierFlags] & NSShiftKeyMask) ? 1 : 0;
	int controlDown = ([theEvent modifierFlags] & NSControlKeyMask) ? 1 : 0;
	int commandDown = ([theEvent modifierFlags] & NSCommandKeyMask) ? 1 : 0;
	int optionDown = ([theEvent modifierFlags] & NSAlternateKeyMask) ? 1 : 0;
	
	if (optionDown) {
		modifier = 1;
	}
	else if (commandDown) {
		modifier = 2;		
	}
	else if (controlDown) {
		modifier = 3;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ActiveToolShouldChange" object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:modifier] forKey:@"Modifier"]];
	//	[super flagsChanged:theEvent];
}

- (void)drawRect:(NSRect)rect {
}

@end

@implementation BJRenderViewController

@synthesize workspace;
@synthesize sceneViewPanelControllers;
@synthesize toolId;
@synthesize toolsEnabled;
@synthesize layoutNames;
@synthesize activeLayoutName;
@synthesize activeArrangementName;
@synthesize invocations;

- (id)init {
	self = [self initWithNibName:@"RenderView" bundle:[NSBundle bundleWithIdentifier:@"com.orobix.BunjeeKit"]];
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		sceneViewPanelControllers = [[NSMutableArray alloc] init];
		layoutNames = [NSArray arrayWithObjects:@"1x1",@"1x2",@"2x1",@"2x2",nil];
		activeLayoutName = [NSString stringWithString:@"1x1"];
		nRows = 1;
		nColumns = 1;
				
		toolId = CH;
		lastNonModifierToolId = CH;
		toolsEnabled = NO;
		
		workspace = nil;
		
		invocations = [[NSMutableDictionary alloc] init];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sceneHasBeenAssociatedToSceneViewPanel:) name:@"SceneAssociatedToSceneViewPanel" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(seedingStatusHasChanged:) name:@"SeedingStatusChanged" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activeSceneHasChanged:) name:@"ActiveSceneChanged" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activeToolShouldChange:) name:@"ActiveToolShouldChange" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayDataHasBeenDraggedInSceneViewPanel:) name:@"DataDisplayDraggedInSceneViewPanel" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataHasBeenDraggedInSceneViewPanel:) name:@"DataDraggedInSceneViewPanel" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sceneTemplateHasBeenApplied:) name:@"SceneTemplateApplied" object:nil];
	}
	return self;
}

- (void)finalize {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"SceneAssociatedToSceneViewPanel" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"SeedingStatusChanged" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"ActiveSceneChanged" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"ActiveToolShouldChange" object:nil];	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"DataDisplayDraggedInSceneViewPanel" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"DataDraggedInSceneViewPanel" object:nil];
	[super finalize];
}

- (void)awakeFromNib {
	[self setUpSceneViewsWithRows:1 columns:1];
	[self updateSeedingToolStatus];
}

- (void)setWorkspace:(BJWorkspace *)theWorkspace {
	workspace = theWorkspace;
	for (id sceneViewPanelController in sceneViewPanelControllers) {
		[sceneViewPanelController setWorkspace:workspace];
	}
}

- (void)activeSceneHasChanged:(NSNotification *)notification {
	if ([workspace activeScene] == nil) {
		[self setToolsEnabled:NO];
		return;
	}

	[self setToolsEnabled:YES];
	[self updateSceneViewsActiveStatus];	
}

- (void)seedingStatusHasChanged:(NSNotification *)notification {
	[self updateSeedingToolStatus];
}

- (void)sceneTemplateHasBeenApplied:(NSNotification *)notification {
	return;
	NSDictionary* userInfo = [notification userInfo];
	
	NSString* sceneName = [userInfo objectForKey:@"SceneName"];

	for (id sceneViewPanelController in sceneViewPanelControllers) {
		if ([sceneViewPanelController scene] == nil) {
			continue;
		}
		if ([sceneName isEqualToString:[[sceneViewPanelController scene] name]] == NO) {
			continue;
		}
		//FIXME: doesn't work!
		NSLog(@"FIXME");
		[[sceneViewPanelController sceneView] displayScene];
	}
}

- (void)sceneHasBeenAssociatedToSceneViewPanel:(NSNotification *)notification {
	NSDictionary* userInfo = [notification userInfo];
	
	NSString* sceneName = [userInfo objectForKey:@"SceneName"];
	
	BJScene* scene = nil;
	if ([sceneName isEqualToString:@""] == NO) {
		scene = [[workspace scenes] objectForKey:sceneName];
		
		if (scene == nil) {
			return;
		}
	}
	
	[[userInfo objectForKey:@"SceneViewPanelController"] setScene:scene];
	
	[workspace setActiveSceneName:[scene name]];
}

- (void)activeToolShouldChange:(NSNotification*)notification {
	int modifier = [[[notification userInfo] objectForKey:@"Modifier"] intValue];
	int newToolId = toolId;
	if (modifier == 0) {
		//		if (toolId == SL || toolId == WL) {
		//			newToolId = CH;
		//		}
		//		else if (toolId == TR || toolId == ZM) {
		//			newToolId = RT;
		//		}
		newToolId = lastNonModifierToolId;
		anyModifierDown = NO;
	}
	else if (modifier == 1) {
		if (toolId == CH || toolId == WL) {
			newToolId = SL;
		}
		else if (toolId == RT || toolId == ZM || toolId == IPRT) {
			newToolId = TR;
		}
		anyModifierDown = YES;
	}
	else if (modifier == 2) {
		if (toolId == CH || toolId == SL) {
			newToolId = WL;
		}
		else if (toolId == TR || toolId == RT || toolId == IPRT) {
			newToolId = ZM;
		}
		anyModifierDown = YES;
	}
	else if (modifier == 3) {
//		if ((toolId == CH || toolId == SL || toolId == WL) && [self seedingEnabled]) {
		if ((toolId == CH || toolId == SL || toolId == WL)) {
			newToolId = SD;
		}
		else if (toolId == TR || toolId == RT || toolId == ZM) {
			newToolId = IPRT;			
		}
		anyModifierDown = YES;
	}
	[self setToolId:newToolId];
}

- (void)displayDataHasBeenDraggedInSceneViewPanel:(NSNotification *)notification {
	NSDictionary* userInfo = [notification userInfo];
	
	BJScene* scene = [[userInfo objectForKey:@"SceneViewPanelController"] scene];
	
	if (!scene) {
		scene = [[workspace scenes] objectForKey:[userInfo objectForKey:@"SceneName"]];
		
		[[userInfo objectForKey:@"SceneViewPanelController"] setScene:scene];
		
		[workspace setActiveSceneName:[scene name]];
	}
	
	NSString* dataUniqueIdentifier = [userInfo objectForKey:@"DataUniqueIdentifier"];
	
	BJData* theData = [workspace dataForUniqueIdentifier:dataUniqueIdentifier];
	id theKey = [theData uniqueIdentifier];
	
	id dataDisplayObject = [theData createDisplayObject];
	[scene setDataDisplay:dataDisplayObject forKey:theKey];
	[scene setDataDisplayed:YES forKey:theKey];
}

- (void)dataHasBeenDraggedInSceneViewPanel:(NSNotification *)notification {
	NSDictionary* userInfo = [notification userInfo];
	
	BJScene* scene = [[userInfo objectForKey:@"SceneViewPanelController"] scene];
	
	if (!scene) {
		return;
	}
	
	NSString* dataUniqueIdentifier = [userInfo objectForKey:@"DataUniqueIdentifier"];
	BJData* theData = [workspace dataForUniqueIdentifier:dataUniqueIdentifier];
	
	id theKey = [theData uniqueIdentifier];
	
	id dataDisplayObject = [theData createDisplayObject];
	[scene setDataDisplay:dataDisplayObject forKey:theKey];
	[scene setDataDisplayed:YES forKey:theKey];
}

- (IBAction)changeLayout:(id)sender {
	[self setActiveLayoutName:[layoutButton titleOfSelectedItem]];
}

- (void)setActiveLayoutName:(NSString *)name {
	if ([activeLayoutName isEqualToString:name]) {
		return;
	}
	activeLayoutName = name;
	if ([activeLayoutName isEqualToString:@"1x1"] == YES) {
		[self setUpSceneViewsWithRows:1 columns:1];
	}
	else if ([activeLayoutName isEqualToString:@"1x2"] == YES) {
		[self setUpSceneViewsWithRows:1 columns:2];
	}
	else if ([activeLayoutName isEqualToString:@"2x1"] == YES) {
		[self setUpSceneViewsWithRows:2 columns:1];
	}
	else if ([activeLayoutName isEqualToString:@"2x2"] == YES) {
		[self setUpSceneViewsWithRows:2 columns:2];
	}
	[layoutButton selectItemWithTitle:name];
}

- (id)newSceneViewPanelController {
	return [[BJSceneViewPanelController alloc] init];
}

- (void)addInvocationsToScenePanelControllers {
	for (id signal in invocations) {
		id invocationsForSignal = [invocations objectForKey:signal];
		for (id invocation in invocationsForSignal) {
			for (id sceneViewPanelController in sceneViewPanelControllers) {
				[sceneViewPanelController addInvocation:invocation forSignal:signal];
			}
		}
	}	
}

- (void)removeInvocationsFromScenePanelControllers {
	for (id signal in invocations) {
		id invocationsForSignal = [invocations objectForKey:signal];
		for (id invocation in invocationsForSignal) {
			for (id sceneViewPanelController in sceneViewPanelControllers) {
				[sceneViewPanelController removeInvocation:invocation forSignal:signal];
			}
		}
	}	
}

- (void)removeAllInvocations {
	[self removeInvocationsFromScenePanelControllers];
	[invocations removeAllObjects];
}

- (void)setUpSceneViewsWithRows:(NSUInteger)rows columns:(NSUInteger)columns {
	
	nRows = rows;
	nColumns = columns;
		
	NSUInteger numberOfViews = rows*columns;
	
	NSMutableArray* newSceneControllers = [[NSMutableArray alloc] init];
	NSMutableArray* sceneViewPanels = [[NSMutableArray alloc] init];
	
	id old3DSceneViewPanelController = nil;
	for (id sceneViewPanelController in sceneViewPanelControllers) {
		if ([sceneViewPanelController inSceneViewMode] == NO) {
			continue;
		}
		old3DSceneViewPanelController = sceneViewPanelController;
	}
	
	for (unsigned int i=0; i<numberOfViews; i++) {
		BJSceneViewPanelController* sceneViewPanelController = [self newSceneViewPanelController];
		[sceneViewPanelController setWorkspace:workspace];
		[newSceneControllers addObject:sceneViewPanelController];
		[sceneViewPanels addObject:[sceneViewPanelController view]];
	}
	
	NSRect renderViewFrame = [sceneViewPanelContainer frame];
	NSRect subviewFrame;
	subviewFrame.size.width = (renderViewFrame.size.width - 1*(columns - 1)) / columns;
	subviewFrame.size.height = (renderViewFrame.size.height - 0*(rows - 1)) / rows;
	for (unsigned int i=0; i<rows; i++) {
		for (unsigned int j=0; j<columns; j++) {
			NSUInteger viewIndex = i*columns + j;
			id sceneViewPanel = [sceneViewPanels objectAtIndex:viewIndex];
			NSPoint origin;
			origin.x = j * (subviewFrame.size.width + 0);
			origin.y = i * (subviewFrame.size.height + 0);
			subviewFrame.origin = origin;
			[sceneViewPanel setFrame:subviewFrame];
			[sceneViewPanel setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable|NSViewMaxYMargin|NSViewMaxXMargin|NSViewMinYMargin|NSViewMinXMargin];
		}
	}

	[self removeInvocationsFromScenePanelControllers];
	
	for (id sceneViewPanelController in sceneViewPanelControllers) {
		[[sceneViewPanelController view] removeFromSuperviewWithoutNeedingDisplay];
		// [[sceneViewPanelController view] removeFromSuperview];
	}
	[sceneViewPanelControllers removeAllObjects];
	
	[sceneViewPanelControllers addObjectsFromArray:newSceneControllers];	

	[self addInvocationsToScenePanelControllers];

	[sceneViewPanelContainer setSubviews:sceneViewPanels];

	if (old3DSceneViewPanelController) {
		for (id sceneViewPanelController in sceneViewPanelControllers) {
			[sceneViewPanelController copyCameraFromSceneViewPanelController:old3DSceneViewPanelController];
		}
	}
	
	//TODO: handle this properly. Store which scene eventually was on previously shown panels and bring that up if it still exists.	
	//	if ([scenes count] > 0) {
	//		for (id sceneViewPanelController in sceneViewPanelControllers) {
	//			[sceneViewPanelController setScene:[scenes objectAtIndex:0]];
	//		}
	//	}
	//	if ([sceneViewPanelControllers count] == 1) {
	//		id sceneViewPanelController = [sceneViewPanelControllers objectAtIndex:0];
	//		[sceneViewPanelController setSynchronized:NO];
	//		[sceneViewPanelController disableSynchronizedButton];
	//	}
}

- (void)updateSceneViewsActiveStatus {
	for (id sceneViewPanelController in sceneViewPanelControllers) {
		if ([sceneViewPanelController scene] == nil) {
			id sceneViewPanel = [sceneViewPanelController view];
			[sceneViewPanel setBackgroundToLight];
			[sceneViewPanel setNeedsDisplay:YES];
			continue;
		}
		if ([[[sceneViewPanelController scene] name] isEqualToString:[workspace activeSceneName]]) {
			id sceneViewPanel = [sceneViewPanelController view];
			[sceneViewPanel setBackgroundToDark];
			[sceneViewPanel setNeedsDisplay:YES];
		}
		else {
			id sceneViewPanel = [sceneViewPanelController view];
			[sceneViewPanel setBackgroundToLight];
			[sceneViewPanel setNeedsDisplay:YES];
		}
		//can we avoid this?
		[[sceneViewPanelController sceneView] displayScene];
	}
}

- (void)setToolsEnabled:(BOOL)enabled {
	toolsEnabled = enabled;
	[self updateSeedingToolStatus];
}

- (BOOL)seedingEnabled {
	BOOL seedingEnabled = NO;
	for (id sceneViewPanelController in sceneViewPanelControllers) {
		if ([workspace activeScene] and [sceneViewPanelController scene] and [[[sceneViewPanelController scene] name] isEqualToString:[workspace activeSceneName]] == YES) {
			if ([sceneViewPanelController seedingEnabled] == YES) {
				seedingEnabled = YES;
			}
		}
	}
	return seedingEnabled;
}

- (void)updateSeedingToolStatus {
	[imageToolSelector setEnabled:[self seedingEnabled] forSegment:3];	
}

- (void)setToolId:(NSInteger)theToolId {
	toolId = theToolId;
	if (anyModifierDown == NO) {
		lastNonModifierToolId = toolId;
	}
//	NSLog(@"Tool id %d",toolId);
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:toolId], @"ToolId", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ToolIdChanged" object:self userInfo:userInfo];
}

- (void)resetCameras {
	[self resetCamerasForScene:nil];
}

- (void)resetCamerasForScene:(BJScene*)theScene {
	for (id sceneViewPanelController in sceneViewPanelControllers) {
		if (theScene != nil && [sceneViewPanelController scene] != theScene) {
			continue;
		}
		[sceneViewPanelController resetCamera:self];
	}
}

- (void)setParallelProjectionEnabled:(BOOL)enabled {
	[self setParallelProjectionEnabled:enabled forScene:nil];
}

- (void)setParallelProjectionEnabled:(BOOL)enabled forScene:(BJScene*)theScene {
	for (id sceneViewPanelController in sceneViewPanelControllers) {
		if (theScene != nil && [sceneViewPanelController scene] != theScene) {
			continue;
		}
		[sceneViewPanelController setParallelProjectionEnabled:enabled];
	}
}

- (void)addInvocation:(NSInvocation*)theInvocation forSignal:(NSString*)theSignal {
	NSMutableSet* invocationsForSignal = [invocations objectForKey:theSignal];
	
	if (invocationsForSignal == nil) {
		invocationsForSignal = [[NSMutableSet alloc] init];
		[invocations setObject:invocationsForSignal forKey:theSignal];
	}
	
	[invocationsForSignal addObject:theInvocation];
	
	for (id sceneViewPanelController in sceneViewPanelControllers) {
		[sceneViewPanelController addInvocation:theInvocation forSignal:theSignal];
	}	
}

- (void)removeInvocation:(NSInvocation*)theInvocation forSignal:(NSString*)theSignal {
	id invocationsForSignal = [invocations objectForKey:theSignal];
	
	if (invocationsForSignal == nil) {
		return;
	}
	
	[invocationsForSignal removeObject:theInvocation];	
}

- (void)setScene:(BJScene*)theScene atRow:(NSUInteger)row column:(NSUInteger)column {
	if (row >= nRows || column >= nColumns) {
		return;
	}
	[[sceneViewPanelControllers objectAtIndex:row*nColumns+column] setScene:theScene];
}

- (id)sceneAtRow:(NSUInteger)row column:(NSUInteger)column {
	id sceneViewPanelController = [sceneViewPanelControllers objectAtIndex:row*nColumns+column];
	if (sceneViewPanelController == nil) {
		return nil;
	}
	return [sceneViewPanelController scene];
}

- (BOOL)isSceneInAnyPanel:(BJScene*)theScene {
	for (id sceneViewPanelController in sceneViewPanelControllers) {
		if ([sceneViewPanelController scene] == theScene) {
			return YES;
		}
	}
	return NO;
}

- (BOOL)isSceneInAnyPanelByName:(NSString*)theSceneName {
	for (id sceneViewPanelController in sceneViewPanelControllers) {
		if ([[sceneViewPanelController sceneName] isEqualToString:theSceneName] == YES) {
			return YES;
		}
	}
	return NO;
}

- (void)invalidateCameras {
	for (id sceneViewPanelController in sceneViewPanelControllers) {
		[sceneViewPanelController invalidateCamera];
	}	
}

- (void)synchronizeAll {
	for (id sceneViewPanelController in sceneViewPanelControllers) {
		[sceneViewPanelController setSynchronized:YES];
	}		
}

- (void)desynchronizeAll {
	for (id sceneViewPanelController in sceneViewPanelControllers) {
		[sceneViewPanelController setSynchronized:NO];
	}	
}

- (void)applyArrangement:(NSDictionary*)theArrangement {
//	id old3DSceneViewPanelController = nil;
//	for (id sceneViewPanelController in sceneViewPanelControllers) {
//		if ([sceneViewPanelController inSceneViewMode] == NO) {
//			continue;
//		}
//		old3DSceneViewPanelController = sceneViewPanelController;
//	}	
		
	NSString* layoutName = [theArrangement objectForKey:@"Type"];
	[self setActiveLayoutName:layoutName];

	NSUInteger index = 0;
	for (id entry in [theArrangement objectForKey:@"Scenes"]) {
		id sceneViewPanelController = [sceneViewPanelControllers objectAtIndex:index];
		[sceneViewPanelController setScene:[workspace sceneWithName:[entry objectForKey:@"Name"]]];
		NSString* viewType = [entry objectForKey:@"View"];
		if ([viewType isEqualToString:@"3D"]) {
			[sceneViewPanelController setViewTo3DWithAnimation:NO];
			NSString* projection = [entry objectForKey:@"Projection"];
			if (projection && [projection isEqualToString:@"Parallel"]) {
				[sceneViewPanelController setParallelProjectionEnabled:YES];
			}
			else {
				[sceneViewPanelController setParallelProjectionEnabled:NO];
			}
			NSString* syncCamera = [entry objectForKey:@"SyncCamera"];
			if (syncCamera) {
				[sceneViewPanelController setSyncCamera:YES];
			}
		}
		else if ([viewType isEqualToString:@"Coronal"]) {
			[sceneViewPanelController setViewToSliceWithAxis:0 withAnimation:NO];
		}
		else if ([viewType isEqualToString:@"Sagittal"]) {
			[sceneViewPanelController setViewToSliceWithAxis:1 withAnimation:NO];
		}
		else if ([viewType isEqualToString:@"Axial"]) {
			[sceneViewPanelController setViewToSliceWithAxis:2 withAnimation:NO];
		}
		index += 1;
	}
	
	[self invalidateCameras];

	[[self workspace] setActiveSceneName:[[[sceneViewPanelControllers objectAtIndex:0] scene] name]];
	
//	if (old3DSceneViewPanelController) {
//		for (id sceneViewPanelController in sceneViewPanelControllers) {
//			[sceneViewPanelController copyCameraFromSceneViewPanelController:old3DSceneViewPanelController];
//		}
//	}	
}

@end
