//
//  VTKView.h
//  Bunjee
//  Created by Luca Antiga on 3/6/09.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "vtkCocoaGLView.h"

class vtkRenderer;
class vtkOrientationMarkerWidget;

@interface VTKView : vtkCocoaGLView {
	vtkRenderer* renderer;
	vtkOrientationMarkerWidget* orientationMarkerWidget;
	BOOL suppressDraw;
}

@property(readwrite) vtkRenderer* renderer;
@property(readwrite) BOOL suppressDraw;

- (void)initializeVTK;
- (void)cleanUpVTK;

- (void)setInteractorStyleToImage;
- (void)setInteractorStyleToTrackballCamera;

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;

@end
