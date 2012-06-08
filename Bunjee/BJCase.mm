//
//  BJCase.mm
//  Bunjee
//  Created by Luca Antiga on 2/15/10.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import "BJCase.h"
#import "BJData.h"
#import "BJScene.h"  // not strictly needed, here just to avoid warning

#import "vtkImageData.h"

NSInteger sortData(id data1, id data2, void *context) {
	BOOL isData1String = [data1 isKindOfClass:[NSString class]];
	BOOL isData2String = [data2 isKindOfClass:[NSString class]];
	if (isData1String == YES and isData2String == YES) {
		return [data1 caseInsensitiveCompare:data2];
	}
	if (isData1String == NO and isData2String == NO) {
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
	if (isData1String == YES and isData2String == NO) {
		return NSOrderedAscending;
	}
	if (isData1String == NO and isData2String == YES) {
		return NSOrderedDescending;
	}
	return NSOrderedAscending;
}

@implementation BJCase

@synthesize dataDictionary;
@synthesize name;
@synthesize listedDataFolders;
@synthesize notifyDataChangeEnabled;
@synthesize metaDataPropertyList;

- (id)init {
	self = [super init];
	if (self) {
		dataDictionary = [[NSMutableDictionary alloc] init];
		name = [[NSString alloc] init];
		listedDataFolders = [[NSMutableDictionary alloc] init];
		notifyDataChangeEnabled = YES;
		metaDataPropertyList = [[NSMutableDictionary alloc] init];
		[self setMetaDataPropertyValue:[NSNumber numberWithDouble:0.0] withName:@"CurrentTime"];
		[self setMetaDataPropertyValue:[NSNumber numberWithInteger:0] withName:@"CurrentCycle"];
		[self setMetaDataPropertyValue:[NSNumber numberWithDouble:0.0] withName:@"TimeMin"];
		[self setMetaDataPropertyValue:[NSNumber numberWithDouble:0.0] withName:@"TimeMax"];
	}
	return self;
}

- (void)finalize {
	[super finalize];
}

- (id)copyWithZone:(NSZone*)zone {
	BJCase* clone = [[BJCase allocWithZone:zone] init];
	for (id key in self->dataDictionary) {
		[clone copyDataNoNotify:[self dataForKey:key] forKey:key];
	}
	[clone->metaDataPropertyList removeAllObjects];
	for (id key in self->metaDataPropertyList) {
		[clone->metaDataPropertyList setObject:[[self->metaDataPropertyList objectForKey:key] copy] forKey:key];
	}
	[clone setListedDataFolders:[self listedDataFolders]];
	return clone;
}

- (void)copyFromCase:(BJCase*)theCase {
	[self removeAllData];
	[self->metaDataPropertyList removeAllObjects];
	for (id key in theCase->metaDataPropertyList) {
		[self->metaDataPropertyList setObject:[[theCase->metaDataPropertyList objectForKey:key] copy] forKey:key];
	}	
	[self addFromCase:theCase];
}

- (NSUInteger)count {
	return [dataDictionary count];
}

- (void)addFromCase:(BJCase*)theCase {
	for (id key in [theCase dataDictionary]) {
		[self copyDataNoNotify:[theCase dataForKey:key] forKey:key];
	}
	[self notifyDataChange];
}

- (void)addFromCase:(BJCase*)theCase inFolder:(NSString*)theFolder {
	for (id key in [theCase dataDictionary]) {
		id theData = [theCase dataForKey:key];
		[self copyDataNoNotify:theData forName:[theData name] folder:theFolder];
	}
	[self notifyDataChange];
}

- (void)setName:(NSString*)theName {
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self name],@"OldName",theName,@"NewName",nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CaseNameChanging" object:self userInfo:userInfo];
	name = theName;
}

- (id)metaDataPropertyValueWithName:(NSString*)theName {
	return [metaDataPropertyList objectForKey:theName];
}

- (void)removeMetaDataPropertyWithName:(NSString*)theName {
	[metaDataPropertyList removeObjectForKey:theName];
}

- (void)setMetaDataPropertyValue:(id)value withName:(NSString*)theName {
	if (value == nil) {
		[metaDataPropertyList setObject:@"" forKey:theName];
	}
	else {
		[metaDataPropertyList setObject:value forKey:theName];
	}
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:theName forKey:@"Name"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MetaDataPropertyChanged" object:self userInfo:userInfo];
}

- (void)setData:(BJData*)theData forKey:(NSString*)theKey {
	[self setDataNoNotify:theData forKey:theKey];
	[self notifyDataChange];
}

