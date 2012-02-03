//
//  BJScene.mm
//  Bunjee
//  Created by Luca Antiga on 8/21/09.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import "BJScene.h"
#import "BJDataDisplay.h"

#import "vtkRenderer.h"

NSInteger sortDataDisplay(id data1, id data2, void *context) {
	NSString* name1 = [data1 name];
	NSString* name2 = [data2 name];
	NSString* className1 = [data1 className];
	NSString* className2 = [data2 className];
	NSInteger classNameCompare = [className1 caseInsensitiveCompare:className2];
	if (classNameCompare == NSOrderedSame) {
		return [name1 caseInsensitiveCompare:name2];
	}
	return classNameCompare;
}

@implementation BJScene

@synthesize dataDisplayDictionary;
@synthesize displayStatusChangeNotificationsEnabled;
@synthesize name;
@synthesize displayPropertyList;
@synthesize displayEditorPropertyList;

- (id)init {
	self = [super init];
	if (self) {
		dataDisplayDictionary = [[NSMutableDictionary alloc] init];
		name = [[NSString alloc] init];
		displayStatusChangeNotificationsEnabled = YES;
		displayPropertyList = [[NSMutableDictionary alloc] init];
		displayEditorPropertyList = [[NSMutableDictionary alloc] init];
		[displayPropertyList setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"",@"Key",@"",@"Name",nil] forKey:@"ActiveImageData"];
		//[displayPropertyList setObject:@"" forKey:@"CurrentSceneTemplate"];
		[displayPropertyList setObject:@"" forKey:@"SceneTemplate"];
		[self addEditorPropertyWithName:@"ActiveImageData" type:@"dataname" label:@"Active image" group:@"" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																													[NSArray arrayWithObjects:@"Image",nil],@"DataTypes",nil]];
		[self addEditorPropertyWithName:@"SceneTemplate" type:@"scenetemplate" label:@"Scene template" group:@""];

	}
	return self;
}

- (void)finalize {
	[super finalize];
}

- (id)copyWithZone:(NSZone*)zone {
	BJScene* clone = [[BJScene allocWithZone:zone] init];
	for (id key in self->dataDisplayDictionary) {
		[clone setDataDisplayNoNotify:[[self dataDisplayForKey:key] copy] forKey:key];
	}
	[clone->displayPropertyList removeAllObjects];
	for (id key in self->displayPropertyList) {
		[clone->displayPropertyList setObject:[[self->displayPropertyList objectForKey:key] copy] forKey:key];
	}
	return clone;
}

- (void)copyFromScene:(BJScene*)theScene {
	BOOL sceneNotify = [self displayStatusChangeNotificationsEnabled];
	if (sceneNotify) {
		[self setDisplayStatusChangeNotificationsEnabled:NO];
	}
	[self removeAllDataDisplay];
	for (id key in [theScene dataDisplayDictionary]) {
		BJDataDisplay* theDataCopy = [[theScene dataDisplayForKey:key] copy];
		[self setDataDisplayNoNotify:theDataCopy forKey:key];
	}
	[self->displayPropertyList removeAllObjects];
	for (id key in theScene->displayPropertyList) {
		[self->displayPropertyList setObject:[[theScene->displayPropertyList objectForKey:key] copy] forKey:key];
	}	
	[self setDisplayStatusChangeNotificationsEnabled:sceneNotify];
	if (sceneNotify) {
		[self notifyDisplayStatusChange];
	}
}

- (NSUInteger)count {
	return [dataDisplayDictionary count];
}

