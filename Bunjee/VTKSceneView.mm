//
//  VTKSceneView.mm
//  Bunjee
//  Created by Luca Antiga on 3/6/09.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import "VTKSceneView.h"

#import "BJScene.h"
#import "BJDataDisplay.h"
#import "BJData.h"

#import "vtkBJImagePlaneWidget.h"
#import "vtkImageData.h"
#import "vtkRenderer.h"
#import "vtkCamera.h"
#import "vtkProperty.h"
#import "vtkCellPicker.h"
#import "vtkMath.h"
#import "vtkCameraInterpolator.h"
#import "vtkAnimationCue.h"
#import "vtkAnimationScene.h"
#import "vtkTextActor.h"
#import "vtkProperty2D.h"
#import "vtkTextProperty.h"

#import "vtkCocoaRenderWindowInteractor.h"
#import "vtkCocoaRenderWindow.h"
#import "vtkCommand.h"

class vtkHighlightAnimationCallback : public vtkCommand
{
public:
	static vtkHighlightAnimationCallback *New()
	{ return new vtkHighlightAnimationCallback; }
	virtual void Execute(vtkObject *caller, unsigned long event, void* data)
	{
		if (this->PlaneWidget == NULL) {
			return;
		}
		vtkAnimationCue::AnimationCueInfo* info = reinterpret_cast<vtkAnimationCue::AnimationCueInfo*>(data);
		double animationTime = info->AnimationTime;
		int frame = (int)(animationTime / 0.1);
		if (frame == this->Frame) {
			return;
		}
		this->Frame = frame;
		this->PlaneWidget->GetPlaneProperty()->SetColor(1,0,0);
		this->PlaneWidget->GetPlaneProperty()->SetLineWidth(2);		
		[SceneView renderer]->GetRenderWindow()->Render();
	}
	vtkHighlightAnimationCallback()
	{
		this->PlaneWidget = NULL;
		this->Frame = -1;
	}
	vtkBJImagePlaneWidget* PlaneWidget;
	VTKSceneView* SceneView;
	int Frame;
};

class vtkCameraAnimationCallback : public vtkCommand
{
public:
	static vtkCameraAnimationCallback *New()
	{ return new vtkCameraAnimationCallback; }
	virtual void Execute(vtkObject *caller, unsigned long event, void* data)
	{
		vtkAnimationCue::AnimationCueInfo* info = reinterpret_cast<vtkAnimationCue::AnimationCueInfo*>(data);
		double animationTime = info->AnimationTime;
		int frame = (int)(animationTime / 0.01);
		if (frame == this->Frame) {
			return;
		}
		this->Frame = frame;
		if (!this->PlaneWidgetX || !this->PlaneWidgetY || !this->PlaneWidgetZ) {
			return;
		}
		switch (this->ViewAxis) {
			case 0:
				this->PlaneWidgetX->GetPlaneProperty()->SetOpacity(1.0);
				this->PlaneWidgetY->GetPlaneProperty()->SetOpacity(1.0-animationTime);
				this->PlaneWidgetZ->GetPlaneProperty()->SetOpacity(1.0-animationTime);
				this->PlaneWidgetX->GetTexturePlaneProperty()->SetOpacity(1.0);
				this->PlaneWidgetY->GetTexturePlaneProperty()->SetOpacity(1.0-animationTime);
				this->PlaneWidgetZ->GetTexturePlaneProperty()->SetOpacity(1.0-animationTime);
				
				this->PlaneWidgetX->GetPlaneProperty()->SetColor(1.0-animationTime,1.0-animationTime,1.0-animationTime);
				//this->PlaneWidgetX->GetPlaneProperty()->SetColor(1.0,1.0,1.0);
				//this->PlaneWidgetY->GetPlaneProperty()->SetColor(1.0-animationTime,1.0-animationTime,1.0-animationTime);
				//this->PlaneWidgetZ->GetPlaneProperty()->SetColor(1.0-animationTime,1.0-animationTime,1.0-animationTime);

				break;
			case 1:
				this->PlaneWidgetX->GetPlaneProperty()->SetOpacity(1.0-animationTime);
				this->PlaneWidgetY->GetPlaneProperty()->SetOpacity(1.0);
				this->PlaneWidgetZ->GetPlaneProperty()->SetOpacity(1.0-animationTime);
				this->PlaneWidgetX->GetTexturePlaneProperty()->SetOpacity(1.0-animationTime);
				this->PlaneWidgetY->GetTexturePlaneProperty()->SetOpacity(1.0);
				this->PlaneWidgetZ->GetTexturePlaneProperty()->SetOpacity(1.0-animationTime);

				this->PlaneWidgetY->GetPlaneProperty()->SetColor(1.0-animationTime,1.0-animationTime,1.0-animationTime);
				//this->PlaneWidgetX->GetPlaneProperty()->SetColor(1.0-animationTime,1.0-animationTime,1.0-animationTime);
				//this->PlaneWidgetY->GetPlaneProperty()->SetColor(1.0,1.0,1.0);
				//this->PlaneWidgetZ->GetPlaneProperty()->SetColor(1.0-animationTime,1.0-animationTime,1.0-animationTime);
				
				break;
			case 2:
				this->PlaneWidgetX->GetPlaneProperty()->SetOpacity(1.0-animationTime);
				this->PlaneWidgetY->GetPlaneProperty()->SetOpacity(1.0-animationTime);
				this->PlaneWidgetZ->GetPlaneProperty()->SetOpacity(1.0);
				this->PlaneWidgetX->GetTexturePlaneProperty()->SetOpacity(1.0-animationTime);
				this->PlaneWidgetY->GetTexturePlaneProperty()->SetOpacity(1.0-animationTime);
				this->PlaneWidgetZ->GetTexturePlaneProperty()->SetOpacity(1.0);

				this->PlaneWidgetZ->GetPlaneProperty()->SetColor(1.0-animationTime,1.0-animationTime,1.0-animationTime);
				//this->PlaneWidgetX->GetPlaneProperty()->SetColor(1.0-animationTime,1.0-animationTime,1.0-animationTime);
				//this->PlaneWidgetY->GetPlaneProperty()->SetColor(1.0-animationTime,1.0-animationTime,1.0-animationTime);
				//this->PlaneWidgetZ->GetPlaneProperty()->SetColor(1.0,1.0,1.0);
				
				break;
			default:
				break;
		}
		if (this->ViewMode == 0) {
			if (this->FromViewMode == 0) {
				this->PlaneWidgetX->GetPlaneProperty()->SetOpacity(1.0);
				this->PlaneWidgetY->GetPlaneProperty()->SetOpacity(1.0);
				this->PlaneWidgetZ->GetPlaneProperty()->SetOpacity(1.0);
				this->PlaneWidgetX->GetTexturePlaneProperty()->SetOpacity(1.0);
				this->PlaneWidgetY->GetTexturePlaneProperty()->SetOpacity(1.0);
				this->PlaneWidgetZ->GetTexturePlaneProperty()->SetOpacity(1.0);				
			}
			else {
				switch (this->FromViewAxis) {
					case 0:
						this->PlaneWidgetX->GetPlaneProperty()->SetOpacity(1.0);
						this->PlaneWidgetY->GetPlaneProperty()->SetOpacity(animationTime);
						this->PlaneWidgetZ->GetPlaneProperty()->SetOpacity(animationTime);
						this->PlaneWidgetX->GetTexturePlaneProperty()->SetOpacity(1.0);
						this->PlaneWidgetY->GetTexturePlaneProperty()->SetOpacity(animationTime);
						this->PlaneWidgetZ->GetTexturePlaneProperty()->SetOpacity(animationTime);
						
						this->PlaneWidgetX->GetPlaneProperty()->SetColor(animationTime,animationTime,animationTime);
						//this->PlaneWidgetX->GetPlaneProperty()->SetColor(1.0,1.0,1.0);
						//this->PlaneWidgetY->GetPlaneProperty()->SetColor(animationTime,animationTime,animationTime);
						//this->PlaneWidgetZ->GetPlaneProperty()->SetColor(animationTime,animationTime,animationTime);
						
						break;
					case 1:
						this->PlaneWidgetX->GetPlaneProperty()->SetOpacity(animationTime);
						this->PlaneWidgetY->GetPlaneProperty()->SetOpacity(1.0);
						this->PlaneWidgetZ->GetPlaneProperty()->SetOpacity(animationTime);
						this->PlaneWidgetX->GetTexturePlaneProperty()->SetOpacity(animationTime);
						this->PlaneWidgetY->GetTexturePlaneProperty()->SetOpacity(1.0);
						this->PlaneWidgetZ->GetTexturePlaneProperty()->SetOpacity(animationTime);

						this->PlaneWidgetY->GetPlaneProperty()->SetColor(animationTime,animationTime,animationTime);
						//this->PlaneWidgetX->GetPlaneProperty()->SetColor(animationTime,animationTime,animationTime);
						//this->PlaneWidgetY->GetPlaneProperty()->SetColor(1.0,1.0,1.0);
						//this->PlaneWidgetZ->GetPlaneProperty()->SetColor(animationTime,animationTime,animationTime);
						
						break;
					case 2:
						this->PlaneWidgetX->GetPlaneProperty()->SetOpacity(animationTime);
						this->PlaneWidgetY->GetPlaneProperty()->SetOpacity(animationTime);
						this->PlaneWidgetZ->GetPlaneProperty()->SetOpacity(1.0);
						this->PlaneWidgetX->GetTexturePlaneProperty()->SetOpacity(animationTime);
						this->PlaneWidgetY->GetTexturePlaneProperty()->SetOpacity(animationTime);
						this->PlaneWidgetZ->GetTexturePlaneProperty()->SetOpacity(1.0);

						this->PlaneWidgetZ->GetPlaneProperty()->SetColor(animationTime,animationTime,animationTime);
						//this->PlaneWidgetX->GetPlaneProperty()->SetColor(animationTime,animationTime,animationTime);
						//this->PlaneWidgetY->GetPlaneProperty()->SetColor(animationTime,animationTime,animationTime);
						//this->PlaneWidgetZ->GetPlaneProperty()->SetColor(1.0,1.0,1.0);
						
					break;
					default:
						break;
				}
			}
		}
		vtkCamera* activeCamera = [SceneView renderer]->GetActiveCamera();
		this->CameraInterpolator->InterpolateCamera(animationTime,activeCamera);
		[SceneView renderer]->GetRenderWindow()->Render();
	}
	vtkCameraAnimationCallback()
	{
		this->Frame = -1;
	}
	vtkBJImagePlaneWidget* PlaneWidgetX;	
	vtkBJImagePlaneWidget* PlaneWidgetY;	
	vtkBJImagePlaneWidget* PlaneWidgetZ;
	int ViewAxis;
	int ViewMode;
	int FromViewMode;
	int FromViewAxis;	
	vtkCameraInterpolator* CameraInterpolator;
	VTKSceneView* SceneView;
	int Frame;
};