- (void)setDataNoNotify:(BJData*)theData forKey:(NSString*)theKey {
	if ([dataDictionary objectForKey:theKey] != nil) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DataBeingRemoved" object:[dataDictionary objectForKey:theKey]];
	}
	[dataDictionary setObject:theData forKey:theKey];
}

- (void)copyData:(BJData*)theData forKey:(NSString*)theKey {
	BJData* theDataCopy = [theData copy];
	[self setDataNoNotify:theDataCopy forKey:theKey];
}

- (void)copyDataNoNotify:(BJData*)theData forKey:(NSString*)theKey {
	BJData* theDataCopy = [theData copy];
	[self setDataNoNotify:theDataCopy forKey:theKey];
}

- (id)dataForKey:(NSString*)theKey {
	return [dataDictionary objectForKey:theKey];
}

- (id)dataForUniqueIdentifier:(NSString*)uniqueIdentifier {
	//TODO: keep second dictionary indexed by unique identifier and with key as value
	for (id key in dataDictionary) {
		id dataObject = [self dataForKey:key];
		if ([[dataObject uniqueIdentifier] isEqualToString:uniqueIdentifier]) {
			return dataObject;
		}
	}
	return nil;
}

- (void)removeDataForKey:(NSString*)theKey {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DataBeingRemoved" object:[dataDictionary objectForKey:theKey]];
	[dataDictionary removeObjectForKey:theKey];
	[self notifyDataChange];
}

- (NSString*)dataKeyFromName:(NSString*)theName folder:(NSString*)theFolder {
	return [NSString stringWithFormat:@"%@/%@",theFolder,theName];
}

- (NSArray*)splitDataKey:(NSString*)theKey {
	return [theKey componentsSeparatedByString:@"/"];
}

- (void)setData:(BJData*)theData forName:(NSString*)theName folder:(NSString*)theFolder {
	[theData setName:theName];
	[theData setFolder:theFolder];
	[self setData:theData forKey:[self dataKeyFromName:theName folder:theFolder]];
}

- (void)setDataNoNotify:(BJData*)theData forName:(NSString*)theName folder:(NSString*)theFolder {
	[self setDataNoNotify:theData forKey:[self dataKeyFromName:theName folder:theFolder]];
}

- (void)copyData:(BJData*)theData forName:(NSString*)theName folder:(NSString*)theFolder {
	BJData* theDataCopy = [theData copy];
	[self setData:theDataCopy forName:theName folder:theFolder];
}

- (void)copyDataNoNotify:(BJData*)theData forName:(NSString*)theName folder:(NSString*)theFolder {
	BJData* theDataCopy = [theData copy];
	[self setDataNoNotify:theDataCopy forName:theName folder:theFolder];
}

- (id)dataForName:(NSString*)theName folder:(NSString*)theFolder {
	return [self dataForKey:[self dataKeyFromName:theName folder:theFolder]];
}

- (void)removeDataForName:(NSString*)theName folder:(NSString*)theFolder {
	[self removeDataForKey:[self dataKeyFromName:theName folder:theFolder]];
}

- (void)setData:(BJData*)theData forName:(NSString*)theName {
	[self setData:theData forName:theName folder:@""];
}

- (void)setDataNoNotify:(BJData*)theData forName:(NSString*)theName {
	[self setDataNoNotify:theData forName:theName folder:@""];
}

- (void)copyData:(BJData*)theData forName:(NSString*)theName {
	[self copyData:theData forName:theName folder:@""];
}

- (void)copyDataNoNotify:(BJData*)theData forName:(NSString*)theName {
	[self copyDataNoNotify:theData forName:theName folder:@""];
}

- (id)dataForName:(NSString*)theName {
	return [self dataForName:theName folder:@""];
}

- (NSArray*)keysForNameWithPrefix:(NSString*)prefix {
	return [self keysForNameWithPrefix:prefix folder:@""];
}

- (NSArray*)keysForNameWithPrefix:(NSString*)prefix folder:(NSString*)theFolder {
	NSMutableArray* keys = [[NSMutableArray alloc] init];
	for (id key in dataDictionary) {
		id theData = [dataDictionary objectForKey:key];
		if ([theFolder isEqualToString:@""] == NO) {
			if ([[theData folder] isEqualToString:theFolder] == NO) {
				continue;
			}
		}
		if ([[theData name] hasPrefix:prefix] == NO) {
			continue;
		}
		[keys addObject:key];
	}
	return keys;
}

