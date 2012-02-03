//
//  BJWorkspaceController.mm
//  Bunjee
//
//  Created by Luca Antiga on 5/11/11.
//  Copyright 2011 Orobix Srl. All rights reserved.
//

#import "BJWorkspaceController.h"
#import "BJWorkspace.h"
#import "BJCase.h"
#import "BJData.h"
#import "BJScene.h"
#import "BJDataDisplay.h"


@implementation BJSaveAsAccessoryViewController

@synthesize shouldSaveSceneAsTemplate;

- (id)init {
	self = [self initWithNibName:@"WorkspaceSaveSceneAsAccessoryView" bundle:[NSBundle bundleWithIdentifier:@"com.orobix.BunjeeKit"]];
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		shouldSaveSceneAsTemplate = NO;
	}
	return self;
}

@end


@implementation BJWorkspaceController

@synthesize workspace;

- (id)init {
	self = [super init];
	if (self) {
		workspace = [[BJWorkspace alloc] init];
	}
	
	return self;	
}

- (void)newCase {
	//TODO: check if name exists
	NSString* caseName = [workspace newCaseName];
	[workspace newCaseWithName:caseName];
	
	NSString* sceneName = [caseName copy];
	[workspace newSceneWithName:sceneName];
}

- (void)newCaseFromImage {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];
	
	//	if ([openPanel runModalForDirectory:nil file:nil types:[NSArray arrayWithObject:@"mha"]] != NSOKButton) {
	if ([openPanel runModalForDirectory:nil file:nil types:nil] != NSOKButton) {
        return;
    }	
	
	NSString *filename = [[openPanel filenames] objectAtIndex:0];
	
	NSString* caseName = [[filename lastPathComponent] stringByDeletingPathExtension];
	BJCase* theCase = [workspace newCaseWithName:caseName];
	
	NSString* sceneName = [caseName copy];
	BJScene* scene = [workspace newSceneWithName:sceneName];
	
	NSString* name = [theCase uniqueDataNameWithBaseName:@"Image"];
	id imageData = [[BJImageData alloc] init];
	[imageData readDataInAxialOrientationFromPath:filename];
	[theCase setData:imageData forName:name];
	
	[scene setDataDisplay:[imageData createDisplayObject] forKey:[imageData uniqueIdentifier]];
	[scene setActiveImageDataKey:[imageData uniqueIdentifier]];
	
	//	for (id sceneViewPanelController in sceneViewPanelControllers) {
	//		if ([sceneViewPanelController scene] == nil) {
	//			[sceneViewPanelController setScene:scene];
	//		}
	//	}
}

- (void)newCaseFromImageWithData:(NSData*)volumeData info:(NSDictionary*)info {
	NSString* caseName = [info objectForKey:@"PatientName"];
	BJCase* theCase = [workspace newCaseWithName:caseName];
	NSLog(@"%@",info);
	[theCase setMetaDataPropertyValue:[info objectForKey:@"PatientName"] withName:@"PatientName"];
	[theCase setMetaDataPropertyValue:[info objectForKey:@"PatientUID"] withName:@"PatientUID"];
	[theCase setMetaDataPropertyValue:[info objectForKey:@"PatientID"] withName:@"PatientID"];
	[theCase setMetaDataPropertyValue:[info objectForKey:@"StudyUID"] withName:@"StudyUID"];
	[theCase setMetaDataPropertyValue:[info objectForKey:@"StudyName"] withName:@"StudyName"];
	[theCase setMetaDataPropertyValue:[info objectForKey:@"SeriesInstanceUID"] withName:@"SeriesInstanceUID"];
	[theCase setMetaDataPropertyValue:[info objectForKey:@"SeriesDescription"] withName:@"SeriesDescription"];
	
	NSString* sceneName = [caseName copy];
	BJScene* scene = [workspace newSceneWithName:sceneName];
	
	NSString* name = [theCase uniqueDataNameWithBaseName:@"Image"];
	id imageData = [[BJImageData alloc] init];
	[imageData importVolumeData:volumeData info:info];
	[theCase setData:imageData forName:name];
	
	[scene setDataDisplay:[imageData createDisplayObject] forKey:[imageData uniqueIdentifier]];
	[scene setActiveImageDataKey:[imageData uniqueIdentifier]];	
}

- (void)openCase {
	NSOpenPanel *openPanel;
	
    openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setResolvesAliases:YES];
    [openPanel setCanChooseFiles:YES];
	
    NSArray *fileTypes = [NSArray arrayWithObjects: @"bunjee", nil];
    
    if ([openPanel runModalForTypes:fileTypes] != NSOKButton) {
        return;
    }

	[self openCaseFromPath:[openPanel filename]];
}

