//
//  BJWorkspace.m
//  Bunjee
//  Created by Luca Antiga on 5/7/10.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import "BJWorkspace.h"
#import "BJCase.h"
#import "BJScene.h"
#import "BJData.h"
#import "BJDataDisplay.h"

@implementation BJWorkspace

@synthesize scenes;
@synthesize cases;
@synthesize activeSceneName;

- (id)init {
	self = [super init];
	if (self) {
		srandom((int)[[NSDate date] timeIntervalSince1970]);
		scenes = [[NSMutableDictionary alloc] init];
		cases = [[NSMutableDictionary alloc] init];
		activeSceneName = [NSString string];
	}
	return self;
}

- (NSString*)appendUniqueSuffixToName:(NSString*)name {
	int suffix = 1;
	BOOL done = NO;
	NSString* currentName = name;
	while (!done) {
		if (suffix > 0) {
			currentName = [NSString stringWithFormat:@"%@ %d",name,suffix];
		}
		done = YES;
		for (id key in scenes) {
			if ([key isEqualToString:currentName] == YES) {
				suffix += 1;
				done = NO;
				break;
			}
		}
	}
	return currentName;	
}

- (NSArray*)caseNames {
	return [cases allKeys];
}

- (NSArray*)sceneNames {
	return [scenes allKeys];
}

- (id)activeScene {
	return [self sceneWithName:activeSceneName];
}

- (void)setActiveSceneName:(NSString*)sceneName {
	if ([sceneName isEqualToString:activeSceneName] == YES) {
		return;
	}
	if ([self sceneWithName:sceneName] == nil) {
		activeSceneName = @"";
		return;
	}
	activeSceneName = sceneName;
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self activeScene], @"Scene", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ActiveSceneChanged" object:self userInfo:userInfo];
}

- (NSArray*)sceneTemplateNames {
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	NSString* sceneTemplatesPath = [NSString pathWithComponents:[NSArray arrayWithObjects:[userDefaults stringForKey:@"DataPath"],@"SceneTemplates",nil]];
	NSArray* fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sceneTemplatesPath error:NULL];
	NSMutableArray* names = [[NSMutableArray alloc] init];
	for (id fileName in fileNames) {
		[names addObject:[fileName stringByDeletingPathExtension]];
	}
	return names;
}