- (void)removeDataForName:(NSString*)theName {
	[self removeDataForName:theName folder:@""];
}

- (void)removeAllDataNoNotify {
	for (id key in dataDictionary) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DataBeingRemoved" object:[dataDictionary objectForKey:key]];
	}
	[dataDictionary removeAllObjects];
}

- (void)removeAllData {
	[self removeAllDataNoNotify];
	[self notifyDataChange];
}

- (void)setNewKey:(NSString*)newKey forDataWithKey:(NSString*)oldKey {
	if ([dataDictionary objectForKey:newKey] != nil) {
		return;
	}
	BJData* dataItem = [dataDictionary objectForKey:oldKey];
	[self removeDataForKey:oldKey];
	[dataItem setName:newKey];
	[self setData:dataItem forKey:newKey];
}

- (void)notifyDataChange {
	if (notifyDataChangeEnabled == NO) {
		return;
	}
	[self updateListedDataFolders];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self, @"Case", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CaseDataChanged" object:self userInfo:userInfo];
}

- (void)updateListedDataFolders {
	[listedDataFolders removeAllObjects];
	for (id key in [self allKeys]) {
		id theData = [self dataForKey:key];
		if ([theData listed] == NO) {
			continue;
		}
		NSString* folder = [theData folder];
		if ([folder isEqualToString:@""] == NO) {
			NSArray* folderComponents = [self folderComponents:folder];
			NSUInteger folderCount = [folderComponents count];
			for (NSUInteger i=0; i<folderCount; i++) {
				NSString* parentFolder = [self joinFolderComponents:[folderComponents subarrayWithRange:NSMakeRange(0,i)]];
				NSString* currentFolder = [self joinFolderComponents:[folderComponents subarrayWithRange:NSMakeRange(0,i+1)]];			
				id parentFolderContents = [listedDataFolders objectForKey:parentFolder];
				if (parentFolderContents == nil) {
					parentFolderContents = [NSMutableArray array];
					[listedDataFolders setObject:parentFolderContents forKey:parentFolder];
				}
				if ([parentFolderContents containsObject:currentFolder] == NO) {
					[parentFolderContents addObject:currentFolder];
				}
				parentFolder = [currentFolder copy];			
			}
		}
		id folderContents = [listedDataFolders objectForKey:folder];
		if (folderContents == nil) {
			folderContents = [NSMutableArray array];
			[listedDataFolders setObject:folderContents forKey:folder];
		}
		[folderContents addObject:theData];
	}
	
	NSArray* allKeys = [listedDataFolders allKeys];
	for (id key in allKeys) {
		NSArray* sortedContents = [[listedDataFolders objectForKey:key] sortedArrayUsingFunction:sortData context:NULL];
		NSMutableArray* actualContents = [[NSMutableArray alloc] init];
		for (id item in sortedContents) {
			if ([item isKindOfClass:[NSString class]] == YES) {
				[actualContents addObject:item];
			}
			else {
				[actualContents addObject:[self dataKeyFromName:[item name] folder:[item folder]]];
			}
		}
		[listedDataFolders setObject:actualContents forKey:key];
	}
}

- (NSArray*)listedContentsOfFolder:(NSString*)folder {
	return [listedDataFolders objectForKey:folder];
}

- (NSArray*)folderComponents:(NSString*)folder {
	return [folder componentsSeparatedByString:@"/"];
}

- (NSString*)joinFolderComponents:(NSArray*)folderComponents {
	return [folderComponents componentsJoinedByString:@"/"];
}

- (NSString*)parentFolder:(NSString*)folder atIndex:(NSUInteger)index {
	NSArray* folderComponents = [self folderComponents:folder];
	if ([folderComponents count] < index+1) {
		return nil;
	}
	return [self joinFolderComponents:[folderComponents subarrayWithRange:NSMakeRange(0,index+1)]];
}

- (NSString*)parentFolder:(NSString*)folder {
	return [self parentFolder:folder atIndex:[[self folderComponents:folder] count]-2];
}

- (NSDictionary*)foldersToKeys {
	NSMutableDictionary* foldersToKeysDictionary = [[NSMutableDictionary alloc] init];
	for (id key in [self allKeys]) {
		BJData* theData = [self dataForKey:key];
		id folder = [theData folder];
		if (folder == nil) {
			folder = [NSNull null];
		}
		if ([foldersToKeysDictionary objectForKey:folder] == nil) {
			[foldersToKeysDictionary setObject:[[NSMutableArray alloc] init] forKey:folder];
		}
		[[foldersToKeysDictionary objectForKey:folder] addObject:key];
	}
	return foldersToKeysDictionary;
}