class vtkCrosshairCallback : public vtkCommand
{
public:
	static vtkCrosshairCallback *New()
	{ return new vtkCrosshairCallback; }
	virtual void Execute(vtkObject *caller, unsigned long event, void* data)
	{
//		if ([SceneView renderer]->GetRenderWindow()->GetInteractor()->GetControlKey() == 0) {
//			return;
//		}
		//if ([SceneView crosshairEnabled] == NO) {
		//	return;
		//}
		vtkImagePlaneWidget* planeWidget = vtkImagePlaneWidget::SafeDownCast(caller);
		if (!planeWidget) {
			return;
		}
		if ([[SceneView scene] activeImageData] == nil) {
			return;
		}
//		double cursorData[4];
//		planeWidget->GetCursorData(cursorData);
		double cursorPosition[3];
		double cursorValue;
		if (planeWidget->GetCursorDataStatus() == 1) {
			planeWidget->GetCurrentCursorPosition(cursorPosition);
			cursorValue = planeWidget->GetCurrentImageValue();
		}
		else {
			cursorPosition[0] = cursorPosition[1] = cursorPosition[2] = 0.0;
			cursorValue = 0.0;
		}
		double wl = planeWidget->GetLevel();
		double ww = planeWidget->GetWindow();
		double spacing[3], origin[3];
		int extent[6];
		vtkImageData* image = [[[SceneView scene] activeImageData] imageData];
		image->GetSpacing(spacing);
		image->GetOrigin(origin);
		image->GetExtent(extent);
		NSInteger ijk[3];
		double xyz[3];
		if (planeWidget->GetUseContinuousCursor()) {
			xyz[0] = cursorPosition[0];
			xyz[1] = cursorPosition[1];
			xyz[2] = cursorPosition[2];
			ijk[0] = (xyz[0]-origin[0]) / spacing[0] + extent[0];
			ijk[1] = (xyz[1]-origin[1]) / spacing[1] + extent[2];
			ijk[2] = (xyz[2]-origin[2]) / spacing[2] + extent[4];
		}
		else {
			ijk[0] = cursorPosition[0];
			ijk[1] = cursorPosition[1];
			ijk[2] = cursorPosition[2];
			xyz[0] = (ijk[0]-extent[0]) * spacing[0] + origin[0];
			xyz[1] = (ijk[1]-extent[2]) * spacing[1] + origin[1];
			xyz[2] = (ijk[2]-extent[4]) * spacing[2] + origin[2];			
		}
		NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithDouble:ijk[0]], @"I", 
								  [NSNumber numberWithDouble:ijk[1]], @"J", 
								  [NSNumber numberWithDouble:ijk[2]], @"K", 
								  [NSNumber numberWithDouble:xyz[0]], @"X", 
								  [NSNumber numberWithDouble:xyz[1]], @"Y", 
								  [NSNumber numberWithDouble:xyz[2]], @"Z", 
								  [NSNumber numberWithDouble:cursorValue], @"Scalar",
								  [SceneView scene], @"Scene", nil];
		[SceneView setCrosshairAnnotationIJK:ijk XYZ:xyz scalar:cursorValue wl:wl ww:ww];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"CrosshairChanged" object:SceneView userInfo:userInfo];
	}
	vtkCrosshairCallback()
	{
	}
	VTKSceneView* SceneView;
};

class vtkSeedCallback : public vtkCommand
{
public:
	static vtkSeedCallback *New()
	{ return new vtkSeedCallback; }
	virtual void Execute(vtkObject *caller, unsigned long event, void* data)
	{
		if ([SceneView renderer]->GetRenderWindow()->GetInteractor()->GetControlKey() == 0) {
			return;
		}
		if ([SceneView seedingEnabled] == NO) {
			return;
		}
		vtkImagePlaneWidget* planeWidget = vtkImagePlaneWidget::SafeDownCast(caller);
		if (!planeWidget) {
			return;
		}
		if ([[SceneView scene] activeImageData] == nil) {
			return;
		}
		double cursorData[4];
		planeWidget->GetCursorData(cursorData);
		int continuousCursor = planeWidget->GetUseContinuousCursor();
		double point[3];
		if (continuousCursor) {
			point[0] = cursorData[0];
			point[1] = cursorData[1];
			point[2] = cursorData[2];
		}
		else{
			double spacing[3], origin[3];
			int extent[6];
			vtkImageData* image = [[[SceneView scene] activeImageData] imageData];
			image->GetSpacing(spacing);
			image->GetOrigin(origin);
			image->GetExtent(extent);
			point[0] = (cursorData[0]-extent[0]) * spacing[0] + origin[0];
			point[1] = (cursorData[1]-extent[2]) * spacing[1] + origin[1];
			point[2] = (cursorData[2]-extent[4]) * spacing[2] + origin[2];
		}
		[SceneView addSeed:point];
		//[SceneView crosshairCallback]->Execute(caller,event,data);
	}
	vtkSeedCallback()
	{
	}
	VTKSceneView* SceneView;
};

class vtkWindowLevelCallback : public vtkCommand
{
public:
	static vtkWindowLevelCallback *New()
	{ return new vtkWindowLevelCallback; }
	virtual void Execute(vtkObject *caller, unsigned long event, void* data)
	{
		vtkImagePlaneWidget* planeWidget = vtkImagePlaneWidget::SafeDownCast(caller);
		if (!planeWidget) {
			return;
		}
		double level = planeWidget->GetLevel();
		double window = planeWidget->GetWindow();
		NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:window], @"Window", [NSNumber numberWithDouble:level], @"Level", [SceneView scene], @"Scene", nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"WindowLevelChanged" object:SceneView userInfo:userInfo];
		//[SceneView crosshairCallback]->Execute(caller,event,data);
	}
	vtkWindowLevelCallback()
	{
	}
	VTKSceneView* SceneView;	
};

class vtkCameraCallback : public vtkCommand
{
public:
	static vtkCameraCallback *New()
	{ return new vtkCameraCallback; }

	virtual void Execute(vtkObject *caller, unsigned long event, void* data)
	{
		if ([SceneView syncCamera] == YES && [SceneView copyingCamera] == NO) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"CameraModified" object:SceneView userInfo:nil];
		}
		[SceneView updateOrientationAnnotation];
	}
	vtkCameraCallback()
	{
	}
	VTKSceneView* SceneView;	
};

int BJComputeDirection(double theVector[3]) {
	double absVector[3];
	absVector[0] = fabs(theVector[0]);
	absVector[1] = fabs(theVector[1]);
	absVector[2] = fabs(theVector[2]);
	int direction;
	if (absVector[0] >= absVector[1] and absVector[0] >= absVector[2]) {
		if (theVector[0] >= 0.0) {
			direction = 1;
		}
		else {
			direction = -1;
		}
	}
	else if (absVector[1] >= absVector[0] and absVector[1] >= absVector[2]) {
		if (theVector[1] >= 0.0) {
			direction = 2;
		}
		else {
			direction = -2;
		}
	}
	else {
		if (theVector[2] >= 0.0) {
			direction = 3;
		}
		else {
			direction = -3;
		}
	}
	return direction;
}

@implementation VTKSceneView