- (void)applySceneTemplate:(BJScene*)sceneTemplate {
	if (sceneTemplate == nil) {
		return;
	}
	BOOL sceneNotify = [self displayStatusChangeNotificationsEnabled];
	if (sceneNotify) {
		[self setDisplayStatusChangeNotificationsEnabled:NO];
	}
	for (id sceneKey in [self allKeys]) {
		id templateKeys = [sceneTemplate keysForDataDisplayWithName:[[self dataDisplayForKey:sceneKey] name]];
		if (templateKeys != nil and [templateKeys count] > 0) {
			continue;
		}
		[[self dataDisplayForKey:sceneKey] setListed:NO];
		[[self dataDisplayForKey:sceneKey] setDisplayed:NO];
	}
	for (id templateKey in [sceneTemplate allKeys]) {
		id sceneKeys = [self keysForDataDisplayWithName:[[sceneTemplate dataDisplayForKey:templateKey] name]];
		if (sceneKeys == nil) {
			continue;
		}
		for (id sceneKey in sceneKeys) {
			id sceneDataDisplay = [self dataDisplayForKey:sceneKey];
			NSString* dataUniqueIdentifier = [sceneDataDisplay dataUniqueIdentifier];
			[[sceneTemplate dataDisplayForKey:templateKey] copyToClone:sceneDataDisplay];
			[sceneDataDisplay setDataUniqueIdentifier:dataUniqueIdentifier];
		}
	}
	NSString* templateActiveImageDataName = [sceneTemplate activeImageDataName];
	if  (templateActiveImageDataName != nil) {
		id activeImageDataKeys = [self keysForDataDisplayWithName:templateActiveImageDataName];
		if (activeImageDataKeys > 0) {
			[self setActiveImageDataKey:[activeImageDataKeys objectAtIndex:0]];
		}
	}
	[self setDisplayStatusChangeNotificationsEnabled:sceneNotify];
	if (sceneNotify) {
		[self notifyDisplayStatusChange];
	}
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self name],@"SceneName",nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SceneTemplateApplied" object:self userInfo:userInfo];
}

- (void)setName:(NSString*)theName {
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self name],@"OldName",theName,@"NewName",nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SceneNameChanging" object:self userInfo:userInfo];
	name = theName;
}

- (void)update {
	//[self setCurrentSceneTemplate:[self displayPropertyValueWithName:@"SceneTemplate"]];

	for (id key in dataDisplayDictionary) {
		[[dataDisplayDictionary objectForKey:key] update];
	}
}

// SAME IMPLEMENTATION AS BJDataDisplay - SHARE IT

- (void)addEditorPropertyWithName:(NSString*)theName type:(NSString*)type label:(NSString*)label group:(NSString*)group attributes:(NSDictionary*)attributes {
	NSMutableDictionary* propertyDict = [[NSMutableDictionary alloc] init];
	[propertyDict setObject:type forKey:@"Type"];
	[propertyDict setObject:label forKey:@"Label"];
	if (group != nil) {
		[propertyDict setObject:group forKey:@"Group"];
	}
	[propertyDict setObject:[NSNumber numberWithInt:[displayEditorPropertyList count]] forKey:@"Id"];
	[propertyDict addEntriesFromDictionary:attributes];
	[displayEditorPropertyList setObject:propertyDict forKey:theName];
}

- (void)addEditorPropertyWithName:(NSString*)theName type:(NSString*)type label:(NSString*)label group:(NSString*)group {
	[self addEditorPropertyWithName:theName type:type label:label group:group attributes:nil];
}

- (void)removeEditorPropertyWithName:(NSString*)theName {
	[displayEditorPropertyList removeObjectForKey:theName];
}

- (id)displayPropertyValueWithName:(NSString*)theName {
	return [displayPropertyList objectForKey:theName];
}

- (void)setDisplayPropertyValue:(id)value withName:(NSString*)theName {
	[self setDisplayPropertyValue:value withName:theName update:YES];
}

- (void)removeDisplayPropertyWithName:(NSString*)theName {
	[displayPropertyList removeObjectForKey:theName];
}

- (void)setDisplayPropertyValue:(id)value withName:(NSString*)theName update:(BOOL)updateFlag {
	if (value == nil) {
		[displayPropertyList setObject:@"" forKey:theName];
	}
	else {
		[displayPropertyList setObject:value forKey:theName];
	}
	if (updateFlag == YES) {
		[self update];
	}
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:theName forKey:@"Name"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DisplayPropertyChanged" object:self userInfo:userInfo];
}

// UNTIL HERE

