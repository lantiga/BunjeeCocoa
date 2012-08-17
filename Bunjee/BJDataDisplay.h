//
//  BJDataDisplay.h
//  Bunjee
//  Created by Luca Antiga on 2/15/10.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

class vtkObject;
class vtkImageData;
class vtkVolume;
class vtkPolyData;
class vtkActor;
class vtkActor2D;
class vtkTextActor;
class vtkRenderer;
class vtkObject;
class vtkStringArray;
class vtkFieldData;
class vtkGlyph3D;
class vtkPlaneSource;
class vtkLineSource;
class vtkScalarsToColors;

#pragma mark BJDataDisplay

@class BJData;

@interface BJDataDisplay : NSObject <NSCopying> {
	BJData* dataObject;
	NSMutableDictionary* displayPropertyList;
	NSMutableDictionary* displayEditorPropertyList;
}

@property(readonly) NSMutableDictionary* displayPropertyList;
@property(readonly) NSMutableDictionary* displayEditorPropertyList;
@property(readonly) BJData* dataObject;

+ (NSString*)dataCode;
- (NSString*)dataCode;

+ (NSString*)dataTypeName;
- (NSString*)dataTypeName;

- (id)initWithDataObjectUniqueIdentifier:(NSString*)uniqueIdentifier;
- (id)initWithDataObject:(BJData*)theDataObject;

- (void)bindToDataObject:(BJData*)theDataObject;

- (id)copyWithZone:(NSZone*)zone;
- (void)copyToClone:(id)clone;

- (void)addToRenderer:(vtkRenderer*)renderer;
- (void)removeFromRenderer:(vtkRenderer*)renderer;
- (void)update;

- (void)addEditorPropertyWithName:(NSString*)name type:(NSString*)type label:(NSString*)label group:(NSString*)group attributes:(NSDictionary*)attributes;
- (void)addEditorPropertyWithName:(NSString*)name type:(NSString*)type label:(NSString*)label group:(NSString*)group;
- (void)removeEditorPropertyWithName:(NSString*)name;

- (id)displayPropertyValueWithName:(NSString*)theName;
- (void)setDisplayPropertyValue:(id)value withName:(NSString*)theName update:(BOOL)updateFlag;
- (void)setDisplayPropertyValue:(id)value withName:(NSString*)theName;

- (NSString*)name;
- (void)setName:(NSString*)name;
- (BOOL)displayed;
- (void)setDisplayed:(BOOL)displayed;
- (void)setDisplayedNoNotify:(BOOL)displayed;
- (BOOL)listed;
- (void)setListed:(BOOL)listed;
- (BOOL)threeD;
- (NSString*)dataUniqueIdentifier;
- (void)setDataUniqueIdentifier:(NSString*)dataUniqueIdentifier;
- (NSString*)dataFolder;
- (NSString*)dataName;

- (NSArray*)dataObjectArrayNamesForPointData:(BOOL)pointDataFlag cellData:(BOOL)cellDataFlag;
- (NSArray*)dataObjectArrayNamesWithPointData:(vtkFieldData*)pointData cellData:(vtkFieldData*)cellData;

- (void)setLUTToBlueToRedForActor:(vtkActor*)theActor;
- (void)setLUTToRedToBlueForActor:(vtkActor*)theActor;
- (void)setLUTToDivergingRedBlueForActor:(vtkActor*)theActor;

- (vtkScalarsToColors*)lut;
- (NSString*)lutTitle;

- (void)requestDelete:(vtkObject*)obj;
+ (void)performDelete:(id)obj;

@end

#pragma mark BJImageDataDisplay

@class BJImageData;

@interface BJImageDataDisplay : BJDataDisplay {
	vtkVolume* imageDataVolume;
}

@property(readwrite) vtkVolume* imageDataVolume;

- (id)initWithDataObjectUniqueIdentifier:(NSString*)uniqueIdentifier;
- (void)bindToDataObject:(BJImageData*)theDataObject;
- (BJImageData*)imageDataObject;