@synthesize scene;
@synthesize seedingEnabled;
@synthesize crosshairEnabled;
@synthesize sliceViewAllowed;
@synthesize viewMode;
@synthesize viewAxis;
@synthesize mipEnabled;
@synthesize toolId;
@synthesize mouseTracking;
@synthesize show3D;
@synthesize cameraAnimation;
@synthesize syncCamera;
@synthesize copyingCamera;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		viewMode = 0;
		viewAxis = 0;
		
		planeWidgetX = NULL;
		planeWidgetY = NULL;
		planeWidgetZ = NULL;
		
		seedCallback = NULL;
		crosshairCallback = NULL;
		windowLevelCallback = NULL;
		cameraCallback = NULL;

		scene = nil;

		cameraInitialized = NO;
		seedingEnabled = NO;
		crosshairEnabled = NO;
		sliceViewAllowed = NO;
		
		mipEnabled = NO;
		show3D = YES;
		
		sceneCamera = NULL;
		
		sceneNameActor = NULL;

		crosshairAnnotationActor = NULL;
		
		topOrientationActor = NULL;
		bottomOrientationActor = NULL;
		leftOrientationActor = NULL;
		rightOrientationActor = NULL;
		
		signalInvocations = [[NSMutableDictionary alloc] init];
		
		toolId = CH;
		mouseTracking = NO;
		
		cameraAnimation = YES;
		syncCamera = NO;
		copyingCamera = NO;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toolIdHasChanged:) name:@"ToolIdChanged" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mouseTrackingHasChanged:) name:@"MouseTrackingChanged" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sceneNameIsChanging:) name:@"SceneNameChanging" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sceneIsBeingRemoved:) name:@"SceneIsBeingRemoved" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraHasBeenModified:) name:@"CameraModified" object:nil];

		[self initializeSceneView];
	}
    return self;
}

- (void)finalize {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"ToolIdChanged" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"MouseTrackingChanged" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"SceneNameChanging" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"SceneIsBeingRemoved" object:nil];
	[self cleanUpSceneView];
    [super finalize];
}

- (void)addInvocation:(NSInvocation*)theInvocation forSignal:(NSString*)theSignal {
	NSMutableSet* invocations = [signalInvocations objectForKey:theSignal];
	if (invocations == nil) {
		invocations = [[NSMutableSet alloc] init];
		[signalInvocations setObject:invocations forKey:theSignal];
	}
	for (NSInvocation* invocation in invocations) {
		if ([invocation selector] == [theInvocation selector] && [invocation target] == [theInvocation target]) {
			return;
		}
	}
	[invocations addObject:theInvocation];
}

- (void)removeInvocation:(NSInvocation*)theInvocation forSignal:(NSString*)theSignal {
	NSMutableSet* invocations = [signalInvocations objectForKey:theSignal];
	if (invocations == nil) {
		return;
	}
	[invocations removeObject:theInvocation];	
}

- (NSSet*)invocationsForSignal:(NSString*)theSignal {
	return [signalInvocations objectForKey:theSignal];
}

- (BOOL)cameraViewVector:(double*)theVector {
	if ([self renderer] == NULL) {
		return NO;
	}
	vtkCamera* activeCamera = [self renderer]->GetActiveCamera();
	if (activeCamera == NULL) {
		return NO;
	}
	
	activeCamera->GetViewPlaneNormal(theVector);

//	double position[3], focalPoint[3];
//	activeCamera->GetPosition(position);
//	activeCamera->GetFocalPoint(focalPoint);
	
//	theVector[0] = focalPoint[0] - position[0];
//	theVector[1] = focalPoint[1] - position[1];
//	theVector[2] = focalPoint[2] - position[2];
	
	return YES;
}

- (BOOL)cameraViewUp:(double*)theVector {
	if ([self renderer] == NULL) {
		return NO;
	}
	vtkCamera* activeCamera = [self renderer]->GetActiveCamera();
	if (activeCamera == NULL) {
		return NO;
	}
	activeCamera->GetViewUp(theVector);
	
	return YES;
}

- (vtkCrosshairCallback*)crosshairCallback {
	return crosshairCallback;
}

- (void)setCrosshairAnnotationIJK:(NSInteger*)ijk XYZ:(double*)xyz scalar:(double)scalar wl:(double)wl ww:(double)ww {
	NSString* annotation = [NSString stringWithFormat:@"I: %d J: %d K: %d Value: %.2f\nX: %.2f Y: %.2f Z: %.2f\nWL: %.2f WW: %.2f",ijk[0],ijk[1],ijk[2],scalar,xyz[0],xyz[1],xyz[2],wl,ww];
	crosshairAnnotationActor->SetInput([annotation UTF8String]);
}

- (void)resetCrosshairAnnotation {
	crosshairAnnotationActor->SetInput("");
}

- (void)setOrientationAnnotationUp:(const char*)up down:(const char*)down {
	if (topOrientationActor == NULL or bottomOrientationActor == NULL) {
		return;
	}
	topOrientationActor->SetInput(up);
	bottomOrientationActor->SetInput(down);
}

- (void)setOrientationAnnotationRight:(const char*)right left:(const char*)left {
	if (rightOrientationActor == NULL or leftOrientationActor == NULL) {
		return;
	}
	rightOrientationActor->SetInput(right);
	leftOrientationActor->SetInput(left);
}

- (void)setMipEnabled:(BOOL)mip {
	mipEnabled = mip;
	[[scene activeImageDataDisplay] setMipEnabled:mipEnabled];
	[self setNeedsDisplay:YES];
}

- (void)setShow3D:(BOOL)show {
	show3D = show;
	[self displayScene];
}

- (void)toolIdHasChanged:(NSNotification*)notification {
	[self setToolId:[[[notification userInfo] objectForKey:@"ToolId"] intValue]];
}

- (void)mouseTrackingHasChanged:(NSNotification*)notification {
	[self setMouseTracking:[[[notification userInfo] objectForKey:@"MouseTracking"] boolValue]];
}

- (void)cameraHasBeenModified:(NSNotification*)notification {
	if ([self syncCamera] == NO) {
		return;
	}

	if ([notification object] == self) {
		return;
	}
	
	if ([[notification object] viewMode] != 0) {
		return;
	}

	if ([self viewMode] != 0) {
		return;
	}
	
	[self copyCameraFromSceneView:[notification object]];
	
	[self updateOrientationAnnotation];
	
	[self setNeedsDisplay:YES];
}

- (void)setMouseTracking:(BOOL)isMouseTracked {
	[[self window] setAcceptsMouseMovedEvents:isMouseTracked];
}

- (void)sceneNameIsChanging:(NSNotification*)notification {
	if ([notification object] != scene) {
		return;
	}
	
	if ([[notification userInfo] objectForKey:@"NewName"] != nil) {
		sceneNameActor->SetInput([[NSString stringWithFormat:@"Scene: %@",[[notification userInfo] objectForKey:@"NewName"]] UTF8String]);	
	}
	else {
		sceneNameActor->SetInput("Scene: -");	
	}
	[self setNeedsDisplay:YES];
}

