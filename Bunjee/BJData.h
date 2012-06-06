//
//  BJData.h
//  Bunjee
//  Created by Luca Antiga on 4/27/09.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//
class vtkImageData;
class vtkPolyData;
class vtkObject;
class vtkStringArray;
class vtkDoubleArray;

#pragma mark BJData

@interface BJData : NSObject <NSCopying> {
	int updateOnModifiedEventTag;
	vtkObject* observedObject;
	NSMutableDictionary* dataPropertyList;
	NSMutableDictionary* infoPropertyList;
}

@property(readonly) NSMutableDictionary* dataPropertyList;
@property(readonly) NSMutableDictionary* infoPropertyList;

+ (NSString*)dataCode;
- (NSString*)dataCode;

+ (NSString*)dataTypeName;
- (NSString*)dataTypeName;

- (id)copyWithZone:(NSZone*)zone;
- (void)copyDataToClone:(id)clone;
- (void)copyToClone:(id)clone;
- (void)enableUpdateOnModifiedWithVTKObject:(vtkObject*)object;
- (void)disableUpdateOnModified;
- (void)update;
- (void)writeDataToPath:(NSString*)path;
- (void)readDataFromPath:(NSString*)path;
- (NSString*)generateFileNameFromName:(NSString*)name;

- (void)addInfoWithName:(NSString*)name type:(NSString*)type label:(NSString*)label unit:(NSString*)unit group:(NSString*)group attributes:(NSDictionary*)attributes;
- (void)addInfoWithName:(NSString*)name type:(NSString*)type label:(NSString*)label unit:(NSString*)unit group:(NSString*)group;
- (void)removeInfoWithName:(NSString*)name;
- (void)setValue:(id)value forInfo:(NSString*)name;
- (id)valueForInfo:(NSString*)name;
- (id)typeForInfo:(NSString*)name;
- (id)labelForInfo:(NSString*)name;
- (id)unitForInfo:(NSString*)name;
- (id)groupForInfo:(NSString*)name;

- (NSString*)name;
- (void)setName:(NSString*)name;
- (NSString*)folder;
- (void)setFolder:(NSString*)folder;
- (BOOL)listed;
- (void)setListed:(BOOL)listed;
- (BOOL)stored;
- (BOOL)timeDependent;
- (double)currentTime;
- (void)setCurrentTime:(double)currentTime;
- (double)minTime;
- (double)maxTime;
- (NSInteger)currentCycle;
- (void)setCurrentCycle:(NSInteger)currentCycle;
- (double)timeMin;
- (double)timeMax;
- (void)setTimeMin:(double)min max:(double)max;
- (NSString*)dataFileExtension;

- (NSString*)generateUniqueIdentifier;
- (NSString*)uniqueIdentifier;
- (void)setUniqueIdentifier:(NSString*)theUniqueIdentifier;

- (id)createDisplayObject;
- (id)defaultDisplayObjectName;

@end

#pragma mark BJImageData

@interface BJImageData : BJData {
	vtkImageData* imageData;
}

@property(readonly) vtkImageData* imageData;

- (void)readDataInAxialOrientationFromPath:(NSString*)path;
- (void)importVolumeData:(NSData*)volumeData info:(NSDictionary*)info;
- (void)getScalarRange:(double*)range;

@end

#pragma mark BJPolyData

@interface BJPolyData : BJData {
	vtkPolyData* polyData;
}

@property(readonly) vtkPolyData* polyData;

@end

#pragma mark BJLevelSetData

@interface BJLevelSetData : BJImageData {
}

- (void)generateIsoSurface:(vtkPolyData*)polyData;

@end

#pragma mark BJSeedData

@interface BJSeedData : BJPolyData {
	vtkStringArray* labelArray;
}

- (void)addSeed:(double*)point;
- (void)setSingleSeed:(double*)point;

- (void)removeSeed:(int)seedId;
- (void)removeLastSeed;
- (void)removeAllSeeds;

- (void)setMaximumNumberOfSeeds:(NSInteger)numberOfSeeds;
- (NSInteger)maximumNumberOfSeeds;

- (NSInteger)numberOfSeeds;

- (void)setLabel:(NSString*)label;
- (NSString*)label;
- (NSString*)labelsArrayName;

@end

#pragma mark BJTubeData

@interface BJTubeData : BJPolyData {
	vtkDoubleArray* radiusArray;
}

- (void)generateSpline:(vtkPolyData*)polyData;

- (void)addPoint:(double*)point;
- (void)addPoint:(double*)point atId:(int)pointId;
- (void)addPoint:(double*)point withRadius:(double)radius;
- (void)addPoint:(double*)point withRadius:(double)radius atId:(int)pointId;

- (void)removePoint:(int)pointId;
- (void)removeLastPoint;
- (void)removeAllPoints;

- (NSInteger)numberOfPoints;

- (NSString*)radiusArrayName;
- (void)setCurrentRadius:(double)radius;
- (double)currentRadius;

- (NSString*)label;
- (void)setLabel:(NSString*)label;

@end

#pragma mark BJCenterlineData

@interface BJCenterlineData : BJPolyData {
}

- (NSString*)radiusArrayName;
- (NSString*)groupIdsArrayName;
- (NSString*)centerlineIdsArrayName;
- (NSString*)tractIdsArrayName;
- (NSString*)blankingArrayName;

@end

#pragma mark BJReferenceSystemData

@interface BJReferenceSystemData : BJPolyData {
}

- (NSString*)referenceSystemNormalArrayName;
- (NSString*)referenceSystemUpNormalArrayName;

@end

#pragma mark BJBifurcationVectorsData

@interface BJBifurcationVectorsData : BJPolyData {
}

- (NSString*)bifurcationVectorsArrayName;
- (NSString*)inPlaneBifurcationVectorsArrayName;
- (NSString*)outOfPlaneBifurcationVectorsArrayName;
- (NSString*)inPlaneBifurcationVectorAnglesArrayName;
- (NSString*)outOfPlaneBifurcationVectorAnglesArrayName;
- (NSString*)bifurcationVectorsOrientationArrayName;
- (NSString*)bifurcationGroupIdsArrayName;

@end

#pragma mark BJScreenshotData

@interface BJScreenshotData : BJImageData {
}

- (NSString*)base64Image;

@end

