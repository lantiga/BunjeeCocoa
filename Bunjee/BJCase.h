//
//  BJCase.h
//  Bunjee
//  Created by Luca Antiga on 2/15/10.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BJData;

@interface BJCase : NSObject <NSCopying> {
	NSMutableDictionary* dataDictionary;
	NSString* name;
	NSMutableDictionary* listedDataFolders;
	BOOL notifyDataChangeEnabled;
	NSMutableDictionary* metaDataPropertyList;
}

@property(readonly) NSMutableDictionary* dataDictionary;
@property(readwrite,copy,setter=setName:) NSString* name;
@property(readwrite,copy) NSMutableDictionary* listedDataFolders;
@property(readwrite) BOOL notifyDataChangeEnabled;
@property(readonly) NSMutableDictionary* metaDataPropertyList;

- (id)copyWithZone:(NSZone*)zone;
- (void)copyFromCase:(BJCase*)theCase;

- (NSUInteger)count;

- (void)addFromCase:(BJCase*)theCase;
- (void)addFromCase:(BJCase*)theCase inFolder:(NSString*)theFolder;

- (id)metaDataPropertyValueWithName:(NSString*)theName;
- (void)removeMetaDataPropertyWithName:(NSString*)theName;
- (void)setMetaDataPropertyValue:(id)value withName:(NSString*)theName;

- (void)setData:(BJData*)theData forKey:(NSString*)theKey;
- (void)setDataNoNotify:(BJData*)theData forKey:(NSString*)theKey;
- (void)copyData:(BJData*)theData forKey:(NSString*)theKey;
- (void)copyDataNoNotify:(BJData*)theData forKey:(NSString*)theKey;
- (id)dataForKey:(NSString*)theKey;
- (void)removeDataForKey:(NSString*)theKey;

- (void)setData:(BJData*)theData forName:(NSString*)theName;
- (void)setDataNoNotify:(BJData*)theData forName:(NSString*)theName;
- (void)copyData:(BJData*)theData forName:(NSString*)theName;
- (void)copyDataNoNotify:(BJData*)theData forName:(NSString*)theName;
- (id)dataForName:(NSString*)theName;
- (void)removeDataForName:(NSString*)theName;

- (void)setData:(BJData*)theData forName:(NSString*)theName folder:(NSString*)theFolder;
- (void)setDataNoNotify:(BJData*)theData forName:(NSString*)theName folder:(NSString*)theFolder;
- (void)copyData:(BJData*)theData forName:(NSString*)theName folder:(NSString*)theFolder;
- (void)copyDataNoNotify:(BJData*)theData forName:(NSString*)theName folder:(NSString*)theFolder;
- (id)dataForName:(NSString*)theName folder:(NSString*)theFolder;
- (void)removeDataForName:(NSString*)theName folder:(NSString*)theFolder;

- (NSArray*)keysForNameWithPrefix:(NSString*)prefix;
- (NSArray*)keysForNameWithPrefix:(NSString*)prefix folder:(NSString*)theFolder;

- (void)removeAllData;
- (void)removeAllDataNoNotify;

- (id)dataForUniqueIdentifier:(NSString*)uniqueIdentifier;

- (void)setNewKey:(NSString*)theKey forDataWithKey:(NSString*)oldKey;

- (NSArray*)splitDataKey:(NSString*)theKey;

- (void)notifyDataChange;

- (NSDictionary*)foldersToKeys;
- (void)updateListedDataFolders;
- (NSArray*)listedContentsOfFolder:(NSString*)folder;
- (NSString*)parentFolder:(NSString*)folder;
- (NSString*)parentFolder:(NSString*)folder atIndex:(NSUInteger)index;
- (NSArray*)folderComponents:(NSString*)folder;
- (NSString*)joinFolderComponents:(NSArray*)folderComponents;

- (NSDictionary*)casePropertyList;
- (NSDictionary*)writeDataToDirectory:(NSString*)directory;

- (BOOL)writeToPackageWithPath:(NSString*)packagePath;
- (BOOL)writeToPackageWithPath:(NSString*)packagePath andScenes:(NSArray*)scenes;

- (BOOL)readFromPackageWithPath:(NSString*)packagePath readData:(BOOL)readData;
- (BOOL)readFromPackageWithPath:(NSString*)packagePath;

+ (id)caseFromPackageWithPath:(NSString*)packagePath;
- (NSArray*)pathsOfScenesInPackage:(NSString*)packagePath;

- (NSArray*)allKeys;
- (NSArray*)allListedKeys;
- (NSString*)listedKeyWithIndex:(NSInteger)index;
- (NSInteger)numberOfListedKeys;
- (NSInteger)numberOfListedKeysWithClassName:(NSString*)className;

- (NSString*)uniqueDataNameWithBaseName:(NSString*)baseName;
- (NSString*)uniqueDataNameWithBaseName:(NSString*)baseName folder:(NSString*)theFolder;

- (id)createDisplayObjectForKey:(NSString*)theKey;
- (id)createDisplayObjectForName:(NSString*)theName folder:(NSString*)theFolder;
- (id)createDisplayObjectForName:(NSString*)theName;

- (void)setCurrentTime:(double)theTime;
- (void)timeMin:(double*)minTime max:(double*)maxTime;

@end