- (void)sceneIsBeingRemoved:(NSNotification*)notification {
	if ([[notification userInfo] objectForKey:@"Scene"] != scene) {
		return;
	}
	
	[self removeSceneDataFromRenderer];
	
	scene = nil;
	viewMode = -1;
	cameraInitialized = NO;
	
	[self cleanUpSceneView];
	[self initializeSceneView];

	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect {
	[super drawRect:rect];
}

- (void)setBackgroundToDark {
	renderer->SetBackground(0.0,0.0,0.0);
//	renderer->SetBackground(0.19,0.20,0.21);
}

- (void)setBackgroundToLight {
	renderer->SetBackground(0.40,0.41,0.44);
}

- (void)setBackgroundToBlack {
	renderer->SetBackground(0.0,0.0,0.0);
}

- (BOOL)parallelProjectionEnabled {
	if ([self renderer]->GetActiveCamera() == NULL) {
		return NO;
	}
	
	if ([self renderer]->GetActiveCamera()->GetParallelProjection()) {
		return YES;
	}
	
	return NO;
}

- (void)setParallelProjectionEnabled:(BOOL)enabled {
	if ([self renderer]->GetActiveCamera() == NULL) {
		return;
	}	
	
	if (viewMode != 0) {
		return;
	}
	
	if (enabled) {
		[self renderer]->GetActiveCamera()->ParallelProjectionOn();
	}
	else {
		[self renderer]->GetActiveCamera()->ParallelProjectionOff();
	}
	
	[self setNeedsDisplay:YES];
}

- (void)initializeSceneView {
	[self setUpPlaneWidgets];
	
	sceneCamera = vtkCamera::New();
	
	sceneNameActor = vtkTextActor::New();
	sceneNameActor->GetProperty()->SetColor(0.0,1.0,0.0);
	sceneNameActor->SetInput("Scene: -");
	renderer->AddActor(sceneNameActor);

	vtkCoordinate* coordinate = sceneNameActor->GetPositionCoordinate();
	coordinate->SetCoordinateSystemToNormalizedViewport();
	coordinate->SetValue(0.01,0.95);

	crosshairAnnotationActor = vtkTextActor::New();
	crosshairAnnotationActor->GetProperty()->SetColor(0.0,1.0,0.0);
	renderer->AddActor(crosshairAnnotationActor);
	
	coordinate = crosshairAnnotationActor->GetPositionCoordinate();
	coordinate->SetCoordinateSystemToNormalizedViewport();
	coordinate->SetValue(0.01,0.02);
	
	topOrientationActor = vtkTextActor::New();
	topOrientationActor->GetProperty()->SetColor(0.0,1.0,0.0);
	renderer->AddActor(topOrientationActor);

	coordinate = topOrientationActor->GetPositionCoordinate();
	coordinate->SetCoordinateSystemToNormalizedViewport();
	coordinate->SetValue(0.5,0.96);
	
	bottomOrientationActor = vtkTextActor::New();
	bottomOrientationActor->GetProperty()->SetColor(0.0,1.0,0.0);
	renderer->AddActor(bottomOrientationActor);

	coordinate = bottomOrientationActor->GetPositionCoordinate();
	coordinate->SetCoordinateSystemToNormalizedViewport();
	coordinate->SetValue(0.5,0.02);
	
	leftOrientationActor = vtkTextActor::New();
	leftOrientationActor->GetProperty()->SetColor(0.0,1.0,0.0);
	renderer->AddActor(leftOrientationActor);

	coordinate = leftOrientationActor->GetPositionCoordinate();
	coordinate->SetCoordinateSystemToNormalizedViewport();
	coordinate->SetValue(0.02,0.5);
	
	rightOrientationActor = vtkTextActor::New();
	rightOrientationActor->GetProperty()->SetColor(0.0,1.0,0.0);
	renderer->AddActor(rightOrientationActor);

	coordinate = rightOrientationActor->GetPositionCoordinate();
	coordinate->SetCoordinateSystemToNormalizedViewport();
	coordinate->SetValue(0.98,0.5);
	
	cameraCallback = vtkCameraCallback::New();
	cameraCallback->SceneView = self;
	renderer->GetActiveCamera()->AddObserver(vtkCommand::ModifiedEvent,cameraCallback);	
}

- (void)setUpPlaneWidgetsCallbacks {
	crosshairCallback = vtkCrosshairCallback::New();
	crosshairCallback->SceneView = self;
	planeWidgetX->AddObserver(vtkCommand::InteractionEvent,crosshairCallback);
	planeWidgetY->AddObserver(vtkCommand::InteractionEvent,crosshairCallback);
	planeWidgetZ->AddObserver(vtkCommand::InteractionEvent,crosshairCallback);
	
	seedCallback = vtkSeedCallback::New();
	seedCallback->SceneView = self;
	planeWidgetX->AddObserver(vtkCommand::StartInteractionEvent,seedCallback);
	planeWidgetY->AddObserver(vtkCommand::StartInteractionEvent,seedCallback);
	planeWidgetZ->AddObserver(vtkCommand::StartInteractionEvent,seedCallback);
	planeWidgetX->AddObserver(vtkCommand::StartInteractionEvent,crosshairCallback);
	planeWidgetY->AddObserver(vtkCommand::StartInteractionEvent,crosshairCallback);
	planeWidgetZ->AddObserver(vtkCommand::StartInteractionEvent,crosshairCallback);
	
	windowLevelCallback = vtkWindowLevelCallback::New();
	windowLevelCallback->SceneView = self;
	planeWidgetX->AddObserver(vtkCommand::WindowLevelEvent,windowLevelCallback);
	planeWidgetY->AddObserver(vtkCommand::WindowLevelEvent,windowLevelCallback);
	planeWidgetZ->AddObserver(vtkCommand::WindowLevelEvent,windowLevelCallback);
	planeWidgetX->AddObserver(vtkCommand::WindowLevelEvent,crosshairCallback);
	planeWidgetY->AddObserver(vtkCommand::WindowLevelEvent,crosshairCallback);
	planeWidgetZ->AddObserver(vtkCommand::WindowLevelEvent,crosshairCallback);
}

- (void)cleanUpPlaneWidgetsCallbacks {
	if (seedCallback) {
		if (planeWidgetX) {
			planeWidgetX->RemoveObserver(seedCallback);
		}
		if (planeWidgetY) {
			planeWidgetY->RemoveObserver(seedCallback);
		}
		if (planeWidgetZ) {
			planeWidgetZ->RemoveObserver(seedCallback);
		}
		seedCallback->Delete();
		seedCallback = NULL;
	}
	if (crosshairCallback) {
		if (planeWidgetX) {
			planeWidgetX->RemoveObserver(crosshairCallback);
		}
		if (planeWidgetY) {
			planeWidgetY->RemoveObserver(crosshairCallback);
		}
		if (planeWidgetZ) {
			planeWidgetZ->RemoveObserver(crosshairCallback);
		}
		crosshairCallback->Delete();
		crosshairCallback = NULL;
	}
	if (windowLevelCallback) {
		if (planeWidgetX) {
			planeWidgetX->RemoveObserver(windowLevelCallback);
		}
		if (planeWidgetY) {
			planeWidgetY->RemoveObserver(windowLevelCallback);
		}
		if (planeWidgetZ) {
			planeWidgetZ->RemoveObserver(windowLevelCallback);
		}
		windowLevelCallback->Delete();
		windowLevelCallback = NULL;
	}
}

- (void)cleanUpSceneView {
	if (sceneCamera) {
		sceneCamera->Delete();
		sceneCamera = NULL;
	}
	if (sceneNameActor) {
		renderer->RemoveActor(sceneNameActor);
		sceneNameActor->Delete();
		sceneNameActor = NULL;
	}
	if (rightOrientationActor) {
		renderer->RemoveActor(rightOrientationActor);
		rightOrientationActor->Delete();
		rightOrientationActor = NULL;
	}
	if (leftOrientationActor) {
		renderer->RemoveActor(leftOrientationActor);
		leftOrientationActor->Delete();
		leftOrientationActor = NULL;
	}
	if (topOrientationActor) {
		renderer->RemoveActor(topOrientationActor);
		topOrientationActor->Delete();
		topOrientationActor = NULL;
	}
	if (bottomOrientationActor) {
		renderer->RemoveActor(bottomOrientationActor);
		bottomOrientationActor->Delete();
		bottomOrientationActor = NULL;
	}
	cameraCallback->Delete();
	[self destroyPlaneWidgets];
}

- (void)setUpPlaneWidgets {
	vtkCellPicker* picker = vtkCellPicker::New();
	picker->SetTolerance(5e-3);
	planeWidgetX = vtkBJImagePlaneWidget::New();
	planeWidgetX->SetInteractor((vtkRenderWindowInteractor*)[self getInteractor]);
	planeWidgetX->KeyPressActivationOff();
	planeWidgetX->DisplayTextOn();
	planeWidgetX->SetPicker(picker);
	planeWidgetX->SetMarginSizeX(0.0);
	planeWidgetX->SetMarginSizeY(0.0);
	planeWidgetX->DisplayTextOff();
	planeWidgetX->GetTextProperty()->SetColor(0.0,1.0,0.0);
	planeWidgetX->UseContinuousCursorOff();
	planeWidgetX->Off();
	planeWidgetY = vtkBJImagePlaneWidget::New();
	planeWidgetY->SetInteractor((vtkRenderWindowInteractor*)[self getInteractor]);
	planeWidgetY->KeyPressActivationOff();
	planeWidgetY->DisplayTextOn();
	planeWidgetY->SetLookupTable(planeWidgetX->GetLookupTable());
	planeWidgetY->SetPicker(picker);
	planeWidgetY->SetMarginSizeX(0.0);
	planeWidgetY->SetMarginSizeY(0.0);
	planeWidgetY->DisplayTextOff();
	planeWidgetY->GetTextProperty()->SetColor(0.0,1.0,0.0);
	planeWidgetY->UseContinuousCursorOff();
	planeWidgetY->Off();
	planeWidgetZ = vtkBJImagePlaneWidget::New();
	planeWidgetZ->SetInteractor((vtkRenderWindowInteractor*)[self getInteractor]);
	planeWidgetZ->KeyPressActivationOff();
	planeWidgetZ->DisplayTextOn();
	planeWidgetZ->SetLookupTable(planeWidgetX->GetLookupTable());
	planeWidgetZ->SetPicker(picker);
	planeWidgetZ->SetMarginSizeX(0.0);
	planeWidgetZ->SetMarginSizeY(0.0);
	planeWidgetZ->DisplayTextOff();
	planeWidgetZ->GetTextProperty()->SetColor(0.0,1.0,0.0);
	planeWidgetZ->UseContinuousCursorOff();
	planeWidgetZ->Off();
	picker->Delete();
	[self setUpPlaneWidgetsCallbacks];
}

- (void)destroyPlaneWidgets {
	[self cleanUpPlaneWidgetsCallbacks];
	if (planeWidgetX) {
		planeWidgetX->Off();
		planeWidgetX->SetInteractor(NULL);
		planeWidgetX->Delete();
		planeWidgetX = NULL;
	}
	if (planeWidgetY) {
		planeWidgetY->Off();
		planeWidgetY->SetInteractor(NULL);
		planeWidgetY->Delete();
		planeWidgetY = NULL;
	}
	if (planeWidgetZ) {
		planeWidgetZ->Off();
		planeWidgetZ->SetInteractor(NULL);
		planeWidgetZ->Delete();
		planeWidgetZ = NULL;
	}	
}

- (BOOL)planeWidgetsAvailable {
	if (!planeWidgetX || !planeWidgetY || !planeWidgetZ) {
		return NO;
	}
	return YES;
}

- (void)setScene:(BJScene*)theScene {
	if (scene == theScene) {
		return;
	}

	[self removeSceneDataFromRenderer];
	scene = theScene;
	
	viewMode = -1;
	cameraInitialized = NO;
	[self displayScene];
}

- (void)addSeed:(double*)point {
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:[NSNumber numberWithDouble:point[0]],[NSNumber numberWithDouble:point[1]],[NSNumber numberWithDouble:point[2]],nil], @"SeedPoint", scene, @"Scene", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SceneViewSeedAdded" object:self userInfo:userInfo];
	[self setNeedsDisplay:YES];
}