- (BOOL)mipEnabled;
- (void)setMipEnabled:(BOOL)mip;

- (BOOL)planesAllowed;

@end

#pragma mark BJPolyDataDisplay

@class BJPolyData;

@interface BJPolyDataDisplay : BJDataDisplay {
	vtkActor* polyDataActor;
}

@property(readwrite) vtkActor* polyDataActor;

- (id)initWithDataObjectUniqueIdentifier:(NSString*)uniqueIdentifier;
- (void)bindToDataObject:(BJPolyData*)theDataObject;
- (BJPolyData*)polyDataObject;

- (void)setLUTToBlueToRed;
- (void)setLUTToRedToBlue;
- (void)setLUTToDivergingRedBlue;

@end

#pragma mark BJLevelSetDataDisplay

@class BJLevelSetData;

@interface BJLevelSetDataDisplay : BJImageDataDisplay {
	vtkPolyData* polyData;
	vtkActor* polyDataActor;
}

@property(readwrite) vtkPolyData* polyData;
@property(readwrite) vtkActor* polyDataActor;

- (id)initWithDataObjectUniqueIdentifier:(NSString*)uniqueIdentifier;
- (void)bindToDataObject:(BJLevelSetData*)theDataObject;
- (BJLevelSetData*)levelSetDataObject;

@end

#pragma mark BJSeedDataDisplay

@class BJSeedData;

@interface BJSeedDataDisplay : BJPolyDataDisplay {
	vtkActor2D* labelActor;
	vtkGlyph3D* glyphs;
}

- (id)initWithDataObjectUniqueIdentifier:(NSString*)uniqueIdentifier;
- (void)bindToDataObject:(BJSeedData*)theDataObject;
- (BJSeedData*)seedDataObject;

@end

#pragma mark BJTubeDataDisplay

@class BJTubeData;

@interface BJTubeDataDisplay : BJPolyDataDisplay {
	vtkTextActor* labelActor;
	vtkGlyph3D* glyphs;
	vtkActor* glyphsActor;
}

- (id)initWithDataObjectUniqueIdentifier:(NSString*)uniqueIdentifier;
- (void)bindToDataObject:(BJTubeData*)theDataObject;
- (BJTubeData*)tubeDataObject;

@end

#pragma mark BJCenterlineDataDisplay

@class BJCenterlineData;

@interface BJCenterlineDataDisplay : BJPolyDataDisplay {
	vtkActor* tubeActor;
}

- (id)initWithDataObjectUniqueIdentifier:(NSString*)uniqueIdentifier;
- (void)bindToDataObject:(BJCenterlineData*)theDataObject;
- (BJCenterlineData*)centerlineDataObject;

@end

#pragma mark BJReferenceSystemDataDisplay

@class BJReferenceSystemData;

@interface BJReferenceSystemDataDisplay : BJPolyDataDisplay {
	vtkPlaneSource* planeSource;
	vtkActor* planeActor;
	vtkActor* edgeActor;
}

- (id)initWithDataObjectUniqueIdentifier:(NSString*)uniqueIdentifier;
- (void)bindToDataObject:(BJReferenceSystemData*)theDataObject;
- (BJReferenceSystemData*)referenceSystemDataObject;

@end

#pragma mark BJBifurcationVectorsDataDisplay

@class BJBifurcationVectorsData;

@interface BJBifurcationVectorsDataDisplay : BJPolyDataDisplay {
	vtkActor* arcActor;
	vtkTextActor* angleTextActor;
	vtkTextActor* planarityTextActor;
}

- (id)initWithDataObjectUniqueIdentifier:(NSString*)uniqueIdentifier;
- (void)bindToDataObject:(BJBifurcationVectorsData*)theDataObject;
- (BJBifurcationVectorsData*)bifurcationVectorsDataObject;

@end

