//
//  BJScene.h
//  Bunjee
//  Created by Luca Antiga on 8/21/09.
//  Copyright 2010-2011 Orobix. All rights reserved.
//  

#import <Cocoa/Cocoa.h>

@class BJDataDisplay;

@interface BJScene : NSObject <NSCopying> {
	NSMutableDictionary* dataDisplayDictionary;
	BOOL displayStatusChangeNotificationsEnabled;
	NSString* name;
	NSMutableDictionary* displayPropertyList;
	NSMutableDictionary* displayEditorPropertyList;
}

@property(readonly) NSMutableDictionary* dataDisplayDictionary;
@property(readwrite) BOOL displayStatusChangeNotificationsEnabled;
@property(readwrite,copy,setter=setName:) NSString* name;
@property(readonly) NSMutableDictionary* displayPropertyList;
@property(readonly) NSMutableDictionary* displayEditorPropertyList;

- (id)copyWithZone:(NSZone*)zone;
- (void)copyFromScene:(BJScene*)theScene;

- (void)setDataDisplay:(BJDataDisplay*)theDataDisplay forKey:(NSString*)theKey;
- (void)setDataDisplayNoNotify:(BJDataDisplay*)theDataDisplay forKey:(NSString*)theKey;
- (id)dataDisplayForKey:(NSString*)theKey;
- (void)removeDataDisplay:(BJDataDisplay*)theDataDisplay;
- (void)removeDataDisplayForKey:(NSString*)theKey;
- (void)removeAllDataDisplay;

- (NSUInteger)count;

- (NSArray*)keysForDataDisplayWithDataUniqueIdentifier:(NSString*)uniqueIdentifier;

- (BOOL)dataDisplayedForKey:(NSString*)theKey;
- (void)setDataDisplayed:(BOOL)displayed forKey:(NSString*)theKey;

- (NSArray*)keysForDataDisplayWithDataName:(NSString*)dataName;
- (NSArray*)keysForDataDisplayWithName:(NSString*)dataDisplayName;

- (void)addEditorPropertyWithName:(NSString*)name type:(NSString*)type label:(NSString*)label group:(NSString*)group attributes:(NSDictionary*)attributes;
- (void)addEditorPropertyWithName:(NSString*)name type:(NSString*)type label:(NSString*)label group:(NSString*)group;
- (void)removeEditorPropertyWithName:(NSString*)name;

- (id)displayPropertyValueWithName:(NSString*)theName;
- (void)setDisplayPropertyValue:(id)value withName:(NSString*)theName update:(BOOL)updateFlag;
- (void)setDisplayPropertyValue:(id)value withName:(NSString*)theName;

- (id)activeImageData;
- (id)activeImageDataDisplay;

- (NSString*)activeImageDataKey;
- (NSString*)activeImageDataName;
- (void)setActiveImageDataKey:(NSString*)key;

- (void)applySceneTemplate:(BJScene*)sceneTemplate;

- (void)update;
- (void)disable;

- (void)notifyDisplayStatusChange;
- (void)notifyDataDisplayChange;

- (NSDictionary*)scenePropertyList;

- (BOOL)writeToPListWithPath:(NSString*)plistPath;
- (BOOL)readFromPListWithPath:(NSString*)plistPath;
+ (id)sceneFromPListWithPath:(NSString*)plistPath;

- (void)notifyDisplayStatusChange;

- (NSArray*)allKeys;
- (NSArray*)allListedKeys;
- (NSArray*)allListedKeysWithType:(NSString*)dataType;
- (NSString*)listedKeyWithIndex:(NSInteger)index;
- (NSString*)listedKeyWithIndex:(NSInteger)index withType:(NSString*)dataType;
- (NSInteger)numberOfListedKeys;
- (NSInteger)numberOfListedKeysWithType:(NSString*)dataType;

- (NSArray*)listedDataTypeNames;

@end