- (void)updateInteractor {
	if (planeWidgetX) {
		planeWidgetX->SetInteractor((vtkRenderWindowInteractor*)[self getInteractor]);
	}
	if (planeWidgetY) {
		planeWidgetY->SetInteractor((vtkRenderWindowInteractor*)[self getInteractor]);
	}
	if (planeWidgetZ) {
		planeWidgetZ->SetInteractor((vtkRenderWindowInteractor*)[self getInteractor]);
	}
}

- (void)keyDown:(NSEvent *)theEvent {
}

- (void)keyUp:(NSEvent *)theEvent {
}

- (void)flagsChanged:(NSEvent *)theEvent {
	[[self nextResponder] flagsChanged:theEvent];
}

- (void)mouseMoved: (NSEvent *)theEvent {	
	vtkCocoaRenderWindow* renWin = vtkCocoaRenderWindow::SafeDownCast([self getVTKRenderWindow]);
	
	double factor = 1.0;
	if (renWin) {
		factor = renWin->GetScaleFactor();
	}
	
	NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];

	NSSet* invocations = [self invocationsForSignal:@"MouseMoved"];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSNumber numberWithDouble:factor],@"Factor",
							  [NSNumber numberWithDouble:mouseLoc.x],@"MouseX",
							  [NSNumber numberWithDouble:mouseLoc.y],@"MouseY",
							  self,@"VTKSceneView",
							  nil];
	
	for (NSInvocation* invocation in invocations) {
		[invocation setArgument:&userInfo atIndex:2];
		[invocation invoke];
	}	
}

- (void)mouseDown:(NSEvent *)theEvent {

	vtkCocoaRenderWindowInteractor *interactor = [self getInteractor];
	if (!interactor) {
		return;
	}
  
	vtkCocoaRenderWindow* renWin = vtkCocoaRenderWindow::SafeDownCast([self getVTKRenderWindow]);
	if (!renWin) {
		return;
	}
	
	double factor = renWin->GetScaleFactor();
  
	BOOL keepOn = YES;

	NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  
	int shiftDown = 0;
	int controlDown = 0;
	int commandDown = 0;
	int optionDown = 0;
	
	if (toolId == SD or toolId == IPRT) {
		controlDown = 1;
	}
	interactor->SetEventInformation((int)round(mouseLoc.x * factor), (int)round(mouseLoc.y * factor), controlDown, shiftDown);

	if ([self planeWidgetsAvailable] == YES) {
		if (toolId == RT or toolId == TR or toolId == ZM or toolId == IPRT) {
			planeWidgetX->InteractionOff();
			planeWidgetY->InteractionOff();
			planeWidgetZ->InteractionOff();
		}
		else {
			planeWidgetX->InteractionOn();
			planeWidgetY->InteractionOn();
			planeWidgetZ->InteractionOn();
		}
	}
	switch (toolId) {
		case RT:
			break;
		case ZM:
			commandDown = 1;
			break;
		case TR:
			optionDown = 1;
			break;
		case CH:
			break;
		case WL:
			commandDown = 1;
			break;
		case SL:
			optionDown = 1;
			break;
		default:
			break;
	}
	
	if (toolId == CH) {
		[self setCrosshairEnabled:YES];
	}
	else {
		[self setCrosshairEnabled:NO];
	}
	
	NSSet* invocations = [self invocationsForSignal:@"ShouldInvokeVTKEvent"];
	BOOL shouldInvokeVTKEvent = YES;
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self,@"VTKSliceView",nil];
	for (NSInvocation* invocation in invocations) {
		[invocation setArgument:&userInfo atIndex:2];
		[invocation invoke];
		NSNumber* doInvokeVTKEvent;
		[invocation getReturnValue:&doInvokeVTKEvent];
		if ([doInvokeVTKEvent boolValue] == NO) {
			shouldInvokeVTKEvent = NO;
			break;
		}
	}
	
	if (shouldInvokeVTKEvent == NO) {
	}
	else if (viewMode != 0 and toolId == SL) {
	}
	else {
		if (commandDown) {
			interactor->InvokeEvent(vtkCommand::RightButtonPressEvent,NULL);
		}
		else if (optionDown) {
			interactor->InvokeEvent(vtkCommand::MiddleButtonPressEvent,NULL);
		}
		else {
			interactor->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
		}
	}

	[[self nextResponder] mouseDown:theEvent];

	invocations = [self invocationsForSignal:@"LeftMouseDown"];
	userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithDouble:factor],@"Factor",
				[NSNumber numberWithDouble:mouseLoc.x],@"MouseX",
				[NSNumber numberWithDouble:mouseLoc.y],@"MouseY",
				self,@"VTKSceneView",
				nil];
	for (NSInvocation* invocation in invocations) {
		[invocation setArgument:&userInfo atIndex:2];
		[invocation invoke];
	}	
	
	NSInteger previousMouseLocX = mouseLoc.x;
	NSInteger previousMouseLocY = mouseLoc.y;
	NSDate* infinity = [NSDate distantFuture];
	do {
		theEvent = [NSApp nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask untilDate:infinity inMode:NSEventTrackingRunLoopMode dequeue:YES];
		
		if (theEvent) {
			mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	  
			interactor->SetEventInformation((int)round(mouseLoc.x * factor), (int)round(mouseLoc.y * factor), controlDown, shiftDown);
			
			switch ([theEvent type]) {
				case NSLeftMouseDragged:
				{
					NSSet* invocations = [self invocationsForSignal:@"LeftMouseDragged"];
					NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
											  [NSNumber numberWithDouble:factor],@"Factor",
											  [NSNumber numberWithDouble:mouseLoc.x],@"MouseX",
											  [NSNumber numberWithDouble:mouseLoc.y],@"MouseY",
											  [NSNumber numberWithDouble:previousMouseLocX],@"PreviousMouseX",
											  [NSNumber numberWithDouble:previousMouseLocY],@"PreviousMouseY",
											  self,@"VTKSceneView",
											  nil];
					for (NSInvocation* invocation in invocations) {
						[invocation setArgument:&userInfo atIndex:2];
						[invocation invoke];
					}
					break;
				}
				case NSLeftMouseUp:
				{
					NSSet* invocations = [self invocationsForSignal:@"LeftMouseUp"];
					NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
											  [NSNumber numberWithDouble:factor],@"Factor",
											  [NSNumber numberWithDouble:mouseLoc.x],@"MouseX",
											  [NSNumber numberWithDouble:mouseLoc.y],@"MouseY",
											  self,@"VTKSceneView",
											  nil];
					for (NSInvocation* invocation in invocations) {
						[invocation setArgument:&userInfo atIndex:2];
						[invocation invoke];
					}	
					break;
				}
			}
			
			if (viewMode != 0 and toolId == SL) {
				switch ([theEvent type]) {
					case NSLeftMouseDragged:
						[self setSlice:(int)([self getSlice]+mouseLoc.y-previousMouseLocY)];
						break;
					case NSLeftMouseUp:
						[self setSlice:(int)([self getSlice]+mouseLoc.y-previousMouseLocY)];
						keepOn = NO;
					default:
						break;
				}
			}
			else {				
				switch ([theEvent type]) {
					case NSLeftMouseDragged:
						interactor->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
						[self renderer]->ResetCameraClippingRange();
						break;
					case NSLeftMouseUp:
						if (commandDown) {
							interactor->InvokeEvent(vtkCommand::RightButtonReleaseEvent, NULL);					
						}
						else if (optionDown) {
							interactor->InvokeEvent(vtkCommand::MiddleButtonReleaseEvent, NULL);
						}
						else {
							interactor->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
						}
						keepOn = NO;
					default:
						break;
				}
				//TODO: take this one outside using signal
				if (viewMode == 0 and toolId == SL) {
					[self notifySliceChanged];
				}
			}
		}
		else {
			keepOn = NO;
		}
		
		previousMouseLocX = mouseLoc.x;
		previousMouseLocY = mouseLoc.y;
	}
	while (keepOn);
}

- (void)showPlaneWidget:(int)axis {
	if (![self planeWidgetsAvailable]) {
		[self setUpPlaneWidgets];
	}
	switch (axis) {
		case 0:
			if (planeWidgetX->GetEnabled() == 0) {
				planeWidgetX->On();
			}
			planeWidgetX->GetPlaneProperty()->SetOpacity(1.0);
			planeWidgetX->GetTexturePlaneProperty()->SetOpacity(1.0);
			planeWidgetX->GetPlaneProperty()->SetColor(0.0,0.0,0.0);
			planeWidgetX->InteractionOn();
			break;
		case 1:
			if (planeWidgetY->GetEnabled() == 0) {
				planeWidgetY->On();
			}
			planeWidgetY->GetPlaneProperty()->SetOpacity(1.0);
			planeWidgetY->GetTexturePlaneProperty()->SetOpacity(1.0);
			planeWidgetY->GetPlaneProperty()->SetColor(0.0,0.0,0.0);
			planeWidgetY->InteractionOn();
			break;
		case 2:
			if (planeWidgetZ->GetEnabled() == 0) {
				planeWidgetZ->On();
			}
			planeWidgetZ->GetPlaneProperty()->SetOpacity(1.0);
			planeWidgetZ->GetTexturePlaneProperty()->SetOpacity(1.0);
			planeWidgetZ->GetPlaneProperty()->SetColor(0.0,0.0,0.0);
			planeWidgetZ->InteractionOn();
			break;
	}
}

