//
//  BJSceneViewPanel.h
//  Bunjee
//  Created by Luca Antiga on 1/9/10.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BJSceneViewToolsPanel : NSView {
	BOOL darkBackground;
}

- (void)setBackgroundToDark;
- (void)setBackgroundToLight;

@end

@interface BJSceneViewPanel : NSView {
	IBOutlet id delegate;
	IBOutlet BJSceneViewToolsPanel* sceneViewToolsPanel;
}

@property (readwrite,retain) id delegate;
@property (readwrite,retain) BJSceneViewToolsPanel* sceneViewToolsPanel;

- (void)mouseDown:(NSEvent*)theEvent;
- (void)setBackgroundToDark;
- (void)setBackgroundToLight;

@end