- (NSArray*)allKeys {
	return [dataDictionary allKeys];
}

- (NSArray*)allListedKeys {
	
	NSMutableArray* listedData = [[NSMutableArray alloc] init];
	for (id key in dataDictionary) {
		id theData = [self dataForKey:key];
		if ([theData listed] == YES) {
			[listedData addObject:theData];
		}
	}
	NSArray* sortedListedData = [listedData sortedArrayUsingFunction:sortData context:NULL];
	NSMutableArray* sortedListedKeys = [[NSMutableArray alloc] init];
	for (id theData in sortedListedData) {
		[sortedListedKeys addObject:[self dataKeyFromName:[theData name] folder:[theData folder]]];
	}
	return sortedListedKeys;
}

- (NSString*)listedKeyWithIndex:(NSInteger)index {
	return [[self allListedKeys] objectAtIndex:index];
}

- (NSInteger)numberOfListedKeys {
	return [[self allListedKeys] count];
}

- (NSInteger)numberOfListedKeysWithClassName:(NSString*)className {
	id listedKeys = [self allListedKeys];
	NSInteger count = 0;
	for (id key in listedKeys) {
		if ([[[dataDictionary objectForKey:key] className] isEqualToString:className]) {
			count += 1;
		}
	}
	return count;
}

- (NSDictionary*)writeDataToDirectory:(NSString*)directory {
	NSMutableDictionary* outputRelativePaths = [NSMutableDictionary dictionary];
	for (id key in dataDictionary) {
		id element = [self dataForKey:key];
		if ([element stored] == NO) {
			continue;
		}
		NSString* dataFileName = [element generateFileNameFromName:key];
		[element writeDataToPath:[directory stringByAppendingPathComponent:dataFileName]];
		[outputRelativePaths setObject:dataFileName forKey:key];
	}
	return outputRelativePaths;
}

- (NSDictionary*)casePropertyList {
	NSMutableDictionary* casePropertyList = [[NSMutableDictionary alloc] init];
	[casePropertyList setObject:name forKey:@"Name"];
	NSMutableDictionary* dataPropertyList = [[NSMutableDictionary alloc] init];
	for (id key in dataDictionary) {
		if ([[self dataForKey:key] stored] == NO) {
			continue;
		}
		[dataPropertyList setObject:[[NSDictionary alloc]
									 initWithObjectsAndKeys:
									 [[self dataForKey:key] className],@"ClassName",
									 [[self dataForKey:key] infoPropertyList],@"InfoPropertyList",
									 [[self dataForKey:key] dataPropertyList],@"DataPropertyList",nil] forKey:key];
	}
	[casePropertyList setObject:dataPropertyList forKey:@"DataDictionary"];
	return casePropertyList;
}

- (void)readDataFromDirectory:(NSString*)directory withPropertyList:(NSDictionary*)casePropertyList {
}

- (NSString*)uniqueDataNameWithBaseName:(NSString*)baseName folder:(NSString*)theFolder {
	NSString* theName = baseName;
	int count = 1;
	while ([self dataForName:theName folder:theFolder] != nil) {
		theName = [baseName stringByAppendingString:[NSString stringWithFormat:@"%d",count]];
		count += 1;
	}
	return theName;
}

- (NSString*)uniqueDataNameWithBaseName:(NSString*)baseName {
	return [self uniqueDataNameWithBaseName:baseName folder:@""];
}

- (id)createDisplayObjectForKey:(NSString*)theKey {
	return [[self dataForKey:theKey] createDisplayObject];
}

- (id)createDisplayObjectForName:(NSString*)theName folder:(NSString*)theFolder {
	return [[self dataForName:theName folder:theFolder] createDisplayObject];
}

- (id)createDisplayObjectForName:(NSString*)theName {
	return [self createDisplayObjectForName:theName folder:@""];
}

