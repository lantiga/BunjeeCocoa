//
//  BJWorkspace.h
//  Bunjee
//  Created by Luca Antiga on 5/7/10.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BJCase;
@class BJScene;
@class BJData;
@class BJDataDisplay;

@interface BJWorkspace : NSObject {
	NSMutableDictionary* cases;
	NSMutableDictionary* scenes;
	
	NSString* activeSceneName;
}

@property(readonly) NSMutableDictionary* cases;
@property(readonly) NSMutableDictionary* scenes;
@property(readwrite,copy) NSString* activeSceneName;

- (NSString*)appendUniqueSuffixToName:(NSString*)name;
- (NSString*)newCaseName;
- (NSString*)newSceneName;

- (id)activeScene;

- (NSArray*)caseNames;
- (NSArray*)sceneNames;
- (NSArray*)sceneTemplateNames;

- (NSArray*)sortedCaseNames;
- (NSArray*)sortedSceneNames;
- (NSArray*)sortedSceneTemplateNames;

- (BJCase*)newCaseWithName:(NSString*)caseName;
- (BJScene*)newSceneWithName:(NSString*)sceneName;

- (void)addCase:(BJCase*)theCase withName:(NSString*)caseName;
- (void)addScene:(BJScene*)theScene withName:(NSString*)sceneName;
//- (void)addSceneTemplate:(BJScene*)theSceneTemplate withName:(NSString*)sceneTemplateName;

- (BJCase*)caseWithName:(NSString*)caseName;
- (BJScene*)sceneWithName:(NSString*)sceneName;
- (BJScene*)sceneTemplateWithName:(NSString*)sceneTemplateName;

- (void)removeCaseWithName:(NSString*)caseName;
- (void)removeSceneWithName:(NSString*)sceneName;
//- (void)removeSceneTemplateWithName:(NSString*)sceneName;

- (void)removeAllCasesAndScenes;

- (BJData*)dataForUniqueIdentifier:(NSString*)uniqueIdentifier;

- (id)caseForData:(BJData*)theData;
- (id)caseForDataWithUniqueIdentifier:(NSString*)uniqueIdentifier;
- (id)sceneForDataDisplay:(BJDataDisplay*)theDataDisplay;
- (NSArray*)dataDisplaysForData:(BJData*)theData;

- (void)caseHasBeenRenamed:(NSNotification*)notification;
- (void)sceneHasBeenRenamed:(NSNotification*)notification;

- (void)caseHasBeenRemoved:(NSNotification*)notification;
- (void)sceneHasBeenRemoved:(NSNotification*)notification;

- (NSArray*)caseFolderAndNameFromPath:(NSString*)path;
- (NSString*)pathWithoutRoot:(NSString*)path;

- (NSArray*)allCasesPropertyList;

- (NSArray*)sceneNamesWithDataFromCase:(id)theCase;

@end
