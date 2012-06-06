//
//  VTKInteractionEvent.h
//  Bunjee
//  Created by Luca Antiga on 3/6/09.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VTKView.h"

@class BJScene;

class vtkBJImagePlaneWidget;
class vtkCamera;
class vtkSeedCallback;
class vtkCrosshairCallback;
class vtkWindowLevelCallback;
class vtkCameraCallback;
class vtkTextActor;

enum {
	AUTO=0,
	WL,
	TR,
	ZM,
	RT,
	SL,
	CH,
	SD,
	IPRT
};

@interface VTKSceneView : VTKView {
	BJScene* scene;
	vtkBJImagePlaneWidget* planeWidgetX;
	vtkBJImagePlaneWidget* planeWidgetY;
	vtkBJImagePlaneWidget* planeWidgetZ;
	vtkSeedCallback* seedCallback;
	vtkCrosshairCallback* crosshairCallback;
	vtkWindowLevelCallback* windowLevelCallback;
	vtkCameraCallback* cameraCallback;
	vtkTextActor* sceneNameActor;

	vtkTextActor* crosshairAnnotationActor;

	vtkTextActor* topOrientationActor;
	vtkTextActor* bottomOrientationActor;
	vtkTextActor* leftOrientationActor;
	vtkTextActor* rightOrientationActor;

	NSMutableDictionary* signalInvocations;
	
	NSInteger viewMode;
	NSInteger viewAxis;
	
	BOOL cameraInitialized;
	vtkCamera* sceneCamera;
	BOOL seedingEnabled;
	BOOL crosshairEnabled;
	BOOL sliceViewAllowed;

	BOOL syncCamera;

	BOOL mipEnabled;
	BOOL show3D;
	BOOL mouseTracking;
	
	BOOL cameraAnimation;
	BOOL copyingCamera;
	
	NSInteger toolId;
	
}

@property(readonly) BJScene* scene;
@property(readonly) BOOL mipEnabled;
@property(readwrite) BOOL seedingEnabled;
@property(readwrite) BOOL crosshairEnabled;
@property(readonly) BOOL show3D;
@property(readwrite) BOOL syncCamera;
@property(readwrite) NSInteger toolId;
@property(readwrite) BOOL mouseTracking;
@property(readonly) BOOL sliceViewAllowed;
@property(readonly) NSInteger viewMode;
@property(readonly) NSInteger viewAxis;
@property(readwrite) BOOL cameraAnimation;
@property(readwrite) BOOL copyingCamera;

- (void)setScene:(BJScene*)theScene;
- (void)setMipEnabled:(BOOL)mip;
- (void)setShow3D:(BOOL)show;

- (void)initializeSceneView;
- (void)cleanUpSceneView;

- (void)setScene:(BJScene*)theScene;
- (void)removeSceneDataFromRenderer;

- (void)addInvocation:(NSInvocation*)theInvocation forSignal:(NSString*)theSignal;
- (void)removeInvocation:(NSInvocation*)theInvocation forSignal:(NSString*)theSignal;

- (BOOL)cameraViewVector:(double*)theVector;
- (BOOL)cameraViewUp:(double*)theVector;

- (void)addInvocation:(NSInvocation*)theInvocation forSignal:(NSString*)theSignal;
- (void)removeInvocation:(NSInvocation*)theInvocation forSignal:(NSString*)theSignal;
- (NSSet*)invocationsForSignal:(NSString*)theSignal;

- (void)setCrosshairAnnotationIJK:(NSInteger*)ijk XYZ:(double*)XYZ scalar:(double)scalar wl:(double)wl ww:(double)ww;
- (void)resetCrosshairAnnotation;
- (vtkCrosshairCallback*)crosshairCallback;

- (vtkCamera*)sceneCamera;

- (void)invalidateCamera;

- (void)setOrientationAnnotationUp:(const char*)up down:(const char*)down;
- (void)setOrientationAnnotationRight:(const char*)right left:(const char*)left;

- (void)displayScene;

- (void)setBackgroundToDark;
- (void)setBackgroundToLight;

- (BOOL)parallelProjectionEnabled;
- (void)setParallelProjectionEnabled:(BOOL)enabled;

- (void)addSeed:(double*)point;

- (void)setSliceMode:(int)axis;
- (void)setSceneMode;

- (void)showPlaneWidget:(int)axis;
- (void)hidePlaneWidget:(int)axis;

- (void)setUpPlaneWidgets;
- (void)destroyPlaneWidgets;
- (BOOL)planeWidgetsAvailable;

- (void)activatePlaneWidget:(int)axis;
- (void)activateAllPlaneWidgets;

- (void)setCameraToAxis:(int)axis;
- (void)setCameraToScene;

- (void)backupCamera;
- (void)resetCamera;

- (void)copyCameraFromSceneView:(id)theSceneView;
// TODO, in struct
//- (NSDictionary*)activeCameraSettings;

- (void)updateInteractor;

- (int)getSliceMin:(int)axis;
- (int)getSliceMax:(int)axis;
- (int)getNumberOfSlices:(int)axis;
- (int)getSlice:(int)axis;
- (int)getSlice;
- (void)setSlice:(int)theSlice;
- (void)setSliceNoNotify:(int)theSlice forAxis:(int)theAxis;

- (void)notifySliceChanged;
- (void)setWindow:(double)window level:(double)level;

- (void)mouseTrackingHasChanged:(NSNotification*)notification;

- (void)interpolateActiveCameraFrom:(vtkCamera*)activeCamera to:(vtkCamera*)targetCamera;
- (void)interpolateActiveCameraFrom:(vtkCamera*)sourceCamera to:(vtkCamera*)targetCamera viewMode:(int)theViewMode viewAxis:(int)theViewAxis;
- (void)restorePlanesOpacity;

- (void)dataDisplayIsBeingRemoved:(NSNotification*)notification;

- (void)updateOrientationAnnotation;

- (id)takeScreenshot;

@end