- (void)hidePlaneWidget:(int)axis {
	if (![self planeWidgetsAvailable]) {
		[self setUpPlaneWidgets];
	}	
	switch (axis) {
		case 0:
			if (planeWidgetX->GetEnabled() == 0) {
				planeWidgetX->On();
			}			
			planeWidgetX->GetPlaneProperty()->SetOpacity(0.0);
			planeWidgetX->GetTexturePlaneProperty()->SetOpacity(0.0);
			planeWidgetX->InteractionOff();
			break;
		case 1:
			if (planeWidgetY->GetEnabled() == 0) {
				planeWidgetY->On();
			}			
			planeWidgetY->GetPlaneProperty()->SetOpacity(0.0);
			planeWidgetY->GetTexturePlaneProperty()->SetOpacity(0.0);
			planeWidgetY->InteractionOff();
			break;
		case 2:
			if (planeWidgetZ->GetEnabled() == 0) {
				planeWidgetZ->On();
			}			
			planeWidgetZ->GetPlaneProperty()->SetOpacity(0.0);
			planeWidgetZ->GetTexturePlaneProperty()->SetOpacity(0.0);
			planeWidgetZ->InteractionOff();
			break;
	}
}

- (void)activatePlaneWidget:(int)axis {
	
	if (!sliceViewAllowed) {
		[self renderer]->ResetCameraClippingRange();
		[self renderer]->ResetCamera();
		[self setNeedsDisplay:YES];
		return;
	}	
	
	if (![self planeWidgetsAvailable]) {
		[self setUpPlaneWidgets];
	}	
	switch (axis) {
		case 0:
			[self showPlaneWidget:0];
			[self hidePlaneWidget:1];
			[self hidePlaneWidget:2];
			planeWidgetX->GetSelectedPlaneProperty()->SetColor(0,0,0);
			planeWidgetX->GetPlaneProperty()->SetColor(0,0,0);
			break;
		case 1:
			[self hidePlaneWidget:0];
			[self showPlaneWidget:1];
			[self hidePlaneWidget:2];
			planeWidgetY->GetSelectedPlaneProperty()->SetColor(0,0,0);
			planeWidgetY->GetPlaneProperty()->SetColor(0,0,0);
			break;
		case 2:
			[self hidePlaneWidget:0];
			[self hidePlaneWidget:1];
			[self showPlaneWidget:2];
			planeWidgetZ->GetSelectedPlaneProperty()->SetColor(0,0,0);	
			planeWidgetZ->GetPlaneProperty()->SetColor(0,0,0);
			break;
	}
	[self renderer]->ResetCameraClippingRange();
	[self setNeedsDisplay:YES];	
}

- (void)activateAllPlaneWidgets {

	if (![self planeWidgetsAvailable]) {
		[self setUpPlaneWidgets];
	}

	if (scene == nil) {
		planeWidgetX->EnabledOff();
		planeWidgetY->EnabledOff();
		planeWidgetZ->EnabledOff();
		[self renderer]->ResetCameraClippingRange();
		[self renderer]->ResetCamera();
		[self setNeedsDisplay:YES];
		return;		
	}
	
	if (![scene activeImageData] || ![scene dataDisplayedForKey:[scene activeImageDataKey]]) {
		planeWidgetX->EnabledOff();
		planeWidgetY->EnabledOff();
		planeWidgetZ->EnabledOff();
		[self renderer]->ResetCameraClippingRange();
		[self renderer]->ResetCamera();
		[self setNeedsDisplay:YES];
		return;
	}
	
	[self showPlaneWidget:0];
	[self showPlaneWidget:1];
	[self showPlaneWidget:2];
	planeWidgetX->GetPlaneProperty()->SetColor(1,1,1);
	planeWidgetY->GetPlaneProperty()->SetColor(1,1,1);
	planeWidgetZ->GetPlaneProperty()->SetColor(1,1,1);	
	planeWidgetX->GetSelectedPlaneProperty()->SetColor(0,1,0);
	planeWidgetY->GetSelectedPlaneProperty()->SetColor(0,1,0);
	planeWidgetZ->GetSelectedPlaneProperty()->SetColor(0,1,0);
	[self renderer]->ResetCameraClippingRange();
	[self setNeedsDisplay:YES];
}

- (double)min:(double*)values among:(int)nvalues {
	double min = 1E40;
	for (unsigned int i=0; i<nvalues; i++) {
		if (values[i] < min) {
			min = values[i];
		}
	}
	return min;
}

- (double)max:(double*)values among:(int)nvalues {
	double max = -1E40;
	for (unsigned int i=0; i<nvalues; i++) {
		if (values[i] > max) {
			max = values[i];
		}
	}
	return max;
}

- (void)setCameraToAxis:(int)axis {

	if (viewMode == 1 && axis == viewAxis) {
		return;
	}

	if (![self planeWidgetsAvailable]) {
		return;
	}
	
	double vn[3], vu[3], fp[3];
	fp[0] = fp[1] = fp[2] = 0.0;
	double origin[3], vector1[3], vector2[3];
	switch (axis) {
		case 0:
			vn[0] = 1.0;
			vn[1] = 0.0;
			vn[2] = 0.0;
			vu[0] = 0.0;
			vu[1] = 0.0;
			vu[2] = 1.0;
			planeWidgetX->GetOrigin(origin);
			planeWidgetX->GetVector1(vector1);
			planeWidgetX->GetVector2(vector2);
			break;
		case 1:
			vn[0] = 0.0;
			//vn[1] = -1.0;
			vn[1] = 1.0;
			vn[2] = 0.0;
			vu[0] = 0.0;
			vu[1] = 0.0;
			vu[2] = 1.0;
			planeWidgetY->GetOrigin(origin);
			planeWidgetY->GetVector1(vector1);
			planeWidgetY->GetVector2(vector2);
			break;
		case 2:
			vn[0] = 0.0;
			vn[1] = 0.0;
			vn[2] = -1.0;
			vu[0] = 0.0;
			vu[1] = 1.0;
			vu[2] = 0.0;
			planeWidgetZ->GetOrigin(origin);
			planeWidgetZ->GetVector1(vector1);
			planeWidgetZ->GetVector2(vector2);
			break;
		default:
			break;
	}
	
	vtkCamera* activeCamera = [self renderer]->GetActiveCamera();

	double px[4], py[4], pz[4];
	px[0] = origin[0];
	px[1] = origin[0] + vector1[0];
	px[2] = origin[0] + vector2[0];
	px[3] = origin[0] + vector1[0] + vector2[0];
	py[0] = origin[1];
	py[1] = origin[1] + vector1[1];
	py[2] = origin[1] + vector2[1];
	py[3] = origin[1] + vector1[1] + vector2[1];
	pz[0] = origin[2];
	pz[1] = origin[2] + vector1[2];
	pz[2] = origin[2] + vector2[2];
	pz[3] = origin[2] + vector1[2] + vector2[2];
	double bounds[6];
	bounds[0] = [self min:px among:4];
	bounds[1] = [self max:px among:4];
	bounds[2] = [self min:py among:4];
	bounds[3] = [self max:py among:4];
	bounds[4] = [self min:pz among:4];
	bounds[5] = [self max:pz among:4];
	double center[3];
	center[0] = (bounds[0] + bounds[1])/2.0;
	center[1] = (bounds[2] + bounds[3])/2.0;
	center[2] = (bounds[4] + bounds[5])/2.0;
	/*
	double w1 = bounds[1] - bounds[0];
	double w2 = bounds[3] - bounds[2];
	double w3 = bounds[5] - bounds[4];
	w1 *= w1;
	w2 *= w2;
	w3 *= w3;
	double radius = w1 + w2 + w3;
	radius = (radius==0) ? (1.0) : (radius);
	radius = sqrt(radius) * 0.5;
	*/

	double radiusX, radiusY;
	switch (axis) {
		case 0:
			radiusX = bounds[3] - bounds[2];
			radiusY = bounds[5] - bounds[4];
			break;
		case 1:
			radiusX = bounds[1] - bounds[0];
			radiusY = bounds[5] - bounds[4];
			break;
		case 2:
			radiusX = bounds[1] - bounds[0];
			radiusY = bounds[3] - bounds[2];			
			break;
		default:
			break;
	}
	radiusX *= 0.5;
	radiusY *= 0.5;
	
	int* rendererSize = renderer->GetSize();
	double aspectRatio = (double)rendererSize[1] / rendererSize[0];
	
	radiusX *= aspectRatio;
	
	double radius = radiusY;
	if (radiusX > radiusY) {
		radius = radiusX;
	}

	double distance = radius/sin(activeCamera->GetViewAngle()*vtkMath::Pi()/360.0);

	if (viewMode == 0 && cameraAnimation == YES) {
		vtkCamera* targetCamera = vtkCamera::New();
		targetCamera->SetFocalPoint(center[0],center[1],center[2]);
		targetCamera->SetPosition(center[0]+distance*vn[0],center[1]+distance*vn[1],center[2]+distance*vn[2]);
		targetCamera->SetViewUp(vu);
		targetCamera->SetParallelScale(radius);
		vtkBJImagePlaneWidget* planeWidget;
		switch (axis) {
			case 0:
				planeWidget = planeWidgetX;
				break;
			case 1:
				planeWidget = planeWidgetY;
				break;
			case 2:
				planeWidget = planeWidgetZ;
				break;
		}
		
		vtkAnimationCue* animationCue = vtkAnimationCue::New();
		animationCue->SetTimeModeToNormalized();
		animationCue->SetStartTime(0.0);
		animationCue->SetEndTime(1.0);
		
		vtkHighlightAnimationCallback *highlightCallback = vtkHighlightAnimationCallback::New();
		highlightCallback->PlaneWidget = planeWidget;
		highlightCallback->SceneView = self;
		animationCue->AddObserver(vtkCommand::AnimationCueTickEvent,highlightCallback);
		
		vtkAnimationScene* animationScene = vtkAnimationScene::New();
		animationScene->AddCue(animationCue);
		animationScene->SetModeToRealTime();
		animationScene->SetFrameRate(10.0);
		animationScene->SetStartTime(0.0);
		animationScene->SetEndTime(0.25);
		animationScene->Play();
		
		animationScene->RemoveObserver(highlightCallback);
		
		highlightCallback->Delete();
		animationCue->Delete();
		animationScene->Delete();
		planeWidget->GetPlaneProperty()->SetColor(1,1,1);
		planeWidget->GetPlaneProperty()->SetLineWidth(1);
		[self interpolateActiveCameraFrom:activeCamera to:targetCamera viewMode:1 viewAxis:axis];

		activeCamera->SetFocalPoint(center[0],center[1],center[2]);
		activeCamera->SetPosition(center[0]+distance*vn[0],center[1]+distance*vn[1],center[2]+distance*vn[2]);
		activeCamera->SetViewUp(vu);
		activeCamera->SetParallelScale(radius);
	}
	else {
		[self restorePlanesOpacity];
		activeCamera->SetFocalPoint(center[0],center[1],center[2]);
		activeCamera->SetPosition(center[0]+distance*vn[0],center[1]+distance*vn[1],center[2]+distance*vn[2]);
		activeCamera->SetViewUp(vu);
		activeCamera->SetParallelScale(radius);
	}

	activeCamera->ParallelProjectionOn();
	
	[self renderer]->ResetCameraClippingRange(bounds);
	[self setNeedsDisplay:YES];
}