- (void)openCaseFromPath:(NSString*)casePath {
	BJCase* theCase = [BJCase caseFromPackageWithPath:casePath];
	
	[workspace addCase:theCase withName:[theCase name]];
	[theCase notifyDataChange];
	
	NSArray* scenePaths = [theCase pathsOfScenesInPackage:casePath];
	for (id scenePath in scenePaths) {
		BJScene* scene = [BJScene sceneFromPListWithPath:scenePath];
		if (scene == nil) {
			continue;
		}
		//TODO: the binding shouldn't be here, it should be somewhere where it can be done every time a new case is loaded. Or not?
		for (id key in [scene dataDisplayDictionary]) {
			id dataDisplayObject = [scene dataDisplayForKey:key];
			id dataObject = [theCase dataForUniqueIdentifier:[dataDisplayObject dataUniqueIdentifier]];
			if (dataObject) {
				[dataDisplayObject bindToDataObject:dataObject];
			}
		}
		[workspace addScene:scene withName:[scene name]];
		[scene notifyDataDisplayChange];
	}
}

- (void)saveCaseAs:(id)theCase {
	
	if (theCase == nil) {
		return;
	}
	
	NSSavePanel* savePanel = [NSSavePanel savePanel];
    [savePanel setCanCreateDirectories:YES];
	[savePanel setRequiredFileType:@"bunjee"];
	
	//TODO: make this a setting in Preferences
	//NSString* basePath = [NSString pathWithComponents: [NSArray arrayWithObjects:NSHomeDirectory(), @"Documents", @"BJ", nil]];
	
    if ([savePanel runModal] != NSOKButton) {
        return;
    }
	
	NSString* packagePath = [savePanel filename];

	[self saveCase:theCase toPath:packagePath];
}

- (void)saveCase:(id)theCase {
	
	if (theCase == nil) {
		return;
	}
	
	NSString* directory = [theCase name];
	NSString* basePath = [[NSUserDefaults standardUserDefaults] stringForKey:@"DataPath"];
	NSString* packagePath = [[NSString pathWithComponents: [NSArray arrayWithObjects:basePath, directory, nil]] stringByAppendingPathExtension:@"bunjee"];
	
	[self saveCase:theCase toPath:packagePath];
}

- (void)saveCase:(id)theCase toPath:(NSString*)packagePath {
	
    if([[NSFileManager defaultManager] fileExistsAtPath:packagePath]) {
		NSString* savePrompt = [NSString stringWithFormat:@"Saving case %@ will overwrite the existing saved case. Continue?",[theCase name]];
		NSInteger alertReturn = NSRunAlertPanel(@"Save",savePrompt,@"OK",@"Cancel",nil);
		if (alertReturn == NSAlertAlternateReturn) {
			return;
		}
		[[NSFileManager defaultManager] removeItemAtPath:packagePath error:NULL];
	}

	NSArray* sceneNamesToWrite = [workspace sceneNamesWithDataFromCase:[theCase name]];
	NSMutableArray* scenesToWrite = [[NSMutableArray alloc] init];
	for (id sceneName in sceneNamesToWrite) {
		id sceneToWrite = [workspace sceneWithName:sceneName];
		if (sceneToWrite == nil) {
			continue;
		}
		[scenesToWrite addObject:sceneToWrite];
	}
	
	[theCase writeToPackageWithPath:packagePath andScenes:scenesToWrite];
}

- (void)closeCase:(id)theCase {
	if (theCase == nil) {
		return;
	}
	[workspace removeCaseWithName:[theCase name]];
}

- (void)removeItem:(id)item fromCase:(id)theCase {
	if (theCase == nil || item == nil) {
		return;
	}
	[theCase removeDataForName:[item name] folder:[item folder]];
}

- (void)removeAllItemsFromCase:(id)theCase {
	if (theCase == nil) {
		return;
	}
	[theCase removeAllData];
}


- (void)addImageToCase:(id)theCase {
	
	if (theCase == nil) {
		return;
	}
	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];
	
	if ([openPanel runModalForDirectory:nil file:nil types:nil] != NSOKButton) {
        return;
    }	
	
	NSString *filename = [[openPanel filenames] objectAtIndex:0];
	
	NSString* name = [theCase uniqueDataNameWithBaseName:@"Image"];
	[theCase setData:[[BJImageData alloc] init] forName:name];
	[[theCase dataForName:name] readDataInAxialOrientationFromPath:filename];
	
	//TODO: scene here hasn't rightfully been created so far. However, the fact that we load an
	//image and the image is not displayed unless we drag it from the case to the scene
	//is not intuitive at all. We need a way of defaulting. Probably, by convention,
	//if a scene has the same key as the case, that's were this kind of things happen.
	//That's what we're doing here.
	//This is also how we can fall back to the previous model where there is only one
	//scene per case: hide the case and fake the fact that the data is in the scene.
	
	//In perspective, this will be handled by scene templates: scene templates are loaded
	//at startup time, and as soon as a case has all the components needed for a scene template,
	//the scene template is created. This could actually be an automated mechanism to put in
	//place everytime a case data is added to the case.
	
	BJScene* scene = [[workspace scenes] objectForKey:[theCase name]];
	if (scene) {
		[scene setDataDisplay:[theCase createDisplayObjectForName:name] forKey:[[theCase dataForName:name] uniqueIdentifier]];
		[scene setActiveImageDataKey:[[theCase dataForName:name] uniqueIdentifier]];
	}
}