- (NSArray*)keysForDataDisplayWithDataUniqueIdentifier:(NSString*)uniqueIdentifier {
	NSMutableArray* keys = [[NSMutableArray alloc] init];
	for (id key in dataDisplayDictionary) {
		id dataDisplay = [dataDisplayDictionary objectForKey:key];
		if ([[dataDisplay dataUniqueIdentifier] isEqualToString:uniqueIdentifier] == YES) {
			[keys addObject:key];
		}
	}
	if ([keys count] == 0) {
		return nil;
	}
	return keys;
}

- (void)setDataDisplay:(BJDataDisplay*)theDataDisplay forKey:(NSString*)theKey {
	[self setDataDisplayNoNotify:theDataDisplay forKey:theKey];
	[self notifyDataDisplayChange];
}

- (void)setDataDisplayNoNotify:(BJDataDisplay*)theDataDisplay forKey:(NSString*)theKey {
	if ([dataDisplayDictionary objectForKey:theKey] != nil) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DataDisplayBeingRemoved" object:[dataDisplayDictionary objectForKey:theKey]];
	}
	[dataDisplayDictionary setObject:theDataDisplay forKey:theKey];
	if ([theDataDisplay dataObject] and ([theDataDisplay name] == nil or [[theDataDisplay name] isEqualToString:@""] == YES)) {
		[theDataDisplay setName:[[theDataDisplay dataObject] name]];
	}
	else {
		//[theDataDisplay setName:[theDataDisplay name]];
	}
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataDisplayHasBeenUpdated:) name:@"DataDisplayUpdated" object:theDataDisplay];
}

- (void)dataDisplayHasBeenUpdated:(NSNotification *)notification {
	[self notifyDataDisplayChange];
}

- (id)dataDisplayForKey:(NSString*)theKey {
	return [dataDisplayDictionary objectForKey:theKey];
}

- (NSArray*)keysForDataDisplayWithName:(NSString*)dataDisplayName {
	NSMutableArray* keys = [[NSMutableArray alloc] init];
	for (id key in dataDisplayDictionary) {
		id dataDisplay = [dataDisplayDictionary objectForKey:key];
		if ([[dataDisplay name] isEqualToString:dataDisplayName] == YES) {
			[keys addObject:key];
		}
	}
	return keys;	
}

- (NSArray*)keysForDataDisplayWithDataName:(NSString*)dataName {
	NSMutableArray* keys = [[NSMutableArray alloc] init];
	for (id key in dataDisplayDictionary) {
		id dataDisplay = [dataDisplayDictionary objectForKey:key];
		if ([[[dataDisplay dataObject] name] isEqualToString:dataName] == YES) {
			[keys addObject:key];
		}
	}
	return keys;
}

- (BOOL)dataDisplayedForKey:(NSString*)theKey {
	return [[dataDisplayDictionary objectForKey:theKey] displayed];
}

- (void)setDataDisplayed:(BOOL)displayed forKey:(NSString*)theKey {
	[[dataDisplayDictionary objectForKey:theKey] setDisplayed:displayed];
}

- (void)removeDataDisplayForKey:(NSString*)theKey {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DataDisplayBeingRemoved" object:[dataDisplayDictionary objectForKey:theKey]];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"DataDisplayUpdated" object:[dataDisplayDictionary objectForKey:theKey]];	
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"ActiveImageDataChanged" object:[dataDisplayDictionary objectForKey:theKey]];	
	[dataDisplayDictionary removeObjectForKey:theKey];
	[self notifyDataDisplayChange];
}

- (void)removeDataDisplay:(BJDataDisplay*)theDataDisplay {
	NSArray* keys = [dataDisplayDictionary allKeys];
	for (id key in keys) {
		if ([self dataDisplayForKey:key] == theDataDisplay) {
			[self removeDataDisplayForKey:key];
		}
	}
}

- (void)removeAllDataDisplay {
	[self disable];
	for (id key in dataDisplayDictionary) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DataDisplayBeingRemoved" object:[dataDisplayDictionary objectForKey:key]];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"DataDisplayUpdated" object:[dataDisplayDictionary objectForKey:key]];	
//		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"ActiveImageDataChanged" object:[dataDisplayDictionary objectForKey:key]];	
	}
	[dataDisplayDictionary removeAllObjects];
	[self notifyDataDisplayChange];
}