- (void)restorePlanesOpacity {
	if (![self planeWidgetsAvailable]) {
		[self setUpPlaneWidgets];
	}	
	
	planeWidgetX->GetPlaneProperty()->SetOpacity(1.0);
	planeWidgetY->GetPlaneProperty()->SetOpacity(1.0);
	planeWidgetZ->GetPlaneProperty()->SetOpacity(1.0);
	planeWidgetX->GetTexturePlaneProperty()->SetOpacity(1.0);
	planeWidgetY->GetTexturePlaneProperty()->SetOpacity(1.0);
	planeWidgetZ->GetTexturePlaneProperty()->SetOpacity(1.0);
	planeWidgetX->GetPlaneProperty()->SetColor(1,1,1);
	planeWidgetY->GetPlaneProperty()->SetColor(1,1,1);
	planeWidgetZ->GetPlaneProperty()->SetColor(1,1,1);	
}

- (void)interpolateActiveCameraFrom:(vtkCamera*)activeCamera to:(vtkCamera*)targetCamera {
	[self interpolateActiveCameraFrom:activeCamera to:targetCamera viewMode:0 viewAxis:0];
}

- (void)interpolateActiveCameraFrom:(vtkCamera*)sourceCamera to:(vtkCamera*)targetCamera viewMode:(int)theViewMode viewAxis:(int)theViewAxis {
	vtkCameraInterpolator* cameraInterpolator = vtkCameraInterpolator::New();
	cameraInterpolator->SetInterpolationTypeToSpline();
	cameraInterpolator->AddCamera(0.0,sourceCamera);
	cameraInterpolator->AddCamera(1.0,targetCamera);

	vtkAnimationCue* animationCue = vtkAnimationCue::New();
	animationCue->SetTimeModeToNormalized();
	animationCue->SetStartTime(0.0);
	animationCue->SetEndTime(1.0);

	vtkCameraAnimationCallback *cameraAnimationCallback = vtkCameraAnimationCallback::New();
	cameraAnimationCallback->CameraInterpolator = cameraInterpolator;
	cameraAnimationCallback->PlaneWidgetX = planeWidgetX;
	cameraAnimationCallback->PlaneWidgetY = planeWidgetY;
	cameraAnimationCallback->PlaneWidgetZ = planeWidgetZ;
	cameraAnimationCallback->FromViewAxis = (int)viewAxis;
	cameraAnimationCallback->ViewMode = theViewMode;
	cameraAnimationCallback->ViewAxis = theViewAxis;
	cameraAnimationCallback->FromViewAxis = (int)viewAxis;
	cameraAnimationCallback->FromViewMode = (int)viewMode;
	cameraAnimationCallback->SceneView = self;
	animationCue->AddObserver(vtkCommand::AnimationCueTickEvent,cameraAnimationCallback);
	
	vtkAnimationScene* animationScene = vtkAnimationScene::New();
	animationScene->AddCue(animationCue);
	animationScene->SetModeToRealTime();
	animationScene->SetFrameRate(10.0);
	animationScene->SetStartTime(0.0);
	animationScene->SetEndTime(0.5);
	animationScene->Play();

	animationCue->RemoveObserver(cameraCallback);

	cameraAnimationCallback->Delete();
	cameraInterpolator->Delete();
	animationScene->Delete();
	animationCue->Delete();
}

- (void)setCameraToScene {
	vtkCamera* activeCamera = [self renderer]->GetActiveCamera();
	activeCamera->ParallelProjectionOff();
	
	if (cameraInitialized == YES) {
		[self interpolateActiveCameraFrom:activeCamera to:sceneCamera];
		[self restorePlanesOpacity];
	}
	else {
		//vtkCamera* activeCamera = [self renderer]->GetActiveCamera();
		//activeCamera->SetPosition(1,1,1);
		//activeCamera->SetViewUp(0,0,1);
		[self renderer]->ResetCamera();
		[self backupCamera];
		cameraInitialized = YES;
	}

	[self renderer]->ResetCameraClippingRange();	
	[self setNeedsDisplay:YES];
}

- (void)backupCamera {
	vtkCamera* activeCamera = [self renderer]->GetActiveCamera();
	sceneCamera->SetPosition(activeCamera->GetPosition());
	sceneCamera->SetFocalPoint(activeCamera->GetFocalPoint());
	sceneCamera->SetViewUp(activeCamera->GetViewUp());
}

- (void)resetCamera {
	//TODO: behave differently when in slice mode
	if (viewMode == 0) {
		[self renderer]->ResetCamera();
		[self setNeedsDisplay:YES];
	}	
}

- (void)invalidateCamera {
	[self renderer]->GetActiveCamera()->Modified();
}

- (vtkCamera*)sceneCamera {
	return sceneCamera;
}

- (void)copyCameraFromSceneView:(id)theSceneView {
	[self setCopyingCamera:YES];
	vtkCamera* targetCamera = [theSceneView renderer]->GetActiveCamera();
	vtkCamera* activeCamera = [self renderer]->GetActiveCamera();
//	activeCamera->DeepCopy(targetCamera);
	activeCamera->SetPosition(targetCamera->GetPosition());
	activeCamera->SetFocalPoint(targetCamera->GetFocalPoint());
	activeCamera->SetViewUp(targetCamera->GetViewUp());
	renderer->ResetCameraClippingRange();
	[self setCopyingCamera:NO];
}

- (void)setSliceMode:(int)axis {
	if (viewMode == 1 && axis == viewAxis) {
		return;
	}
	if (viewMode == 0) {
		[self backupCamera];
	}
	[self setCameraToAxis:axis];
	[self activatePlaneWidget:axis];
	[self setInteractorStyleToImage];
	[self updateInteractor];
	//[self setBackgroundToBlack];
	[self setBackgroundToDark];
	viewAxis = axis;
	viewMode = 1;
}

- (void)setSceneMode {
	if (viewMode == 0) {
		return;
	}
	[self activateAllPlaneWidgets];
	[self setCameraToScene];
	[self setInteractorStyleToTrackballCamera];
	[self updateInteractor];
	[self setBackgroundToDark];
	viewMode = 0;
}