- (void)addSurfaceToCase:(id)theCase {
	[self addDataToCase:theCase withClassName:@"BJPolyData" fileTypes:[NSArray arrayWithObject:@"vtp"] dataBaseName:@"Surface"];
/*	
	if (theCase == nil) {
		return;
	}
	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];
	
	if ([openPanel runModalForDirectory:nil file:nil types:[NSArray arrayWithObject:@"vtp"]] != NSOKButton) {
        return;
    }	
	
	NSString *filename = [[openPanel filenames] objectAtIndex:0];
	
	NSString* name = [theCase uniqueDataNameWithBaseName:@"Surface"];
	[theCase setData:[[BJPolyData alloc] init] forName:name];
	[[theCase dataForName:name] readDataFromPath:filename];
	
	//TODO: scene here hasn't rightfully been created so far. However, the fact that we load an
	//image and the image is not displayed unless we drag it from the case to the scene
	//is not intuitive at all. We need a way of defaulting. Probably, by convention,
	//if a scene has the same key as the case, that's were this kind of things happen.
	//That's what we're doing here.
	//This is also how we can fall back to the previous model where there is only one
	//scene per case: hide the case and fake the fact that the data is in the scene.
	
	BJScene* scene = [[workspace scenes] objectForKey:[theCase name]];
	if (scene) {
		[scene setDataDisplay:[theCase createDisplayObjectForName:name] forKey:[[theCase dataForName:name] uniqueIdentifier]];
	}
*/
}

- (void)addDataToCase:(id)theCase withClassName:(NSString*)className fileTypes:(NSArray*)fileTypes dataBaseName:(NSString*)dataBaseName {
	if (theCase == nil) {
		return;
	}
	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];
	
	if ([openPanel runModalForDirectory:nil file:nil types:fileTypes] != NSOKButton) {
        return;
    }	
	
	NSString *filename = [[openPanel filenames] objectAtIndex:0];
	
	NSString* name = [theCase uniqueDataNameWithBaseName:dataBaseName];
	[theCase setData:[[NSClassFromString(className) alloc] init] forName:name];
	[[theCase dataForName:name] readDataFromPath:filename];
	
	BJScene* scene = [[workspace scenes] objectForKey:[theCase name]];
	if (scene) {
		[scene setDataDisplay:[theCase createDisplayObjectForName:name] forKey:[[theCase dataForName:name] uniqueIdentifier]];
	}
}

- (void)newScene {
	NSString* sceneName = [workspace newSceneName];
	[workspace newSceneWithName:sceneName];
}

- (void)openScene {
	
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setResolvesAliases:YES];
    [openPanel setCanChooseFiles:YES];
	
    NSArray *fileTypes = [NSArray arrayWithObjects: @"bunjeescene", nil];
    
    if ([openPanel runModalForTypes:fileTypes] != NSOKButton) {
        return;
    }
	
	BJScene* scene = [BJScene sceneFromPListWithPath:[openPanel filename]];
	
	if (scene == nil) {
		return;
	}
	
	[workspace addScene:scene withName:[scene name]];
}

- (void)saveScene:(id)scene {

	if (scene == nil) {
		return;
	}
	
	NSString* basePath = [[NSUserDefaults standardUserDefaults] stringForKey:@"DataPath"];

	//NSString* basePath = [NSString pathWithComponents: [NSArray arrayWithObjects:NSHomeDirectory(), @"Documents", @"Bunjee", nil]];
	NSString* scenePListPath = [[NSString pathWithComponents: [NSArray arrayWithObjects:basePath, [scene name], nil]] stringByAppendingPathExtension:@"bunjeescene"];
	[scene writeToPListWithPath:scenePListPath];
}

