//
//  VTKView.mm
//  Bunjee
//  Created by Luca Antiga on 3/6/09.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import "VTKView.h"

#import "vtkRenderer.h"
#import "vtkRenderWindowInteractor.h"
#import "vtkCocoaRenderWindowInteractor.h"
#import "vtkCocoaRenderWindow.h"
#import "vtkInteractorStyleTrackballCamera.h"
#import "vtkInteractorStyleImage.h"

#import "vtkOrientationMarkerWidget.h"
#import "vtkAnnotatedCubeActor.h"
#import "vtkPropAssembly.h"
#import "vtkProperty.h"

@implementation VTKView

@synthesize renderer;
@synthesize suppressDraw;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		renderer = NULL;
		orientationMarkerWidget = NULL;
		suppressDraw = NO;
		[self initializeVTK];
    }
    return self;
}

- (void)finalize
{
	[self cleanUpVTK];
    [super finalize];
}

- (void)drawRect:(NSRect)rect {
	if (suppressDraw == YES) {
		[[NSColor windowBackgroundColor] set];
//		[[NSColor colorWithCalibratedWhite:0.0 / 256.0  alpha:1.0] set];
		NSRectFill(rect);		
		return;
	}
	vtkRenderWindowInteractor*	theRenWinInt = [self getInteractor];
	if (theRenWinInt && (theRenWinInt->GetInitialized() == NO))
	{
		theRenWinInt->Initialize();
	}
	[super drawRect:rect];
}

- (void)initializeVTK
{
	vtkRenderer *ren = vtkRenderer::New();
	vtkRenderWindow *renWin = vtkRenderWindow::New();
	vtkRenderWindowInteractor *renWinInt = vtkRenderWindowInteractor::New();
	
	vtkCocoaRenderWindow* cocoaRenWin = vtkCocoaRenderWindow::SafeDownCast(renWin);
	
	if (!(ren && cocoaRenWin && renWinInt)) {
		return;
	}
	
	cocoaRenWin->SetRootWindow([self window]);
	cocoaRenWin->SetWindowId(self);
	
	cocoaRenWin->PointSmoothingOn();
	cocoaRenWin->LineSmoothingOn();
	
//	ren->SetBackground(0.19,0.20,0.21);
	ren->SetBackground(0.0,0.0,0.0);
	ren->UseDepthPeelingOn();
	
	cocoaRenWin->AddRenderer(ren);
	renWinInt->SetRenderWindow(cocoaRenWin);

	vtkAnnotatedCubeActor* cube = vtkAnnotatedCubeActor::New();
/*	cube->SetXPlusFaceText("L");
	cube->SetXMinusFaceText("R");
	cube->SetYPlusFaceText("P");
	cube->SetYMinusFaceText("A");
	cube->SetZPlusFaceText("S");
	cube->SetZMinusFaceText("I");
*/
	cube->SetXPlusFaceText("R");
	cube->SetXMinusFaceText("L");
	cube->SetYPlusFaceText("A");
	cube->SetYMinusFaceText("P");
	cube->SetZPlusFaceText("S");
	cube->SetZMinusFaceText("I");
	cube->SetFaceTextScale(0.67);

	cube->GetXPlusFaceProperty()->SetColor(0,0,0);
	cube->GetXMinusFaceProperty()->SetColor(0,0,0);
	cube->GetYPlusFaceProperty()->SetColor(0,0,0);
	cube->GetYMinusFaceProperty()->SetColor(0,0,0);
	cube->GetZPlusFaceProperty()->SetColor(0,0,0);
	cube->GetZMinusFaceProperty()->SetColor(0,0,0);
	
	cube->GetTextEdgesProperty()->SetColor(0.5, 0.5, 0.5);
	cube->SetTextEdgesVisibility(1);
	cube->SetCubeVisibility(1);
	cube->SetFaceTextVisibility(1);

	if (orientationMarkerWidget) {
		orientationMarkerWidget->Delete();
	}
	
	orientationMarkerWidget = vtkOrientationMarkerWidget::New();
	orientationMarkerWidget->SetOrientationMarker(cube);
	orientationMarkerWidget->SetViewport(0.90,0.90,1.0,1.0);
	orientationMarkerWidget->SetInteractor(renWinInt);
	orientationMarkerWidget->EnabledOn();
	orientationMarkerWidget->InteractiveOff();

	cube->Delete();

	[self setVTKRenderWindow:cocoaRenWin];
	
	[self setInteractorStyleToTrackballCamera];
	
	[self setRenderer:ren];
}

- (void)setInteractorStyleToImage {
	vtkInteractorStyleImage* interactorStyle = vtkInteractorStyleImage::New();
	[self getInteractor]->SetInteractorStyle(interactorStyle);
	interactorStyle->Delete();
}

- (void)setInteractorStyleToTrackballCamera {
	vtkInteractorStyleTrackballCamera* interactorStyle = vtkInteractorStyleTrackballCamera::New();
	[self getInteractor]->SetInteractorStyle(interactorStyle);	
	interactorStyle->Delete();
}

- (void)cleanUpVTK {

	if (orientationMarkerWidget) {
		orientationMarkerWidget->Delete();
		orientationMarkerWidget = NULL;
	}

	vtkRenderer *ren = [self renderer];
	vtkRenderWindow *renWin = [self getVTKRenderWindow];
	vtkRenderWindowInteractor *renWinInt = [self getInteractor];

	if (ren) {
		ren->Delete();
	}

	if (renWin) {
		renWin->Delete();
	}

	if (renWinInt) {
		renWinInt->Delete();
	}

	[self setRenderer:NULL];
	[self setVTKRenderWindow:NULL];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return YES;
}

@end