- (NSArray*)sortedCaseNames {
	return [[self caseNames] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (NSArray*)sortedSceneNames {
	return [[self sceneNames] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (NSArray*)sortedSceneTemplateNames {
	return [[self sceneTemplateNames] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (NSString*)newCaseName {
	return [self appendUniqueSuffixToName:@"Case"];
}

- (NSString*)newSceneName {
	return [self appendUniqueSuffixToName:@"Scene"];
}

- (BJCase*)newCaseWithName:(NSString*)caseName {
	BJCase* theCase = [[BJCase alloc] init];
	[self addCase:theCase withName:caseName];
	return theCase;
}

- (void)addCase:(BJCase*)theCase withName:(NSString*)caseName {
	[cases setObject:theCase forKey:caseName];
	[theCase setName:caseName];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:theCase forKey:@"Case"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CaseHasBeenAdded" object:self userInfo:userInfo];
	//TODO: update all scenes and eventually call a display. Scenes that have data display that didn't find its unique identifier, they may find it again, so the view might need to be redisplayed.
}

- (BJCase*)caseWithName:(NSString*)caseName {
	return [cases objectForKey:caseName];
}

- (void)removeCaseWithName:(NSString*)caseName {
	for (id key in [[cases objectForKey:caseName] dataDictionary]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DataBeingRemoved" object:[[cases objectForKey:caseName] dataForKey:key]];
	}
	[cases removeObjectForKey:caseName];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:caseName forKey:@"CaseName"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CaseHasBeenRemoved" object:self userInfo:userInfo];
}

- (void)removeAllCasesAndScenes {
	id caseNames = [[cases allKeys] copy];
	id sceneNames = [[scenes allKeys] copy];
	for (id sceneName in sceneNames) {
		[self removeSceneWithName:sceneName];
	}
	for (id caseName in caseNames) {
		[self removeCaseWithName:caseName];
	}
}

- (BJScene*)newSceneWithName:(NSString*)sceneName {
	BJScene* scene = [[BJScene alloc] init];
	[self addScene:scene withName:sceneName];
	return scene;
}

- (void)addScene:(BJScene*)theScene withName:(NSString*)sceneName {
	[scenes setObject:theScene forKey:sceneName];
	[theScene setName:sceneName];
	for (id key in [theScene dataDisplayDictionary]) {
		id theDataDisplay = [theScene dataDisplayForKey:key];
		id theData = [self dataForUniqueIdentifier:[theDataDisplay dataUniqueIdentifier]];
		if (theData == nil) {
			continue;
		}
		[theDataDisplay bindToDataObject:theData];
	}
	[theScene update];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:theScene forKey:@"Scene"]; 
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SceneHasBeenAdded" object:self userInfo:userInfo];
}

//- (void)addSceneTemplate:(BJScene*)theSceneTemplate withName:(NSString*)sceneTemplateName {
//	[sceneTemplates setObject:theSceneTemplate forKey:sceneTemplateName];
//}

- (BJScene*)sceneWithName:(NSString*)sceneName {
	return [scenes objectForKey:sceneName];
}

- (BJScene*)sceneTemplateWithName:(NSString*)sceneTemplateName {
	if ([sceneTemplateName isEqualToString:@""] == YES) {
		return nil;
	}
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	NSString* sceneTemplatesPath = [NSString pathWithComponents:[NSArray arrayWithObjects:[userDefaults stringForKey:@"DataPath"],@"SceneTemplates",nil]];
	NSString* sceneFileName = [sceneTemplateName stringByAppendingPathExtension:@"bunjeescene"];
	return [BJScene sceneFromPListWithPath:[sceneTemplatesPath stringByAppendingPathComponent:sceneFileName]];
}

- (void)removeSceneWithName:(NSString*)sceneName {
	id theScene = [scenes objectForKey:sceneName];
//	for (id key in [theScene dataDisplayDictionary]) {
//		[[NSNotificationCenter defaultCenter] postNotificationName:@"DataDisplayBeingRemoved" object:[theScene dataDisplayForKey:key]];
//	}
//	[theScene removeAllDataDisplay];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:theScene forKey:@"Scene"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SceneIsBeingRemoved" object:self userInfo:userInfo];
	[scenes removeObjectForKey:sceneName];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SceneHasBeenRemoved" object:self];
}

//- (void)removeSceneTemplateWithName:(NSString*)sceneTemplateName {
//	[sceneTemplates removeObjectForKey:sceneTemplateName];
//}

- (BJData*)dataForUniqueIdentifier:(NSString*)uniqueIdentifier {
	for (id caseKey in cases) {
		id theData = [[cases objectForKey:caseKey] dataForUniqueIdentifier:uniqueIdentifier];
		if (theData) {
			return theData;
		}
	}
	return nil;
}

- (id)caseForData:(BJData*)theData {
	for (id caseKey in cases) {
		id currentCase = [cases objectForKey:caseKey];
		if ([currentCase dataForUniqueIdentifier:[theData uniqueIdentifier]] != nil) {
			return currentCase;
		}
	}
	return nil;
}

- (id)caseForDataWithUniqueIdentifier:(NSString*)uniqueIdentifier {
	for (id caseKey in cases) {
		id theData = [[cases objectForKey:caseKey] dataForUniqueIdentifier:uniqueIdentifier];
		if (theData) {
			return [cases objectForKey:caseKey];
		}
	}
	return nil;	
}

- (id)sceneForDataDisplay:(BJDataDisplay*)theDataDisplay {
	for (id sceneKey in scenes) {
		id currentScene = [scenes objectForKey:sceneKey];
		if ([currentScene dataDisplayForKey:[[theDataDisplay dataObject] uniqueIdentifier]] == theDataDisplay) {
			return currentScene;
		}
//		if ([currentScene dataDisplayForKey:[theDataDisplay name]] == theDataDisplay) {
//			return currentScene;
//		}
	}
	return nil;
}

- (NSArray*)dataDisplaysForData:(BJData*)theData {
	NSMutableArray* dataDisplays = [[NSMutableArray alloc] init];
	for (id sceneKey in scenes) {
		NSArray* sceneDataDisplays = [[scenes objectForKey:sceneKey] keysForDataDisplayWithDataUniqueIdentifier:[theData uniqueIdentifier]];
		for (id dataDisplay in sceneDataDisplays) {
			[dataDisplays addObject:dataDisplay];
		}
	}
	if ([dataDisplays count] == 0) {
		return nil;
	}
	return dataDisplays;
}

- (void)caseHasBeenRenamed:(NSNotification*)notification {
}

- (void)sceneHasBeenRenamed:(NSNotification*)notification {
}

- (void)caseHasBeenRemoved:(NSNotification*)notification {
}

- (void)sceneHasBeenRemoved:(NSNotification*)notification {
}

- (void)dataHasBeenAdded:(NSNotification*)notification {
}

- (void)dataHasBeenRenamed:(NSNotification*)notification {
}

- (void)dataHasBeenRemoved:(NSNotification*)notification {
}

- (NSString*)pathWithoutRoot:(NSString*)path {
	if ([path length] < 1) {
		return path;
	}
	if ([[path substringToIndex:1] isEqualToString:@"/"] == NO) {
		return path;
	}
	return [path substringFromIndex:1];
}

- (NSArray*)caseFolderAndNameFromPath:(NSString*)path {
	NSArray* fullSplitPath = [path componentsSeparatedByString:@"/"];
	NSArray* splitPath = [fullSplitPath subarrayWithRange:NSMakeRange(1,[fullSplitPath count]-1)];
	if ([splitPath count] == 0) {
		return [NSArray arrayWithObjects:[NSNull null],[NSNull null],[NSNull null],nil];
	}
	NSString* caseName = [splitPath objectAtIndex:0];
	if ([splitPath count] == 1) {
		return [NSArray arrayWithObjects:caseName,[NSNull null],[NSNull null],nil];
	}
	id theCase = [self caseWithName:caseName];
	NSArray* folderComponents = [splitPath subarrayWithRange:NSMakeRange(1,[splitPath count]-1)];
	NSString* folder = [theCase joinFolderComponents:folderComponents];
	NSArray* folderComponentsButLast = [folderComponents subarrayWithRange:NSMakeRange(0,[folderComponents count]-1)];
	NSString* lastFolderComponent = [folderComponents objectAtIndex:[folderComponents count]-1];
	NSString* folderButLast = [theCase joinFolderComponents:folderComponentsButLast];
	if ([theCase dataForName:lastFolderComponent folder:folderButLast] != nil) {
		return [NSArray arrayWithObjects:caseName,folderButLast,lastFolderComponent,nil];
	}
	return [NSArray arrayWithObjects:caseName,folder,[NSNull null],nil];	
}

- (NSArray*)allCasesPropertyList {
	NSString* dataPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"DataPath"];
	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSError* error;
	NSArray* dataPathContents = [fileManager contentsOfDirectoryAtPath:dataPath error:&error];

	NSMutableArray* plistFilePaths = [[NSMutableArray alloc] init];
	
	for (id entry in dataPathContents) {
		NSString* plistFilePath = [NSString pathWithComponents:[NSArray arrayWithObjects:dataPath,entry,@"Contents",@"Info.plist",nil]];
		if ([fileManager fileExistsAtPath:plistFilePath]) {
			[plistFilePaths addObject:plistFilePath];
		}
	}
	
	NSMutableArray* allCasesPropertyList = [[NSMutableArray alloc] init];
	
	for (id plistFilePath in plistFilePaths) {
		NSMutableDictionary* casePropertyList = [[NSMutableDictionary alloc] initWithContentsOfFile:plistFilePath];
		[casePropertyList setObject:[[plistFilePath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] forKey:@"CasePath"];
		[allCasesPropertyList addObject:casePropertyList];
	}
	
//	NSLog(@"%@",allCasesPropertyList);
	return allCasesPropertyList;
}

- (NSArray*)sceneNamesWithDataFromCase:(NSString*)caseName {
	
	BJCase* theCase = [self caseWithName:caseName];
	
	if (theCase == nil) {
		return [NSArray array];
	}
	
	NSMutableSet* uniqueIdentifiers = [[NSMutableSet alloc] init];
	
	for (id key in [theCase allListedKeys]) {
		[uniqueIdentifiers addObject:[[theCase dataForKey:key] uniqueIdentifier]];
	}
	
	NSMutableArray* linkedSceneNames = [[NSMutableArray alloc] init];
	
	for (id sceneName in [self sceneNames]) {
		id currentScene = [self sceneWithName:sceneName];
		for (id key in [currentScene allListedKeys]) {
			if ([uniqueIdentifiers containsObject:[[currentScene dataDisplayForKey:key] dataUniqueIdentifier]] == YES) {
				[linkedSceneNames addObject:sceneName];
				break;
			}
		}
	}
	
	return linkedSceneNames;
}

@end