- (BOOL)writeToPackageWithPath:(NSString*)packagePath {
    
    //TODO: do this atomically. Create a temporary package. If successful, rename it over packagePath.
    //TODO: write casePList first, so if there are any issues the method can exit immediately.
    
	NSDictionary *attribs = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSFileExtensionHidden, nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:packagePath withIntermediateDirectories:YES attributes:attribs error:nil];
	
	//TODO: check that directory has been created successfully
	
    NSString *contentsPath = [packagePath stringByAppendingPathComponent:@"Contents"];
    [[NSFileManager defaultManager] createDirectoryAtPath:contentsPath withIntermediateDirectories:YES attributes:nil error:nil];
	
    NSString *filesPath = [contentsPath stringByAppendingPathComponent:@"Files"];
    [[NSFileManager defaultManager] createDirectoryAtPath:filesPath withIntermediateDirectories:YES attributes:nil error:nil];
	
    NSString *plistFile = [contentsPath stringByAppendingPathComponent:@"Info.plist"];
    
	NSMutableDictionary* casePropertyList = [NSMutableDictionary dictionaryWithDictionary:[self casePropertyList]];
	NSDictionary* outputRelativePaths = [self writeDataToDirectory:filesPath];
	
	[casePropertyList setObject:metaDataPropertyList forKey:@"MetaData"];
	[casePropertyList setObject:outputRelativePaths forKey:@"Files"];
    
    return [casePropertyList writeToFile:plistFile atomically:YES];
}

- (BOOL)writeToPackageWithPath:(NSString*)packagePath andScenes:(NSArray*)scenes {
	BOOL success = [self writeToPackageWithPath:packagePath];
	
	if (success == NO) {
		return NO;
	}
	
    NSString *contentsPath = [packagePath stringByAppendingPathComponent:@"Contents"];
	NSString *scenesPath = [contentsPath stringByAppendingPathComponent:@"Scenes"];
    [[NSFileManager defaultManager] createDirectoryAtPath:scenesPath withIntermediateDirectories:YES attributes:nil error:nil];

	NSMutableArray* sceneFiles = [NSMutableArray array];
	for (id scene in scenes) {
		NSString *sceneFileName = [NSString stringWithFormat:@"%@.plist",[scene name]];
		NSString *scenePListPath = [scenesPath stringByAppendingPathComponent:sceneFileName];
		[scene writeToPListWithPath:scenePListPath];
		[sceneFiles addObject:sceneFileName];
	}

    NSString *plistFile = [contentsPath stringByAppendingPathComponent:@"Info.plist"];
	NSMutableDictionary* casePropertyList = [NSMutableDictionary dictionaryWithContentsOfFile:plistFile];
	[casePropertyList setObject:metaDataPropertyList forKey:@"MetaData"];
	[casePropertyList setObject:sceneFiles forKey:@"Scenes"];
	[casePropertyList writeToFile:plistFile atomically:YES];
	
	return YES;
}

- (BOOL)readFromPackageWithPath:(NSString*)packagePath {
	return [self readFromPackageWithPath:packagePath readData:YES];
}

- (BOOL)readFromPackageWithPath:(NSString*)packagePath readData:(BOOL)readData {
	[self removeAllDataNoNotify];
	
	NSString *contentsPath = [packagePath stringByAppendingPathComponent:@"Contents"];
    NSString *filesPath = [contentsPath stringByAppendingPathComponent:@"Files"];
    NSString *plistFile = [contentsPath stringByAppendingPathComponent:@"Info.plist"];
	
	NSDictionary* propertyList = [NSDictionary dictionaryWithContentsOfFile:plistFile];
	
	if (propertyList == nil) {
		return NO;
	}
	
	[self setName:[propertyList objectForKey:@"Name"]];
	[metaDataPropertyList setDictionary:[propertyList objectForKey:@"MetaData"]];

	NSDictionary* dataPropertyListDictionary = [propertyList objectForKey:@"DataDictionary"];
	for (id key in dataPropertyListDictionary) {
		NSDictionary* dict = [dataPropertyListDictionary objectForKey:key];
		NSString* className = [dict objectForKey:@"ClassName"];
		NSDictionary* dataPropertyList = [dict objectForKey:@"DataPropertyList"];
		NSDictionary* infoPropertyList = [dict objectForKey:@"InfoPropertyList"];
		NSString* theName = [dataPropertyList objectForKey:@"Name"];
		NSString* theFolder = [dataPropertyList objectForKey:@"Folder"];
		BJData* dataObject = [[NSClassFromString(className) alloc] init];
		if (dataObject == nil) {
			continue;
		}
		[[dataObject dataPropertyList] addEntriesFromDictionary:dataPropertyList];
		if (infoPropertyList) {
			[[dataObject infoPropertyList] addEntriesFromDictionary:infoPropertyList];
		}
		if (readData) {
			NSString* dataFilePath = [filesPath stringByAppendingPathComponent:[[propertyList objectForKey:@"Files"] objectForKey:key]];
			[dataObject readDataFromPath:dataFilePath];
		}
		[dataObject update];
		[self setDataNoNotify:dataObject forName:theName folder:theFolder];
	}
	
	return YES;
}