- (void)saveSceneAs:(id)scene {

	if (scene == nil) {
		return;
	}	
	
	BJSaveAsAccessoryViewController* saveAsAccessoryViewController = [[BJSaveAsAccessoryViewController alloc] init];

	NSSavePanel* savePanel = [NSSavePanel savePanel];
    [savePanel setCanCreateDirectories:YES];
	[savePanel setRequiredFileType:@"bunjeescene"];
	[savePanel setAccessoryView:[saveAsAccessoryViewController view]];
	[savePanel setNameFieldStringValue:[[scene name] stringByAppendingPathExtension:@"bunjeescene"]];
	
	//TODO: make this a setting in Preferences
	//NSString* basePath = [NSString pathWithComponents: [NSArray arrayWithObjects:NSHomeDirectory(), @"Documents", @"BJ", nil]];
	
    //if ([savePanel runModalForDirectory:basePath file:@""] != NSOKButton) {
    if ([savePanel runModal] != NSOKButton) {
        return;
    }
	
	NSString* scenePListPath = [savePanel filename];	
	
	if ([saveAsAccessoryViewController shouldSaveSceneAsTemplate] == NO) {
		[scene writeToPListWithPath:scenePListPath];
	}
	else {
		//TODO: make this a setting in Preferences
		//TODO: warn if file exist. For this it might be good to change the savePanel URL as soon as the scene template checkbox is toggled.
		NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
		NSString* sceneTemplatesPath = [NSString pathWithComponents:[NSArray arrayWithObjects:[userDefaults stringForKey:@"DataPath"],@"SceneTemplates",nil]];
		[scene writeToPListWithPath:[NSString pathWithComponents: [NSArray arrayWithObjects:sceneTemplatesPath, [scenePListPath lastPathComponent], nil]]];
	}
}

- (void)closeScene:(id)scene {

	if (scene == nil) {
		return;
	}
	[workspace removeSceneWithName:[scene name]];
}

- (void)removeItem:(id)sceneItem fromScene:(id)scene {
	if (scene == nil || sceneItem == nil) {
		return;
	}
	if ([sceneItem dataObject] != nil) {
		[scene removeDataDisplayForKey:[[sceneItem dataObject] uniqueIdentifier]];
	}
	else {
		[scene removeDataDisplay:sceneItem];
	}
}

- (void)removeAllItemsFromScene:(id)scene {
	if (scene == nil) {
		return;
	}
	[scene removeAllDataDisplay];
}

- (void)closeAllCasesAndScenes {
	[workspace removeAllCasesAndScenes];
}

- (void)openStudyInOsiriX:(id)theCase {
	NSString* studyUID = [theCase metaDataPropertyValueWithName:@"StudyUID"];
	[self openStudyInOsiriXWithUID:studyUID];
}

- (void)openStudyInOsiriXWithUID:(NSString*)studyUID {
	NSArray* apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.rossetantoine.osirix"];
	
	BOOL launchResult = NO;
	if ([apps count] == 0) {
		launchResult = [[NSWorkspace sharedWorkspace] launchApplication:@"OsiriX"];
	}
	else {
		[(NSRunningApplication*)[apps objectAtIndex:0] activateWithOptions:NSApplicationActivateAllWindows];
	}
	
	NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"osirix://?methodName=DisplayStudy&StudyInstanceUID=%@",studyUID]];
	[[NSWorkspace sharedWorkspace] openURL:url];	
}

- (void)exportDBData:(NSArray*)columnProperties {
	[self exportDBData:columnProperties withDefaultFileName:@"DBData"];
}

- (void)exportDBData:(NSArray*)columnProperties withDefaultFileName:(NSString*)defaultFileName {
	NSSavePanel* savePanel = [NSSavePanel savePanel];
    [savePanel setCanCreateDirectories:YES];
	[savePanel setExtensionHidden:NO];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObjects:@"csv",@"txt",nil]];
	[savePanel setNameFieldStringValue:[[NSString stringWithString:defaultFileName] stringByAppendingPathExtension:@"csv"]];
	
	if ([savePanel runModal] != NSOKButton) {
        return;
    }
	
	NSArray* dbData = [self collectDBData:columnProperties];
	
	NSString* outputFormattedData = [dbData componentsJoinedByString:@"\n"];
	
	NSError* error = nil;
	[outputFormattedData writeToFile:[savePanel filename] atomically:NO encoding:NSUTF8StringEncoding error:&error];	
}

- (NSArray*)collectDBData:(NSArray*)columnProperties{
	
	NSMutableArray* dbData = [[NSMutableArray alloc] init];
	
	NSMutableArray* row = [[NSMutableArray alloc] init];

	for (id prop in columnProperties) {
		[row addObject:[prop objectForKey:@"Name"]];
	}
	
	[dbData addObject:[row componentsJoinedByString:@"\t"]];
	
	NSArray* allCasesPropertyList = [[self workspace] allCasesPropertyList];
	
	for (id casePropertyList in allCasesPropertyList) {
		[row removeAllObjects];
		for (id prop in columnProperties) {
			id entry = [casePropertyList valueForKeyPath:[prop objectForKey:@"KeyPath"]];
			if (entry != nil) {
				[row addObject:entry];
			}
			else {
				[row addObject:@""];
			}
		}
		[dbData addObject:[row componentsJoinedByString:@"\t"]];
	}
	
	return dbData;
}

@end
