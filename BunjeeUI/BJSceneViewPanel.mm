//
//  BJSceneViewPanel.mm
//  Bunjee
//  Created by Luca Antiga on 1/9/10.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import "BJSceneViewPanel.h"

@implementation BJSceneViewToolsPanel

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
	if (self) {
		darkBackground = NO;
	}
	return self;
}

- (void)drawRect:(NSRect)rect {

//	fillGradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:[NSColor colorWithCalibratedWhite:254.0 / 256.0  alpha:1.0],
//													   [NSColor colorWithCalibratedWhite:169.0 / 256.0 alpha:1.0],nil]];

	NSGradient* fillGradient;
	if (darkBackground) {
		fillGradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:[NSColor colorWithCalibratedWhite:150.0 / 256.0  alpha:1.0],
														   [NSColor colorWithCalibratedWhite:69.0 / 256.0 alpha:1.0],nil]];
	}
	else {
		fillGradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:[NSColor colorWithCalibratedWhite:254.0 / 256.0  alpha:1.0],
														   [NSColor colorWithCalibratedWhite:169.0 / 256.0 alpha:1.0],nil]];
	}
	CGFloat fillAngle = 270.0f;
	[fillGradient drawInRect:[self bounds] angle:fillAngle];
/*	
	//[[NSColor colorWithCalibratedWhite:169.0 / 256.0  alpha:1.0] set];
	[[NSColor colorWithCalibratedWhite:0.0 / 256.0  alpha:1.0] set];
	NSRect lineRect;
	lineRect.size.width = rect.size.width;
	lineRect.size.height = 1;
	lineRect.origin.x = rect.origin.x;
	lineRect.origin.y = rect.origin.y + rect.size.height - 1;
	NSRectFill(lineRect);
*/
}

- (void)setBackgroundToDark {
	darkBackground = YES;
}

- (void)setBackgroundToLight {
	darkBackground = NO;
}

@end

@implementation BJSceneViewPanel

@synthesize delegate;
@synthesize sceneViewToolsPanel;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
	if (self) {
		[self registerForDraggedTypes:[NSArray arrayWithObjects: NSStringPboardType, nil]];		
	}
	return self;
}

- (void)finalize {
	[self unregisterDraggedTypes];		
	[super finalize];
}

- (void)mouseDown:(NSEvent*)theEvent {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SceneViewPanelSelected" object:self];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	if ([delegate respondsToSelector: @selector(draggingEntered:)])
	{
		return [delegate draggingEntered:sender];
	}
	
	return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	if ([delegate respondsToSelector: @selector(prepareForDragOperation:)])
	{
		return [delegate prepareForDragOperation:sender];
	}
	
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	if ([delegate respondsToSelector: @selector(performDragOperation:)])
	{
		return [delegate performDragOperation:sender];
	}
	return NO;
}

- (void)setBackgroundToDark {
	[sceneViewToolsPanel setBackgroundToDark];
}

- (void)setBackgroundToLight {
	[sceneViewToolsPanel setBackgroundToLight];
}


@end