- (void)disable {
	for (id key in dataDisplayDictionary) {
		[[dataDisplayDictionary objectForKey:key] setDisplayed:NO];
	}
	if ([self displayStatusChangeNotificationsEnabled]) {
		//TODO: should the DataDisplay objects themselves do it?
		[self notifyDisplayStatusChange];
	}
}

- (void)notifyDataDisplayChange {
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self, @"Scene", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SceneDataDisplayChanged" object:self userInfo:userInfo];
	if ([self displayStatusChangeNotificationsEnabled]) {
		[self notifyDisplayStatusChange];
	}
}

- (void)notifyDisplayStatusChange {
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self, @"Scene", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SceneDataDisplayStatusChanged" object:self userInfo:userInfo];
}

- (void)setActiveImageDataKey:(NSString*)theActiveImageDataKey {
	if ([self activeImageDataKey] and [theActiveImageDataKey isEqualToString:[self activeImageDataKey]] == YES) {
		return;
	}

	if (theActiveImageDataKey) {
		[self setDisplayPropertyValue:[NSDictionary dictionaryWithObjectsAndKeys:theActiveImageDataKey,@"Key",[[self dataDisplayForKey:theActiveImageDataKey] name],@"Name",nil] withName:@"ActiveImageData"];
	}
	else {
		[self setDisplayPropertyValue:[NSDictionary dictionaryWithObjectsAndKeys:@"",@"Key",@"",@"Name",nil] withName:@"ActiveImageData"];
	}

//	if ([self displayStatusChangeNotificationsEnabled]) {
//		[self notifyDisplayStatusChange];
//	}
}

- (NSString*)activeImageDataKey {
	id key = [[self displayPropertyValueWithName:@"ActiveImageData"] objectForKey:@"Key"];
	if ([key isEqualToString:@""] == YES) {
		return nil;
	}
	return key;
}

- (NSString*)activeImageDataName {
	id theName = [[self displayPropertyValueWithName:@"ActiveImageData"] objectForKey:@"Name"];
	if ([theName isEqualToString:@""] == YES) {
		return nil;
	}
	return theName;
}

/*
- (void)setCurrentSceneTemplate:(NSString*)sceneTemplate {
	if ([sceneTemplate isEqualToString:[self displayPropertyValueWithName:@"CurrentSceneTemplate"]] == YES) {
		return;
	}
	[self setDisplayPropertyValue:sceneTemplate withName:@"CurrentSceneTemplate"];
}

- (NSString*)currentSceneTemplate {
	return [self displayPropertyValueWithName:@"CurrentSceneTemplate"];
}
*/
- (id)activeImageDataDisplay {
	if ([self dataDisplayForKey:[self activeImageDataKey]] == nil) {
		return nil;
	}
	return [self dataDisplayForKey:[self activeImageDataKey]];
}

- (id)activeImageData {
	return [[self activeImageDataDisplay] imageDataObject];
}

- (NSArray*)allListedKeysWithType:(NSString*)dataType {
	NSArray* keys = [self allListedKeys];
	NSMutableArray* keysWithType = [[NSMutableArray alloc] init];
	for (id key in keys) {
		if ([[[self dataDisplayForKey:key] dataTypeName] isEqualToString:dataType] == NO) {
			continue;
		}
		[keysWithType addObject:key];
	}
	return keysWithType;
}

- (NSArray*)allListedKeys {
	NSMutableArray* listedDataDisplay = [[NSMutableArray alloc] init];
	for (id key in dataDisplayDictionary) {
		id dataDisplay = [self dataDisplayForKey:key];
		if ([dataDisplay listed] == YES) {
			[listedDataDisplay addObject:dataDisplay];
		}
	}
	NSArray* sortedListedDataDisplay = [listedDataDisplay sortedArrayUsingFunction:sortDataDisplay context:NULL];
	NSMutableArray* sortedListedKeys = [[NSMutableArray alloc] init];
	for (id dataDisplay in sortedListedDataDisplay) {
		[sortedListedKeys addObject:[dataDisplay dataUniqueIdentifier]];
	}
	return sortedListedKeys;
}

