//
//  BJWorkspaceController.h
//  Bunjee
//
//  Created by Luca Antiga on 5/11/11.
//  Copyright 2011 Orobix Srl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BJWorkspace;

@interface BJSaveAsAccessoryViewController : NSViewController {
	BOOL shouldSaveSceneAsTemplate;
}

@property(readwrite) BOOL shouldSaveSceneAsTemplate;

@end;

@interface BJWorkspaceController : NSObject {
	BJWorkspace* workspace;
}

@property(readonly) BJWorkspace* workspace;

- (void)newCase;
- (void)newCaseFromImage;
- (void)newCaseFromImageWithData:(NSData*)volumeData info:(NSDictionary*)info;
- (void)addImageToCase:(id)theCase;
- (void)addSurfaceToCase:(id)theCase;
- (void)addDataToCase:(id)theCase withClassName:(NSString*)className fileTypes:(NSArray*)fileTypes dataBaseName:(NSString*)dataBaseName;
- (void)openCase;
- (void)openCaseFromPath:(NSString*)casePath;
- (void)saveCase:(id)theCase;
- (void)saveCaseAs:(id)theCase;
- (void)saveCase:(id)theCase toPath:(NSString*)packagePath;
- (void)closeCase:(id)theCase;
- (void)removeItem:(id)item fromCase:(id)theCase;
- (void)removeAllItemsFromCase:(id)theCase;

- (void)newScene;
- (void)openScene;
- (void)saveSceneAs:(id)theScene;
- (void)saveScene:(id)theScene;
- (void)closeScene:(id)theScene;
- (void)removeItem:(id)item fromScene:(id)theScene;
- (void)removeAllItemsFromScene:(id)theScene;

- (void)closeAllCasesAndScenes;

- (void)openStudyInOsiriX:(id)theCase;
- (void)openStudyInOsiriXWithUID:(NSString*)studyUID;

- (void)exportDBData:(NSArray*)columnProperties;
- (void)exportDBData:(NSArray*)columnProperties withDefaultFileName:(NSString*)defaultFileName;
- (NSArray*)collectDBData:(NSArray*)columnProperties;

@end