+ (id)caseFromPackageWithPath:(NSString*)packagePath {
	BJCase* theCase = [[BJCase alloc] init];
	BOOL success = [theCase readFromPackageWithPath:packagePath];
	if (success == NO) {
		return nil;
	}
	return theCase;
}

- (NSArray*)pathsOfScenesInPackage:(NSString*)packagePath {
	NSString *contentsPath = [packagePath stringByAppendingPathComponent:@"Contents"];
	NSString *plistFile = [contentsPath stringByAppendingPathComponent:@"Info.plist"];
	NSString *scenesPath = [contentsPath stringByAppendingPathComponent:@"Scenes"];
	NSMutableArray* pathsOfScenes = [NSMutableArray array];
	
	NSDictionary* casePropertyList = [NSDictionary dictionaryWithContentsOfFile:plistFile];
	NSArray* sceneFiles = [casePropertyList objectForKey:@"Scenes"];
	for (id entry in sceneFiles) {
		[pathsOfScenes addObject:[scenesPath stringByAppendingPathComponent:entry]];
	}
	return pathsOfScenes;
}
/*
- (void)setCurrentTime:(double)theTime {
	double currentTime = [[self metaDataPropertyValueWithName:@"CurrentTime"] doubleValue];
    
	if (theTime == currentTime) {
		return;
	}

    [self setMetaDataPropertyValue:[NSNumber numberWithDouble:theTime] withName:@"CurrentTime"];

	for (id key in [self allKeys]) {
		BJData* theData = [self dataForKey:key];
		if ([theData timeDependent] == YES) {
			[theData setCurrentTime:theTime];
			[theData update];
		}
	}
}
*/

- (void)setTimeMin:(double)timeMin max:(double)timeMax {
    [self setMetaDataPropertyValue:[NSNumber numberWithDouble:timeMin] withName:@"TimeMin"];
    [self setMetaDataPropertyValue:[NSNumber numberWithDouble:timeMax] withName:@"TimeMax"];

    for (id key in [self allKeys]) {
		BJData* theData = [self dataForKey:key];
		if ([theData timeDependent] == YES) {
			[theData setTimeMin:timeMin max:timeMax];
			[theData update];
		}
	}
}

- (void)setCurrentTime:(double)theTime {
    [self setCurrentTime:theTime cycle:[[self metaDataPropertyValueWithName:@"CurrentCycle"] integerValue]];
}

- (void)setCurrentTime:(double)theTime cycle:(NSInteger)theCycle {
	double currentTime = [[self metaDataPropertyValueWithName:@"CurrentTime"] doubleValue];
    NSInteger currentCycle = [[self metaDataPropertyValueWithName:@"CurrentCycle"] integerValue];
    
	if (theTime == currentTime && theCycle == currentCycle) {
		return;
	}

    [self setMetaDataPropertyValue:[NSNumber numberWithDouble:theTime] withName:@"CurrentTime"];
    [self setMetaDataPropertyValue:[NSNumber numberWithInteger:theCycle] withName:@"CurrentCycle"];

	for (id key in [self allKeys]) {
		BJData* theData = [self dataForKey:key];
		if ([theData timeDependent] == YES) {
			[theData setCurrentTime:theTime];
			[theData setCurrentCycle:theCycle];
			[theData update];
		}
	}
}

- (void)timeMin:(double*)minTime max:(double*)maxTime {
	double tempMinTime = 0.0;
	double tempMaxTime = 0.0;
	double dataMinTime, dataMaxTime;
	BOOL doneOnce = NO;
	for (id key in [self allKeys]) {
		BJData* theData = [self dataForKey:key];
		if ([theData timeDependent] == YES) {
			dataMinTime = [theData minTime];
			dataMaxTime = [theData maxTime];
			if (doneOnce == NO) {
				tempMinTime = dataMinTime;
				tempMaxTime = dataMaxTime;
			}
			else {
				if (dataMinTime < tempMinTime) {
					tempMinTime = dataMinTime;
				}
				if (dataMaxTime > tempMaxTime) {
					tempMaxTime = dataMaxTime;
				}
			}			
			doneOnce = YES;
		}
	}
	*minTime = tempMinTime;
	*maxTime = tempMaxTime;	
}

@end