- (void)setSliceNoNotify:(int)theSlice forAxis:(int)theAxis {
//	if (viewMode == 0) {
//		return;
//	}

	if ([scene activeImageData] == nil) {
		return;
	}

	if (![self planeWidgetsAvailable]) {
		return;
	}	

	if (viewMode == 0) {
		switch (theAxis) {
			case 0:
				planeWidgetX->SetSliceIndex(theSlice);
				break;
			case 1:
				planeWidgetY->SetSliceIndex(theSlice);
				break;
			case 2:
				planeWidgetZ->SetSliceIndex(theSlice);
				break;
			default:
				break;
		}		
		[self renderer]->ResetCameraClippingRange();
		[self setNeedsDisplay:YES];
		return;
	}
	
	if (theAxis != viewAxis) {
		return;
	}
	
	int currentSliceIndex = -1;
	
	switch (viewAxis) {
		case 0:
			currentSliceIndex = planeWidgetX->GetSliceIndex();
			break;
		case 1:
			currentSliceIndex = planeWidgetY->GetSliceIndex();
			break;
		case 2:
			currentSliceIndex = planeWidgetZ->GetSliceIndex();
			break;
		default:
			break;
	}

	BJImageData* imageData = [scene activeImageData];
	double spacing = [imageData imageData]->GetSpacing()[viewAxis];

	vtkCamera* camera = [self renderer]->GetActiveCamera();
	double cameraPosition[3];
	camera->GetPosition(cameraPosition);
	cameraPosition[viewAxis] += spacing * (theSlice - currentSliceIndex);
	camera->SetPosition(cameraPosition);
	double cameraFocalPoint[3];
	camera->GetFocalPoint(cameraFocalPoint);
	cameraFocalPoint[viewAxis] += spacing * (theSlice - currentSliceIndex);
	camera->SetFocalPoint(cameraFocalPoint);
	
	switch (viewAxis) {
		case 0:
			planeWidgetX->SetSliceIndex(theSlice);
			break;
		case 1:
			planeWidgetY->SetSliceIndex(theSlice);
			break;
		case 2:
			planeWidgetZ->SetSliceIndex(theSlice);
			break;
		default:
			break;
	}

	[self renderer]->ResetCameraClippingRange();
	[self setNeedsDisplay:YES];
}

- (void)notifySliceChanged {
	NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] init];
	[userInfo setObject:[NSNumber numberWithInt:[self getSlice:0]] forKey:@"X"];
	[userInfo setObject:[NSNumber numberWithInt:[self getSlice:1]] forKey:@"Y"];
	[userInfo setObject:[NSNumber numberWithInt:[self getSlice:2]] forKey:@"Z"];
	[userInfo setObject:[NSNumber numberWithInt:(int)viewAxis] forKey:@"ViewAxis"];
	[userInfo setObject:[NSNumber numberWithInt:(int)viewMode] forKey:@"ViewMode"];
	[userInfo setObject:scene forKey:@"Scene"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SliceChanged" object:self userInfo:userInfo];
}

- (void)setSlice:(int)theSlice {
	[self setSliceNoNotify:theSlice forAxis:(int)viewAxis];
	[self notifySliceChanged];
}

- (int)getSlice {
	if (viewAxis < 0) {
		return -1;
	}
	return [self getSlice:(int)viewAxis];
}

- (int)getSlice:(int)axis {
	int sliceIndex = -1;

	if (![self planeWidgetsAvailable]) {
		return -1;
	}	
	
	switch (axis) {
		case 0:
			sliceIndex = planeWidgetX->GetSliceIndex();
			break;
		case 1:
			sliceIndex = planeWidgetY->GetSliceIndex();
			break;
		case 2:
			sliceIndex = planeWidgetZ->GetSliceIndex();
			break;
		default:
			break;
	}
	return sliceIndex;
}

- (int)getSliceMin:(int)axis {
	return [[scene activeImageData] imageData]->GetExtent()[2*axis];
}

- (int)getSliceMax:(int)axis {
	return [[scene activeImageData] imageData]->GetExtent()[2*axis+1];
}

- (int)getNumberOfSlices:(int)axis {
	int* extent = [[scene activeImageData] imageData]->GetExtent();
	return extent[2*axis+1] - extent[2*axis];
}

- (void)setWindow:(double)window level:(double)level {
	if (![self planeWidgetsAvailable]) {
		return;
	}
	planeWidgetX->SetWindowLevel(window,level);
}

- (void)removeSceneDataFromRenderer {
	for (id key in [scene dataDisplayDictionary]) {
		[[scene dataDisplayForKey:key] removeFromRenderer:renderer];
	}	
}

- (void)displayScene {
	BOOL newSliceViewAllowed = YES;
	BOOL newPlaneWidgetsCreated = NO;

	if (scene == nil) {
		sliceViewAllowed = NO;
		sceneNameActor->SetInput("Scene: -");
		[self setSceneMode];
		[self setNeedsDisplay:YES];
		return;
	}
		
	if ([scene activeImageData]) {
		if ([scene dataDisplayedForKey:[scene activeImageDataKey]]) {
			vtkImageData* image = [[scene activeImageData] imageData];
			if (![self planeWidgetsAvailable]) {
				[self setUpPlaneWidgets];
				newPlaneWidgetsCreated = YES;
			}
			if (planeWidgetX->GetInput() != image) {
				planeWidgetX->SetInput(image);
				planeWidgetX->SetPlaneOrientationToXAxes();	
				planeWidgetY->SetInput(image);
				planeWidgetY->SetPlaneOrientationToYAxes();	
				planeWidgetZ->SetInput(image);
				planeWidgetZ->SetPlaneOrientationToZAxes();	
				planeWidgetX->On();
				planeWidgetY->On();
				planeWidgetZ->On();
			}
			newSliceViewAllowed = YES;
		}
		else {
			[self destroyPlaneWidgets];
			newSliceViewAllowed = NO;
		}
	}
	else {
		[self destroyPlaneWidgets];
		newSliceViewAllowed = NO;
	}
	
	if (newPlaneWidgetsCreated) {
		for (id key in [scene dataDisplayDictionary]) {
			if ([scene dataDisplayedForKey:key] == YES) {
				[[NSNotificationCenter defaultCenter] removeObserver:self name:@"DataDisplayBeingRemoved" object:[scene dataDisplayForKey:key]];
				[[scene dataDisplayForKey:key] removeFromRenderer:renderer];
			}
		}
	}

	for (id key in [scene dataDisplayDictionary]) {
		if ([scene dataDisplayedForKey:key] == YES and ([self show3D] == YES or ([self show3D] ==  NO and [[scene dataDisplayForKey:key] threeD] == NO))) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataDisplayIsBeingRemoved:) name:@"DataDisplayBeingRemoved" object:[scene dataDisplayForKey:key]];
			[[scene dataDisplayForKey:key] addToRenderer:renderer];
		}
		else {
			[[NSNotificationCenter defaultCenter] removeObserver:self name:@"DataDisplayBeingRemoved" object:[scene dataDisplayForKey:key]];
			[[scene dataDisplayForKey:key] removeFromRenderer:renderer];
		}
	}
	
	if (sliceViewAllowed != newSliceViewAllowed) {
		sliceViewAllowed = newSliceViewAllowed;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SliceViewAllowedChanged" object:self];
	}

	if (!sliceViewAllowed) {
		[self setSceneMode];
	}
	
	if (viewMode == -1) {
		[self setSceneMode];
	}

	if ([scene name] != nil) {
		sceneNameActor->SetInput([[NSString stringWithFormat:@"Scene: %@",[scene name]] UTF8String]);
	}
	else {
		sceneNameActor->SetInput("Scene: -");
	}
	
	[self setNeedsDisplay:YES];
}

- (void)dataDisplayIsBeingRemoved:(NSNotification*)notification {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"DataDisplayBeingRemoved" object:[notification object]];
	[[notification object] removeFromRenderer:renderer];	
}

- (void)updateOrientationAnnotation {
	double viewVector[3], viewUp[3];
	BOOL result1 = [self cameraViewVector:viewVector];
	BOOL result2 = [self cameraViewUp:viewUp];
	if (result1 == NO or result2 == NO) {
		return;
	}
	double viewRight[3];
	vtkMath::Cross(viewUp,viewVector,viewRight);
	int rightDirection = BJComputeDirection(viewRight);
	int upDirection = BJComputeDirection(viewUp);
	switch (upDirection) {
		case 1:
			[self setOrientationAnnotationUp:"R" down:"L"];
			break;
		case -1:
			[self setOrientationAnnotationUp:"L" down:"R"];
			break;
		case 2:
			[self setOrientationAnnotationUp:"A" down:"P"];
			break;
		case -2:
			[self setOrientationAnnotationUp:"P" down:"A"];
			break;
		case 3:
			[self setOrientationAnnotationUp:"S" down:"I"];
			break;
		case -3:
			[self setOrientationAnnotationUp:"I" down:"S"];
			break;
	}
	switch (rightDirection) {
		case 1:
			[self setOrientationAnnotationRight:"R" left:"L"];
			break;
		case -1:
			[self setOrientationAnnotationRight:"L" left:"R"];
			break;
		case 2:
			[self setOrientationAnnotationRight:"A" left:"P"];
			break;
		case -2:
			[self setOrientationAnnotationRight:"P" left:"A"];
			break;
		case 3:
			[self setOrientationAnnotationRight:"S" left:"I"];
			break;
		case -3:
			[self setOrientationAnnotationRight:"I" left:"S"];
			break;
	}
}

@end