- (NSArray*)allKeys {
	return [dataDisplayDictionary allKeys];
}
			
- (NSString*)listedKeyWithIndex:(NSInteger)index {
	return [[self allListedKeys] objectAtIndex:index];
}

- (NSString*)listedKeyWithIndex:(NSInteger)index withType:(NSString*)dataType {
	return [[self allListedKeysWithType:dataType] objectAtIndex:index];
}

- (NSInteger)numberOfListedKeys {
	return [[self allListedKeys] count];
}

- (NSInteger)numberOfListedKeysWithType:(NSString*)dataType {
	return [[self allListedKeysWithType:dataType] count];	
}

- (NSArray*)listedDataTypeNames {
	NSMutableSet* typeSet = [[NSMutableSet alloc] init];
	NSArray* listedKeys = [self allListedKeys];
	for (id key in listedKeys) {
		[typeSet addObject:[[self dataDisplayForKey:key] dataTypeName]];
	}
	return [typeSet allObjects];
}

//TODO: add possibility of storing relative paths to case files
- (NSDictionary*)scenePropertyList {
	NSMutableDictionary* scenePropertyList = [[NSMutableDictionary alloc] init];
	[scenePropertyList setObject:name forKey:@"Name"];
	[scenePropertyList setObject:displayPropertyList forKey:@"DisplayPropertyList"];
	[scenePropertyList setObject:[NSNumber numberWithBool:displayStatusChangeNotificationsEnabled] forKey:@"DisplayStatusChangeNotificationsEnabled"];
	NSMutableDictionary* dataDisplayPropertyList = [[NSMutableDictionary alloc] init];
	for (id key in dataDisplayDictionary) {
		[dataDisplayPropertyList setObject:[[NSDictionary alloc]
									initWithObjectsAndKeys:
									[[self dataDisplayForKey:key] className],@"ClassName",
									[[self dataDisplayForKey:key] displayPropertyList],@"DisplayPropertyList", nil] forKey:key];
	}
	[scenePropertyList setObject:dataDisplayPropertyList forKey:@"DataDisplayDictionary"];
	return scenePropertyList;
}

- (BOOL)writeToPListWithPath:(NSString*)plistPath {
	return [[self scenePropertyList] writeToFile:plistPath atomically:YES];
}

- (BOOL)readFromPListWithPath:(NSString*)plistPath {
	NSDictionary* propertyList = [NSDictionary dictionaryWithContentsOfFile:plistPath];
	if (propertyList == nil) {
		return NO;
	}
	[self setName:[propertyList objectForKey:@"Name"]];
	[displayPropertyList addEntriesFromDictionary:[propertyList objectForKey:@"DisplayPropertyList"]];
	[self setDisplayStatusChangeNotificationsEnabled:[[propertyList objectForKey:@"DisplayStatusChangeNotificationsEnabled"] boolValue]];
	NSDictionary* dataDisplayPropertyList = [propertyList objectForKey:@"DataDisplayDictionary"];
	for (id key in dataDisplayPropertyList) {
		NSDictionary* dict = [dataDisplayPropertyList objectForKey:key];
		NSString* className = [dict objectForKey:@"ClassName"];
		NSDictionary* dataDisplayPropertyList = [dict objectForKey:@"DisplayPropertyList"];
		NSString* dataUniqueIdentifier = [dataDisplayPropertyList objectForKey:@"DataUniqueIdentifier"];
		BJDataDisplay* dataDisplayObject = [[NSClassFromString(className) alloc] initWithDataObjectUniqueIdentifier:dataUniqueIdentifier];
		if (dataDisplayObject == nil) {
			continue;
		}
		[[dataDisplayObject displayPropertyList] addEntriesFromDictionary:dataDisplayPropertyList];
		[self setDataDisplayNoNotify:dataDisplayObject forKey:key];
	}
	return YES;
}

+ (id)sceneFromPListWithPath:(NSString*)plistPath {
	BJScene* scene = [[BJScene alloc] init];
	BOOL success = [scene readFromPListWithPath:plistPath];
	if (success == NO) {
		return nil;
	}
	return scene;
}

@end
