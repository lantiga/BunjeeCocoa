//
//  BJDataDisplay.mm
//  Bunjee
//  Created by Luca Antiga on 2/15/10.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import "BJDataDisplay.h"

#import "BJData.h"

#import "vtkRenderer.h"

#import "vtkImageData.h"
#import "vtkVolume.h"
#import "vtkColorTransferFunction.h"
#import "vtkPiecewiseFunction.h"
#import "vtkFixedPointVolumeRayCastMapper.h"
#import "vtkGPUVolumeRayCastMapper.h"
#import "vtkVolumeRayCastMIPFunction.h"
#import "vtkVolumeProperty.h"
#import "vtkPolyData.h"
#import "vtkPointData.h"
#import "vtkCellData.h"
#import "vtkActor.h"
#import "vtkActor2D.h"
#import "vtkProperty2D.h"
#import "vtkLabeledDataMapper.h"
#import "vtkPolyDataMapper2D.h"
#import "vtkStringArray.h"
#import "vtkTextActor.h"
#import "vtkPolyDataMapper.h"
#import "vtkGlyph2D.h"
#import "vtkGlyphSource2D.h"
#import "vtkGlyph3D.h"
#import "vtkSphereSource.h"
#import "vtkTextProperty.h"
#import "vtkArrowSource.h"
#import "vtkAppendPolyData.h"
#import "vtkProperty.h"
#import "vtkTubeFilter.h"
#import "vtkCleanPolyData.h"
#import "vtkFeatureEdges.h"
#import "vtkStripper.h"
#import "vtkPolyLine.h"
#import "vtkSplineFilter.h"

#import "vtkArcSource.h"
#import "vtkPlaneSource.h"
#import "vtkLineSource.h"

#import "vtkLookupTable.h"

#import "vtkMath.h"
#import "vtkCommand.h"

#pragma mark BJDataDisplay

@implementation BJDataDisplay

@synthesize displayPropertyList;
@synthesize displayEditorPropertyList;
@synthesize dataObject;

- (id)initWithDataObjectUniqueIdentifier:(NSString*)uniqueIdentifier{
	self = [super init];
	if (self) {
		dataObject = nil;
		displayPropertyList = [[NSMutableDictionary alloc] init];
		displayEditorPropertyList = [[NSMutableDictionary alloc] init];
		[displayPropertyList setObject:uniqueIdentifier forKey:@"DataUniqueIdentifier"];
		[displayPropertyList setObject:@"" forKey:@"Name"];
		[displayPropertyList setObject:[NSNumber numberWithBool:YES] forKey:@"Listed"];
		[displayPropertyList setObject:[NSNumber numberWithBool:YES] forKey:@"Displayed"];
		[displayPropertyList setObject:[NSNumber numberWithBool:YES] forKey:@"ThreeD"];
		[self addEditorPropertyWithName:@"Displayed" type:@"boolean" label:@"Displayed" group:@""];

	}
	return self;
}

- (id)initWithDataObject:(BJData*)theDataObject {
	self = [self initWithDataObjectUniqueIdentifier:[theDataObject uniqueIdentifier]];
	if (self) {
		[self bindToDataObject:theDataObject];
	}
	return self;
}

- (void)finalize {
	if (dataObject != nil) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"DataUpdated" object:dataObject];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"DataBeingRemoved" object:dataObject];
	}
	[super finalize];
}

- (void)bindToDataObject:(BJData*)theDataObject {
	[displayPropertyList setObject:[theDataObject uniqueIdentifier] forKey:@"DataUniqueIdentifier"];
	if (dataObject != nil) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"DataUpdated" object:dataObject];
	}
	dataObject = theDataObject;
	//[self setName:[dataObject name]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataHasBeenUpdated:) name:@"DataUpdated" object:dataObject];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataIsBeingRemoved:) name:@"DataBeingRemoved" object:dataObject];
}

- (void)copyToClone:(id)clone {
//	NSString* dataUniqueIdentifier = [clone dataUniqueIdentifier];
	[((BJDataDisplay*)clone)->displayPropertyList removeAllObjects];
	for (id key in self->displayPropertyList) {
		[((BJDataDisplay*)clone)->displayPropertyList setObject:[[self->displayPropertyList objectForKey:key] copy] forKey:key];
	}
//	[((BJDataDisplay*)clone)->displayPropertyList setObject:dataUniqueIdentifier forKey:@"DataUniqueIdentifier"];
}

- (id)copyWithZone:(NSZone*)zone {
	BJDataDisplay* clone = [[BJDataDisplay allocWithZone:zone] init];
	[self copyToClone:clone];
	return clone;
}

- (void)dataHasBeenUpdated:(NSNotification *)notification {
	[self update];
}

- (void)dataIsBeingRemoved:(NSNotification *)notification {
	[self setDisplayed:NO];
	dataObject = nil;
}

- (void)notifyUpdate {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DataDisplayUpdated" object:self];
}

- (void)update {
	[self notifyUpdate];
}

- (void)addToRenderer:(vtkRenderer*)renderer {
}

- (void)removeFromRenderer:(vtkRenderer*)renderer {
}

- (NSString*)name {
	return [self displayPropertyValueWithName:@"Name"];
}

- (void)setName:(NSString*)name {
	[self setDisplayPropertyValue:name withName:@"Name"];
}

- (BOOL)displayed {
	return [[self displayPropertyValueWithName:@"Displayed"] boolValue];
}

- (void)setDisplayed:(BOOL)displayed {
	[self setDisplayPropertyValue:[NSNumber numberWithBool:displayed] withName:@"Displayed"];
}

- (void)setDisplayedNoNotify:(BOOL)displayed {
	[self setDisplayPropertyValue:[NSNumber numberWithBool:displayed] withName:@"Displayed" update:NO];
}

- (BOOL)listed {
	return [[self displayPropertyValueWithName:@"Listed"] boolValue];
}

- (void)setListed:(BOOL)listed {
	[self setDisplayPropertyValue:[NSNumber numberWithBool:listed] withName:@"Listed"];
}

- (BOOL)threeD {
	return [[displayPropertyList objectForKey:@"ThreeD"] boolValue];
}

- (NSString*)dataUniqueIdentifier {
	return [displayPropertyList objectForKey:@"DataUniqueIdentifier"];
}

- (void)setDataUniqueIdentifier:(NSString*)dataUniqueIdentifier {
	return [displayPropertyList setObject:dataUniqueIdentifier forKey:@"DataUniqueIdentifier"];
}

+ (NSString*)dataCode {
	return [BJData dataCode];
}

- (NSString*)dataCode {
	return [[self class] dataCode];
}

+ (NSString*)dataTypeName {
	return [BJData dataTypeName];
}

- (NSString*)dataTypeName {
	return [[self class] dataTypeName];
}

- (NSString*)dataName {
	return [dataObject name];
}

- (NSString*)dataFolder {
	return [dataObject folder];
}

- (void)addEditorPropertyWithName:(NSString*)name type:(NSString*)type label:(NSString*)label group:(NSString*)group attributes:(NSDictionary*)attributes {
	NSMutableDictionary* propertyDict = [[NSMutableDictionary alloc] init];
	[propertyDict setObject:type forKey:@"Type"];
	[propertyDict setObject:label forKey:@"Label"];
	if (group != nil) {
		[propertyDict setObject:group forKey:@"Group"];
	}
	[propertyDict setObject:[NSNumber numberWithInteger:(NSUInteger)[displayEditorPropertyList count]] forKey:@"Id"];
	[propertyDict addEntriesFromDictionary:attributes];
	[displayEditorPropertyList setObject:propertyDict forKey:name];
}

- (void)addEditorPropertyWithName:(NSString*)name type:(NSString*)type label:(NSString*)label group:(NSString*)group {
	[self addEditorPropertyWithName:name type:type label:label group:group attributes:nil];
}

- (void)removeEditorPropertyWithName:(NSString*)name {
	[displayEditorPropertyList removeObjectForKey:name];
}

- (id)displayPropertyValueWithName:(NSString*)name {
	return [displayPropertyList objectForKey:name];
}

- (void)setDisplayPropertyValue:(id)value withName:(NSString*)name {
	[self setDisplayPropertyValue:value withName:name update:YES];
}

- (void)removeDisplayPropertyWithName:(NSString*)name {
	[displayPropertyList removeObjectForKey:name];
}

- (void)setDisplayPropertyValue:(id)value withName:(NSString*)name update:(BOOL)updateFlag {
	[displayPropertyList setObject:value forKey:name];
	if (updateFlag == YES) {
		[self update];
	}
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:name forKey:@"Name"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DisplayPropertyChanged" object:self userInfo:userInfo];
}

- (NSArray*)dataObjectArrayNamesForPointData:(BOOL)pointDataFlag cellData:(BOOL)cellDataFlag {
	return [self dataObjectArrayNamesWithPointData:NULL cellData:NULL];
}

- (NSArray*)dataObjectArrayNamesWithPointData:(vtkFieldData*)pointData cellData:(vtkFieldData*)cellData {
	if (dataObject == nil) {
		return nil;
	}
	NSMutableArray* namesArray = [[NSMutableArray alloc] init];
	int i, numberOfArrays;
	if (pointData) {
		numberOfArrays = pointData->GetNumberOfArrays();
		for (i=0; i<numberOfArrays; i++) {
			vtkDataArray* array = pointData->GetArray(i);
			if (array == NULL) {
				continue;
			}
			if (array->GetName() == NULL) {
				continue;
			}
			NSString* arrayName = [NSString stringWithUTF8String:array->GetName()];
			if ([arrayName hasPrefix:@"_"] == YES) {
				continue;
			}
			[namesArray addObject:arrayName];
		}
	}
	if (cellData) {
		numberOfArrays = cellData->GetNumberOfArrays();
		for (i=0; i<numberOfArrays; i++) {
			vtkDataArray* array = cellData->GetArray(i);
			if (array == NULL) {
				continue;
			}
			if (array->GetName() == NULL) {
				continue;
			}
			NSString* arrayName = [NSString stringWithUTF8String:array->GetName()];
			if ([arrayName hasPrefix:@"_"] == YES) {
				continue;
			}
			[namesArray addObject:arrayName];			
		}
	}
	return namesArray;
}

- (void)setLUTToBlueToRedForActor:(vtkActor*)theActor {
	vtkLookupTable* lut = vtkLookupTable::New();
	lut->SetHueRange(0.66667,0.0);
	//	lut->SetSaturationRange(1.0,1.0);
	lut->SetSaturationRange(0.75,0.75);
	lut->SetValueRange(1.0,1.0);
	lut->SetAlphaRange(1.0,1.0);
	lut->SetNumberOfColors(256);
	lut->Build();
	
	theActor->GetMapper()->SetLookupTable(lut);
	
	lut->Delete();
}

- (void)setLUTToRedToBlueForActor:(vtkActor*)theActor {
	vtkLookupTable* lut = vtkLookupTable::New();
	lut->SetHueRange(0.0,0.66667);
	//	lut->SetSaturationRange(1.0,1.0);
	lut->SetSaturationRange(0.75,0.75);
	lut->SetValueRange(1.0,1.0);
	lut->SetAlphaRange(1.0,1.0);
	lut->SetNumberOfColors(256);
	lut->Build();
	
	theActor->GetMapper()->SetLookupTable(lut);
	
	lut->Delete();
}

- (void)setLUTToDivergingRedBlueForActor:(vtkActor*)theActor {
	vtkColorTransferFunction* lut = vtkColorTransferFunction::New();
	lut->AddRGBPoint(0.0,0.231373,0.298039,0.752941);
	lut->AddRGBPoint(1.0,0.705882,0.0156863,0.14902);
	lut->SetColorSpaceToDiverging();
	lut->Build();	
	
	theActor->GetMapper()->SetLookupTable(lut);
	
	lut->Delete();
}

@end

#pragma mark BJImageDataDisplay

@implementation BJImageDataDisplay

@synthesize imageDataVolume;

- (id)initWithDataObjectUniqueIdentifier:(NSString*)uniqueIdentifier{
	self = [super initWithDataObjectUniqueIdentifier:uniqueIdentifier];
	if (self) {
		imageDataVolume = vtkVolume::New();
		[displayPropertyList setObject:[NSNumber numberWithBool:NO] forKey:@"MIPEnabled"];
		[displayPropertyList setObject:[NSNumber numberWithBool:NO] forKey:@"ThreeD"];
		[displayPropertyList setObject:[NSNumber numberWithBool:YES] forKey:@"PlanesAllowed"];
		[self addEditorPropertyWithName:@"MIPEnabled" type:@"boolean" label:@"MIP" group:@"Rendering"];
	}
	return self;
}

- (void)bindToDataObject:(BJImageData*)theDataObject {
	[super bindToDataObject:theDataObject];

	double scalarRange[2];
	[theDataObject imageData]->GetScalarRange(scalarRange);
	
	vtkPiecewiseFunction* opacityFunction = vtkPiecewiseFunction::New();
	opacityFunction->AddPoint(scalarRange[0],0.0);
	opacityFunction->AddPoint(scalarRange[1],1.0);
	
	vtkColorTransferFunction* colorTransferFunction = vtkColorTransferFunction::New();
	colorTransferFunction->AddRGBPoint(scalarRange[0],0.0,0.0,0.0);
	colorTransferFunction->AddRGBPoint(scalarRange[1],1.0,1.0,1.0);
	
	vtkFixedPointVolumeRayCastMapper* volumeMapper = vtkFixedPointVolumeRayCastMapper::New();
	// DOESN'T WORK ON SNOW LEOPARD! See vtk bug report.
	//	vtkGPUVolumeRayCastMapper* volumeMapper = vtkGPUVolumeRayCastMapper::New();
	volumeMapper->SetInput([theDataObject imageData]);
	volumeMapper->SetBlendModeToMaximumIntensity();
	volumeMapper->AutoAdjustSampleDistancesOn();
	
	vtkVolumeProperty* volumeProperty = vtkVolumeProperty::New();
	volumeProperty->ShadeOn();
	volumeProperty->SetInterpolationTypeToLinear();
	volumeProperty->SetColor(colorTransferFunction);
	volumeProperty->SetScalarOpacity(opacityFunction);
	
	imageDataVolume->SetMapper(volumeMapper);
	imageDataVolume->SetProperty(volumeProperty);
	
	volumeMapper->Delete();
	volumeProperty->Delete();
	colorTransferFunction->Delete();
	opacityFunction->Delete();
}

- (BJImageData*)imageDataObject {
	return (BJImageData*)dataObject;
}

+ (NSString*)dataCode {
	return [BJImageData dataCode];
}

+ (NSString*)dataTypeName {
	return [BJImageData dataTypeName];
}

- (NSArray*)dataObjectArrayNamesForPointData:(BOOL)pointDataFlag cellData:(BOOL)cellDataFlag {
	if (!dataObject) {
		return nil;
	}
	
	vtkFieldData* pointData = NULL;
	vtkFieldData* cellData = NULL;
	if (pointDataFlag) {
		pointData = [[self imageDataObject] imageData]->GetPointData();
	}
	if (cellDataFlag) {
		cellData = [[self imageDataObject] imageData]->GetCellData();
	}
	return [self dataObjectArrayNamesWithPointData:pointData cellData:cellData];
}

- (void)setMipEnabled:(BOOL)mip {
	[self setDisplayPropertyValue:[NSNumber numberWithBool:mip] withName:@"MIPEnabled"];
}

- (BOOL)mipEnabled {
	return [[self displayPropertyValueWithName:@"MIPEnabled"] boolValue];
}

- (BOOL)planesAllowed {
	return [[self displayPropertyValueWithName:@"PlanesAllowed"] boolValue];
}

- (void)addToRenderer:(vtkRenderer*)renderer {
	if ([self mipEnabled] == YES) {
		imageDataVolume->VisibilityOn();
	}
	else {
		imageDataVolume->VisibilityOff();
	}	
	renderer->AddVolume(imageDataVolume);
}

- (void)removeFromRenderer:(vtkRenderer*)renderer {
	renderer->RemoveVolume(imageDataVolume);
}

- (void)update {
	if (!dataObject) {
		return;
	}
	
	if ([self mipEnabled] == YES) {
		imageDataVolume->VisibilityOn();
	}
	else {
		imageDataVolume->VisibilityOff();
	}

	[super update];
}

@end

#pragma mark BJPolyDataDisplay

@implementation BJPolyDataDisplay

@synthesize polyDataActor;

- (id)initWithDataObjectUniqueIdentifier:(NSString*)uniqueIdentifier{
	self = [super initWithDataObjectUniqueIdentifier:uniqueIdentifier];
	if (self) {
		polyDataActor = vtkActor::New();
		//[displayPropertyList setObject:[NSNumber numberWithBool:NO] forKey:@"ScalarVisibility"];
		[displayPropertyList setObject:@"" forKey:@"ScalarArray"];
		[displayPropertyList setObject:[NSNumber numberWithDouble:1.0] forKey:@"Opacity"];
		[displayPropertyList setObject:[NSArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0]] forKey:@"Color"];
		//[self addEditorPropertyWithName:@"ScalarVisibility" type:@"boolean" label:@"Scalar Visibility" group:@"Color"];
		[self addEditorPropertyWithName:@"ScalarArray" type:@"dataarray" label:@"Array" group:@"Appearance"];
		[self addEditorPropertyWithName:@"Opacity" type:@"float" label:@"Opacity" group:@"Appearance" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																											   [NSNumber numberWithDouble:0.0],@"MinValue",[NSNumber numberWithDouble:1.0],@"MaxValue",nil]];
		[self addEditorPropertyWithName:@"Color" type:@"color" label:@"Color" group:@"Appearance"];
	}
	return self;
}

- (void)setLUTToBlueToRed {
	[self setLUTToBlueToRedForActor:[self polyDataActor]];
}

- (void)setLUTToRedToBlue {
	[self setLUTToRedToBlueForActor:[self polyDataActor]];
}

- (void)setLUTToDivergingRedBlue {
	[self setLUTToDivergingRedBlueForActor:[self polyDataActor]];
}

- (void)bindToDataObject:(BJPolyData*)theDataObject {
	[super bindToDataObject:theDataObject];
		
	vtkPolyDataMapper* mapper = vtkPolyDataMapper::New();
	mapper->SetInput([theDataObject polyData]);
	mapper->ScalarVisibilityOff();

	polyDataActor->SetMapper(mapper);
	
	[self setLUTToBlueToRed];
	
	mapper->Delete();
}

- (void)finalize {
	polyDataActor->Delete();
	[super finalize];
}

- (void)copyToClone:(id)clone {
	[super copyToClone:clone];
}

- (id)copyWithZone:(NSZone*)zone {
	BJPolyDataDisplay* clone = [[BJPolyDataDisplay allocWithZone:zone] init];
	[self copyToClone:clone];
	return clone;
}

- (BJPolyData*)polyDataObject {
	return (BJPolyData*)dataObject;
}

+ (NSString*)dataCode {
	return [BJPolyData dataCode];
}

+ (NSString*)dataTypeName {
	return [BJPolyData dataTypeName];
}

- (NSArray*)dataObjectArrayNamesForPointData:(BOOL)pointDataFlag cellData:(BOOL)cellDataFlag {
	if (!dataObject) {
		return nil;
	}
	vtkFieldData* pointData = NULL;
	vtkFieldData* cellData = NULL;
	if (pointDataFlag) {
		pointData = [[self polyDataObject] polyData]->GetPointData();
	}
	if (cellDataFlag) {
		cellData = [[self polyDataObject] polyData]->GetCellData();
	}
	return [self dataObjectArrayNamesWithPointData:pointData cellData:cellData];
}

- (void)addToRenderer:(vtkRenderer*)renderer {
	renderer->AddActor(polyDataActor);
}

- (void)removeFromRenderer:(vtkRenderer*)renderer {
	renderer->RemoveActor(polyDataActor);
}

- (void)update {
	if (!dataObject) {
		return;
	}
	float opacity = [[self displayPropertyValueWithName:@"Opacity"] floatValue];
	polyDataActor->GetProperty()->SetOpacity(opacity);
	//TODO: problem here: if two arrays with same name as pointdata and celldata, pointdata always wins. Need a way to disambiguate.
	//BOOL scalarVisibility = [[self displayPropertyValueWithName:@"ScalarVisibility"] boolValue];
	NSString* scalarArrayName = [self displayPropertyValueWithName:@"ScalarArray"];
	if ([scalarArrayName isEqualToString:@""] == NO) {
		//NSString* scalarArrayName = [self displayPropertyValueWithName:@"ScalarArray"];
		vtkDataArray* scalarArray = [[self polyDataObject] polyData]->GetPointData()->GetArray([scalarArrayName UTF8String]);		
		if (scalarArray) {
			polyDataActor->GetMapper()->ScalarVisibilityOn();
			polyDataActor->GetMapper()->SetScalarModeToUsePointFieldData();
			polyDataActor->GetMapper()->SelectColorArray([scalarArrayName UTF8String]);
			//TODO: set range as property
			polyDataActor->GetMapper()->SetScalarRange(scalarArray->GetRange());
		}
		else {
			scalarArray = [[self polyDataObject] polyData]->GetCellData()->GetArray([scalarArrayName UTF8String]);
			if (scalarArray) {
				polyDataActor->GetMapper()->ScalarVisibilityOn();
				polyDataActor->GetMapper()->SetScalarModeToUseCellFieldData();
				polyDataActor->GetMapper()->SelectColorArray([scalarArrayName UTF8String]);
				//TODO: set range as property
				polyDataActor->GetMapper()->SetScalarRange(scalarArray->GetRange());
			}
			else {
				polyDataActor->GetMapper()->ScalarVisibilityOff();
				CGFloat r, g, b, a;
				[[[NSUnarchiver unarchiveObjectWithData:[self displayPropertyValueWithName:@"Color"]] colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:&a];
				polyDataActor->GetProperty()->SetColor(r,g,b);				
			}
		}
	}
	else {
		polyDataActor->GetMapper()->ScalarVisibilityOff();
		CGFloat r, g, b, a;
		[[[NSUnarchiver unarchiveObjectWithData:[self displayPropertyValueWithName:@"Color"]] colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:&a];
		polyDataActor->GetProperty()->SetColor(r,g,b);				
	}
	
	polyDataActor->GetMapper()->GetLookupTable()->SetVectorModeToMagnitude();
	polyDataActor->Modified();	
	
	[super update];
}

@end

#pragma mark BJLevelSetDataDisplay

@implementation BJLevelSetDataDisplay

@synthesize polyData;
@synthesize polyDataActor;

- (id)initWithDataObjectUniqueIdentifier:(NSString*)uniqueIdentifier{
	self = [super initWithDataObjectUniqueIdentifier:uniqueIdentifier];
	if (self) {
		[displayPropertyList setObject:[NSNumber numberWithBool:NO] forKey:@"PlanesAllowed"];
		[displayPropertyList setObject:[NSNumber numberWithBool:YES] forKey:@"ThreeD"];
		polyData = vtkPolyData::New();
		vtkPolyDataMapper* mapper = vtkPolyDataMapper::New();
		mapper->SetInput(polyData);
		mapper->ScalarVisibilityOff();		
		polyDataActor = vtkActor::New();
		polyDataActor->SetMapper(mapper);
		mapper->Delete();
	}
	return self;
}

- (void)bindToDataObject:(BJLevelSetData*)theDataObject {
	[super bindToDataObject:theDataObject];
}

- (void)finalize {
	polyDataActor->Delete();
	[super finalize];
}

- (void)copyToClone:(id)clone {
	[super copyToClone:clone];
}

- (id)copyWithZone:(NSZone*)zone {
	BJLevelSetDataDisplay* clone = [[BJLevelSetDataDisplay allocWithZone:zone] init];
	return clone;
}

- (BJLevelSetData*)levelSetDataObject {
	return (BJLevelSetData*)dataObject;
}

+ (NSString*)dataCode {
	return [BJLevelSetData dataCode];
}

+ (NSString*)dataTypeName {
	return [BJLevelSetData dataTypeName];
}

- (void)update {
	if (!dataObject) {
		return;
	}

	[[self levelSetDataObject] generateIsoSurface:polyData];
	
	[super update];
}

- (void)addToRenderer:(vtkRenderer*)renderer {
	renderer->AddActor(polyDataActor);
}

- (void)removeFromRenderer:(vtkRenderer*)renderer {
	renderer->RemoveActor(polyDataActor);
}

@end

#pragma mark BJSeedDataDisplay

@implementation BJSeedDataDisplay

- (id)initWithDataObjectUniqueIdentifier:(NSString*)uniqueIdentifier{
	self = [super initWithDataObjectUniqueIdentifier:uniqueIdentifier];
	if (self) {
        labelActor = vtkActor2D::New();
		glyphs = vtkGlyph3D::New();
		[displayPropertyList setObject:[NSNumber numberWithBool:NO] forKey:@"ThreeD"];
		[displayPropertyList setObject:[NSNumber numberWithBool:YES] forKey:@"LabelsVisibility"];
		[displayPropertyList setObject:[NSNumber numberWithBool:YES] forKey:@"GlyphVisibility"];
		[displayPropertyList setObject:[NSNumber numberWithDouble:1.0] forKey:@"GlyphScale"];
		[displayPropertyList setObject:[NSArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:1.0]] forKey:@"Color"];
		[self addEditorPropertyWithName:@"LabelsVisibility" type:@"boolean" label:@"Visible" group:@"Labels"];
		[self addEditorPropertyWithName:@"GlyphVisibility" type:@"boolean" label:@"Visible" group:@"Glyphs"];
		[self addEditorPropertyWithName:@"GlyphScale" type:@"float" label:@"Scale" group:@"Glyphs" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																											   [NSNumber numberWithDouble:0.0],@"MinValue",nil]];
	}
	return self;
}

- (void)bindToDataObject:(BJSeedData*)theDataObject {
	[super bindToDataObject:theDataObject];
	
	vtkSphereSource* glyphSource = vtkSphereSource::New();
	glyphSource->SetThetaResolution(20);
	glyphSource->SetPhiResolution(20);
	
	glyphs->SetInput([theDataObject polyData]);
	glyphs->SetSource(glyphSource->GetOutput());
	glyphs->SetScaleModeToDataScalingOff();

	//TODO: scale with viewport
	//		coordinate = vtkCoordinate::New();
	//		coordinate->SetCoordinateSystemToWorld();
	//		vtkPolyDataMapper2D* glyphMapper = vtkPolyDataMapper2D::New();
	//		glyphMapper->SetInput(glyphs->GetOutput());
	//		glyphMapper->SetTransformCoordinate(coordinate);
	//		seedActor = vtkActor2D::New();
	//		seedActor->SetMapper(glyphMapper);
	//		coordinate->Delete();
	
	vtkPolyDataMapper* glyphMapper = vtkPolyDataMapper::New();
	glyphMapper->SetInput(glyphs->GetOutput());

	polyDataActor->SetMapper(glyphMapper);
	
	glyphSource->Delete();
	glyphMapper->Delete();	
	
	vtkLabeledDataMapper* labelMapper = vtkLabeledDataMapper::New();
	labelMapper->SetInput([theDataObject polyData]);
	labelMapper->SetLabelModeToLabelFieldData();
	labelMapper->SetFieldDataName([[theDataObject labelsArrayName] UTF8String]);
	labelMapper->GetLabelTextProperty()->SetFontFamilyToArial();
	labelMapper->GetLabelTextProperty()->BoldOff();
	labelMapper->GetLabelTextProperty()->ItalicOff();
	labelMapper->GetLabelTextProperty()->ShadowOff();
	labelMapper->GetLabelTextProperty()->SetColor(0.0,1.0,0.0);
	
	labelActor->SetMapper(labelMapper);
	labelMapper->Delete();
}

- (void)update {
	if (!dataObject) {
		return;
	}

	BOOL labelsVisibility = [[self displayPropertyValueWithName:@"LabelsVisibility"] boolValue];
	if (labelsVisibility == YES) {
		labelActor->VisibilityOn();
	}
	else {
		labelActor->VisibilityOff();
	}
	
	BOOL glyphVisibility = [[self displayPropertyValueWithName:@"GlyphVisibility"] boolValue];
	if (glyphVisibility == YES) {
		polyDataActor->VisibilityOn();
	}
	else {
		polyDataActor->VisibilityOff();
	}
	
	float glyphScale = [[self displayPropertyValueWithName:@"GlyphScale"] floatValue];
	glyphs->SetScaleFactor(glyphScale);
	
//	CGFloat r, g, b, a;
//	[[[NSUnarchiver unarchiveObjectWithData:[self displayPropertyValueWithName:@"GlyphColor"]] colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:&a];
//	polyDataActor->GetProperty()->SetColor(r,g,b);
	
	polyDataActor->Modified();	

	[super update];
}

- (void)finalize {
	labelActor->Delete();
	glyphs->Delete();
	[super finalize];
}

- (void)copyToClone:(id)clone {
	[super copyToClone:clone];
}

- (id)copyWithZone:(NSZone*)zone {
	BJSeedDataDisplay* clone = [[BJSeedDataDisplay allocWithZone:zone] init];
	[self copyToClone:clone];
	return clone;
}

- (BJSeedData*)seedDataObject {
	return (BJSeedData*)dataObject;
}

+ (NSString*)dataCode {
	return [BJSeedData dataCode];
}

+ (NSString*)dataTypeName {
	return [BJSeedData dataTypeName];
}

- (void)addToRenderer:(vtkRenderer*)renderer {
	[super addToRenderer:renderer];
	renderer->AddActor(labelActor);
	//	renderer->AddActor(seedActor);
}

- (void)removeFromRenderer:(vtkRenderer*)renderer {
	renderer->RemoveActor(labelActor);
	//	renderer->RemoveActor(seedActor);
	[super removeFromRenderer:renderer];
}

@end

#pragma mark BJTubeDataDisplay

@implementation BJTubeDataDisplay

- (id)initWithDataObjectUniqueIdentifier:(NSString*)uniqueIdentifier{
	self = [super initWithDataObjectUniqueIdentifier:uniqueIdentifier];
	if (self) {
		glyphsActor = vtkActor::New();
        labelActor = vtkTextActor::New();
		labelActor->GetProperty()->SetColor(0.0,1.0,0.0);
		glyphs = vtkGlyph3D::New();
		[displayPropertyList setObject:[NSNumber numberWithBool:NO] forKey:@"ThreeD"];
		[displayPropertyList setObject:[NSNumber numberWithBool:YES] forKey:@"LabelVisibility"];
		[displayPropertyList setObject:[NSNumber numberWithBool:YES] forKey:@"GlyphVisibility"];
		[displayPropertyList setObject:[NSNumber numberWithDouble:1.0] forKey:@"GlyphOpacity"];
		[displayPropertyList setObject:[NSArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed:1.0 green:0.8 blue:0.8 alpha:1.0]] forKey:@"Color"];
		[displayPropertyList setObject:[NSArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:1.0]] forKey:@"GlyphsColor"];
		[self addEditorPropertyWithName:@"LabelVisibility" type:@"boolean" label:@"Visible" group:@"Label"];
		[self addEditorPropertyWithName:@"GlyphVisibility" type:@"boolean" label:@"Visible" group:@"Glyphs"];
	}
	return self;
}

- (void)bindToDataObject:(BJTubeData*)theDataObject {
	[super bindToDataObject:theDataObject];

	[theDataObject polyData]->GetPointData()->SetActiveScalars([[theDataObject radiusArrayName] UTF8String]);

	vtkSphereSource* glyphSource = vtkSphereSource::New();
	glyphSource->SetThetaResolution(20);
	glyphSource->SetPhiResolution(20);
	glyphSource->SetRadius(1.0);
	
	glyphs->SetInput([theDataObject polyData]);
	glyphs->SetSource(glyphSource->GetOutput());
	glyphs->SetScaleModeToScaleByScalar();
	glyphs->SetScaleFactor(1.0);
	
	vtkPolyDataMapper* glyphMapper = vtkPolyDataMapper::New();
	glyphMapper->SetInput(glyphs->GetOutput());
	glyphMapper->ScalarVisibilityOff();
	glyphsActor->SetMapper(glyphMapper);
	
	glyphSource->Delete();
	glyphMapper->Delete();	

	vtkSplineFilter* splineFilter = vtkSplineFilter::New();
	splineFilter->SetInput([theDataObject polyData]);
	splineFilter->SetSubdivideToLength();
	splineFilter->SetLength(0.5);
	
	vtkTubeFilter* tubeFilter = vtkTubeFilter::New();
	tubeFilter->SetInput(splineFilter->GetOutput());
	tubeFilter->SetVaryRadiusToVaryRadiusByAbsoluteScalar();
	tubeFilter->SetNumberOfSides(20);
	
	vtkPolyDataMapper* tubeMapper = vtkPolyDataMapper::New();
	tubeMapper->SetInput(tubeFilter->GetOutput());
	
	polyDataActor->SetMapper(tubeMapper);
	
	splineFilter->Delete();
	tubeFilter->Delete();
	tubeMapper->Delete();
}

- (void)update {
	if (!dataObject) {
		return;
	}
	
	double textPosition[3];
	vtkIdType numberOfPoints = [[self tubeDataObject] polyData]->GetNumberOfPoints();
	if (numberOfPoints == 0) {
		[super update];
		return;
	}
	
	if (numberOfPoints != 2) {
		[[self tubeDataObject] polyData]->GetPoint(numberOfPoints/2,textPosition);
	}
	else {
		double point0[3], point1[3];
		[[self tubeDataObject] polyData]->GetPoint(0,point0);
		[[self tubeDataObject] polyData]->GetPoint(1,point1);
		textPosition[0] = 0.5 * (point0[0] + point1[0]);
		textPosition[1] = 0.5 * (point0[1] + point1[1]);
		textPosition[2] = 0.5 * (point0[2] + point1[2]);
	}
	
	labelActor->GetPositionCoordinate()->SetCoordinateSystemToWorld();
	labelActor->GetPositionCoordinate()->SetValue(textPosition);
	labelActor->SetInput([[[self tubeDataObject] label] UTF8String]);
		
	BOOL labelVisibility = [[self displayPropertyValueWithName:@"LabelVisibility"] boolValue];
	if (labelVisibility == YES) {
		labelActor->VisibilityOn();
	}
	else {
		labelActor->VisibilityOff();
	}

	CGFloat r, g, b, a;
	[[[NSUnarchiver unarchiveObjectWithData:[self displayPropertyValueWithName:@"GlyphsColor"]] colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:&a];
	glyphsActor->GetProperty()->SetColor(r,g,b);				
	
	BOOL glyphVisibility = [[self displayPropertyValueWithName:@"GlyphVisibility"] boolValue];
	if (glyphVisibility == YES) {
		glyphsActor->VisibilityOn();
	}
	else {
		glyphsActor->VisibilityOff();
	}

	double glyphOpacity = [[self displayPropertyValueWithName:@"GlyphOpacity"] doubleValue];
	glyphsActor->GetProperty()->SetOpacity(glyphOpacity);
	
	//	CGFloat r, g, b, a;
	//	[[[NSUnarchiver unarchiveObjectWithData:[self displayPropertyValueWithName:@"GlyphColor"]] colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:&a];
	//	polyDataActor->GetProperty()->SetColor(r,g,b);
	
	polyDataActor->Modified();	
	
	[super update];
}

- (void)finalize {
	glyphsActor->Delete();
	labelActor->Delete();
	glyphs->Delete();
	[super finalize];
}

- (void)copyToClone:(id)clone {
	[super copyToClone:clone];
}

- (id)copyWithZone:(NSZone*)zone {
	BJTubeDataDisplay* clone = [[BJTubeDataDisplay allocWithZone:zone] init];
	[self copyToClone:clone];
	return clone;
}

- (BJTubeData*)tubeDataObject {
	return (BJTubeData*)dataObject;
}

+ (NSString*)dataCode {
	return [BJTubeData dataCode];
}

+ (NSString*)dataTypeName {
	return [BJTubeData dataTypeName];
}

- (void)addToRenderer:(vtkRenderer*)renderer {
	[super addToRenderer:renderer];
	renderer->AddActor(labelActor);
	renderer->AddActor(glyphsActor);
}

- (void)removeFromRenderer:(vtkRenderer*)renderer {
	renderer->RemoveActor(labelActor);
	renderer->RemoveActor(glyphsActor);
	[super removeFromRenderer:renderer];
}

@end

#pragma mark BJCenterlineDataDisplay

@implementation BJCenterlineDataDisplay

- (id)initWithDataObjectUniqueIdentifier:(NSString*)uniqueIdentifier{
	self = [super initWithDataObjectUniqueIdentifier:uniqueIdentifier];
	if (self) {
		tubeActor = vtkActor::New();
		[displayPropertyList setObject:[NSNumber numberWithBool:NO] forKey:@"TubeVisibility"];
		[displayPropertyList setObject:[NSNumber numberWithDouble:1.0] forKey:@"TubeOpacity"];
		[displayPropertyList setObject:[NSNumber numberWithBool:NO] forKey:@"TubeScalarVisibility"];
//		[displayPropertyList setObject:[NSNumber numberWithBool:YES] forKey:@"LabelsVisibility"];
//		[displayPropertyList setObject:@"" forKey:@"LabelsArray"];
		
		[self addEditorPropertyWithName:@"TubeVisibility" type:@"boolean" label:@"Visible" group:@"Tubes"];
		[self addEditorPropertyWithName:@"TubeScalarVisibility" type:@"boolean" label:@"Scalars" group:@"Tubes"];
		[self addEditorPropertyWithName:@"TubeOpacity" type:@"float" label:@"Opacity" group:@"Tubes" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																												  [NSNumber numberWithDouble:0.0],@"MinValue",[NSNumber numberWithDouble:1.0],@"MaxValue",nil]];
//		[self addEditorPropertyWithName:@"LabelsVisibility" type:@"boolean" label:@"Visible" group:@"Labels"];
//		[self addEditorPropertyWithName:@"LabelsArray" type:@"cellarray" label:@"Array" group:@"Labels"];
	}
	return self;
}

- (void)bindToDataObject:(BJCenterlineData*)theDataObject {
	[super bindToDataObject:theDataObject];

	polyDataActor->GetProperty()->SetLineWidth(2.0f);
	
	vtkPolyData* centerlines = vtkPolyData::New();
	centerlines->ShallowCopy([theDataObject polyData]);
	centerlines->GetPointData()->SetActiveScalars([[theDataObject radiusArrayName] UTF8String]);
	
	vtkCleanPolyData* cleaner = vtkCleanPolyData::New();
	cleaner->SetInput(centerlines);
	
	vtkTubeFilter* tubeFilter = vtkTubeFilter::New();
	tubeFilter->SetInput(cleaner->GetOutput());
	tubeFilter->SetVaryRadiusToVaryRadiusByAbsoluteScalar();
	tubeFilter->SetNumberOfSides(20);
	
	vtkPolyDataMapper* tubeMapper = vtkPolyDataMapper::New();
	tubeMapper->SetInput(tubeFilter->GetOutput());
	
	tubeActor->SetMapper(tubeMapper);
	
	centerlines->Delete();
	tubeFilter->Delete();
	tubeMapper->Delete();
}

- (void)copyToClone:(id)clone {
	[super copyToClone:clone];
}

- (id)copyWithZone:(NSZone*)zone {
	BJCenterlineDataDisplay* clone = [[BJCenterlineDataDisplay allocWithZone:zone] init];
	[self copyToClone:clone];
	return clone;
}

- (BJCenterlineData*)centerlineDataObject {
	return (BJCenterlineData*)dataObject;
}

+ (NSString*)dataCode {
	return [BJCenterlineData dataCode];
}

+ (NSString*)dataTypeName {
	return [BJCenterlineData dataTypeName];
}

- (void)update {
	if (!dataObject) {
		return;
	}

	BOOL tubeVisibility = [[self displayPropertyValueWithName:@"TubeVisibility"] boolValue];
	if (tubeVisibility == YES) {
		tubeActor->VisibilityOn();
	}
	else {
		tubeActor->VisibilityOff();
	}
	
	float opacity = [[self displayPropertyValueWithName:@"TubeOpacity"] floatValue];
	tubeActor->GetProperty()->SetOpacity(opacity);
	
	BOOL scalarVisibility = [[self displayPropertyValueWithName:@"TubeScalarVisibility"] boolValue];

	NSString* scalarArrayName = [self displayPropertyValueWithName:@"ScalarArray"];
	if (scalarVisibility and [scalarArrayName isEqualToString:@""] == NO) {
		vtkPolyData* tube = vtkPolyDataMapper::SafeDownCast(tubeActor->GetMapper())->GetInput();
		vtkDataArray* scalarArray = tube->GetPointData()->GetArray([scalarArrayName UTF8String]);		
		if (scalarArray) {
			tubeActor->GetMapper()->ScalarVisibilityOn();
			tubeActor->GetMapper()->SetScalarModeToUsePointFieldData();
			tubeActor->GetMapper()->SelectColorArray([scalarArrayName UTF8String]);
			//TODO: set range as property
			tubeActor->GetMapper()->SetScalarRange(scalarArray->GetRange());
		}
		else {
			scalarArray = tube->GetCellData()->GetArray([scalarArrayName UTF8String]);
			if (scalarArray) {
				tubeActor->GetMapper()->ScalarVisibilityOn();
				tubeActor->GetMapper()->SetScalarModeToUseCellFieldData();
				tubeActor->GetMapper()->SelectColorArray([scalarArrayName UTF8String]);
				//TODO: set range as property
				tubeActor->GetMapper()->SetScalarRange(scalarArray->GetRange());
			}
			else {
				tubeActor->GetMapper()->ScalarVisibilityOff();
				CGFloat r, g, b, a;
				[[[NSUnarchiver unarchiveObjectWithData:[self displayPropertyValueWithName:@"Color"]] colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:&a];
				tubeActor->GetProperty()->SetColor(r,g,b);								
			}
		}
	}
	else {
		tubeActor->GetMapper()->ScalarVisibilityOff();
		CGFloat r, g, b, a;
		[[[NSUnarchiver unarchiveObjectWithData:[self displayPropertyValueWithName:@"Color"]] colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:&a];
		tubeActor->GetProperty()->SetColor(r,g,b);								
	}
	
	tubeActor->Modified();
	/*
	BOOL labelsVisibility = [[self displayPropertyValueWithName:@"LabelsVisibility"] boolValue];
	if (labelsVisibility == NO) {
		labelActor->VisibilityOff();
	}
	
	BOOL glyphVisibility = [[self displayPropertyValueWithName:@"GlyphVisibility"] boolValue];
	if (glyphVisibility == NO) {
		polyDataActor->VisibilityOff();
	}
	
	float glyphScale = [[self displayPropertyValueWithName:@"GlyphScale"] floatValue];
	glyphs->SetScaleFactor(glyphScale);
	
	CGFloat r, g, b, a;
	[[[NSUnarchiver unarchiveObjectWithData:[self displayPropertyValueWithName:@"GlyphColor"]] colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]] getRed:&r green:&g blue:&b alpha:&a];
	polyDataActor->GetProperty()->SetColor(r/256.0,g/256.0,b/256.0);
	 */
	[super update];
}

- (void)finalize {
	tubeActor->Delete();
	[super finalize];
}

- (void)addToRenderer:(vtkRenderer*)renderer {
	[super addToRenderer:renderer];
	renderer->AddActor(tubeActor);
}

- (void)removeFromRenderer:(vtkRenderer*)renderer {
	renderer->RemoveActor(tubeActor);
	[super removeFromRenderer:renderer];
}

@end

#pragma mark BJReferenceSystemDataDisplay

@implementation BJReferenceSystemDataDisplay

- (id)initWithDataObjectUniqueIdentifier:(NSString*)uniqueIdentifier{
	self = [super initWithDataObjectUniqueIdentifier:uniqueIdentifier];
	if (self) {
		planeSource = vtkPlaneSource::New();
		planeActor = vtkActor::New();
		edgeActor = vtkActor::New();

		[displayPropertyList setObject:[NSNumber numberWithBool:YES] forKey:@"VectorsVisibility"];
		[displayPropertyList setObject:[NSNumber numberWithDouble:1.0] forKey:@"VectorsScale"];
		[displayPropertyList setObject:[NSNumber numberWithBool:YES] forKey:@"PlaneVisibility"];
		[displayPropertyList setObject:[NSNumber numberWithDouble:1.0] forKey:@"PlaneScale"];
		[displayPropertyList setObject:[NSNumber numberWithDouble:1.0] forKey:@"PlaneOpacity"];

		[self addEditorPropertyWithName:@"VectorsVisibility" type:@"boolean" label:@"Reference System Vectors" group:@"Geometry"];
		[self addEditorPropertyWithName:@"VectorsScale" type:@"float" label:@"Scale" group:@"Vectors" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																											   [NSNumber numberWithDouble:0.0],@"MinValue",nil]];
		[self addEditorPropertyWithName:@"PlaneVisibility" type:@"boolean" label:@"Bifurcation Plane" group:@"Geometry"];
		[self addEditorPropertyWithName:@"PlaneScale" type:@"float" label:@"Scale" group:@"Plane" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																											  [NSNumber numberWithDouble:0.0],@"MinValue",nil]];
		[self addEditorPropertyWithName:@"PlaneOpacity" type:@"float" label:@"Opacity" group:@"Plane" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																												  [NSNumber numberWithDouble:0.0],@"MinValue",[NSNumber numberWithDouble:1.0],@"MaxValue",nil]];
	}
	return self;
}

- (void)bindToDataObject:(BJReferenceSystemData*)theDataObject {
	[super bindToDataObject:theDataObject];
	
	vtkPolyDataMapper* planeMapper = vtkPolyDataMapper::New();
	planeMapper->SetInput(planeSource->GetOutput());
	
	planeActor->SetMapper(planeMapper);
	
	planeMapper->Delete();
}

- (void)finalize {
	planeSource->Delete();
	planeActor->Delete();
	edgeActor->Delete();
	[super finalize];
}

- (void)copyToClone:(id)clone {
	[super copyToClone:clone];
}

- (id)copyWithZone:(NSZone*)zone {
	BJReferenceSystemDataDisplay* clone = [[BJReferenceSystemDataDisplay allocWithZone:zone] init];
	[self copyToClone:clone];
	return clone;
}

- (BJReferenceSystemData*)referenceSystemDataObject {
	return (BJReferenceSystemData*)dataObject;
}

+ (NSString*)dataCode {
	return [BJReferenceSystemData dataCode];
}

+ (NSString*)dataTypeName {
	return [BJReferenceSystemData dataTypeName];
}

- (void)update {
	if (!dataObject) {
		return;
	}
	
	BOOL vectorsVisibility = [[self displayPropertyValueWithName:@"VectorsVisibility"] boolValue];
	if (vectorsVisibility == YES) {
		polyDataActor->VisibilityOn();
	}
	else {
		polyDataActor->VisibilityOff();
	}
	
	BOOL planeVisibility = [[self displayPropertyValueWithName:@"PlaneVisibility"] boolValue];
	if (planeVisibility == YES) {
		planeActor->VisibilityOn();
	}
	else {
		planeActor->VisibilityOff();
	}
	
	float opacity = [[self displayPropertyValueWithName:@"PlaneOpacity"] floatValue];
	planeActor->GetProperty()->SetOpacity(opacity);
	
	vtkPolyData* normalData = vtkPolyData::New();
	normalData->DeepCopy([[self referenceSystemDataObject] polyData]);
	normalData->GetPointData()->SetActiveVectors([[[self referenceSystemDataObject] referenceSystemNormalArrayName] UTF8String]);
	
	vtkPolyData* upNormalData = vtkPolyData::New();
	upNormalData->DeepCopy([[self referenceSystemDataObject] polyData]);
	upNormalData->GetPointData()->SetActiveVectors([[[self referenceSystemDataObject] referenceSystemUpNormalArrayName] UTF8String]);
	
	vtkArrowSource* arrowSource = vtkArrowSource::New();
	arrowSource->SetShaftResolution(20);
	arrowSource->SetTipResolution(20);
	
	float vectorsScale = [[self displayPropertyValueWithName:@"VectorsScale"] floatValue];
	
	vtkGlyph3D* normalGlypher = vtkGlyph3D::New();
	normalGlypher->SetInput(normalData);
	normalGlypher->SetSource(arrowSource->GetOutput());
	normalGlypher->SetVectorModeToUseVector();
	normalGlypher->SetScaleModeToDataScalingOff();
	normalGlypher->SetScaleFactor(vectorsScale);
	normalGlypher->Update();	
	
	vtkGlyph3D* upNormalGlypher = vtkGlyph3D::New();
	upNormalGlypher->SetInput(upNormalData);	
	upNormalGlypher->SetSource(arrowSource->GetOutput());
	upNormalGlypher->SetVectorModeToUseVector();
	upNormalGlypher->SetScaleModeToDataScalingOff();
	upNormalGlypher->SetScaleFactor(vectorsScale);
	upNormalGlypher->Update();
	
	vtkAppendPolyData* append = vtkAppendPolyData::New();
	append->AddInput(normalGlypher->GetOutput());
	append->AddInput(upNormalGlypher->GetOutput());
	append->Update();
	
	vtkPolyDataMapper::SafeDownCast(polyDataActor->GetMapper())->SetInput(append->GetOutput());
	
	float planeScale = [[self displayPropertyValueWithName:@"PlaneScale"] floatValue];

	double origin[3], point1[3], point2[3], point[3], normal[3], upNormal[3], rightNormal[3];
	
	normalData->GetPoint(0,point);
	normalData->GetPointData()->GetArray([[[self referenceSystemDataObject] referenceSystemNormalArrayName] UTF8String])->GetTuple(0,normal);
	normalData->GetPointData()->GetArray([[[self referenceSystemDataObject] referenceSystemUpNormalArrayName] UTF8String])->GetTuple(0,upNormal);

	vtkMath::Cross(upNormal,normal,rightNormal);

	origin[0] = point[0] - planeScale * upNormal[0] - planeScale * rightNormal[0];
	origin[1] = point[1] - planeScale * upNormal[1] - planeScale * rightNormal[1];
	origin[2] = point[2] - planeScale * upNormal[2] - planeScale * rightNormal[2];

	point1[0] = origin[0] + 2.0 * planeScale * upNormal[0];
	point1[1] = origin[1] + 2.0 * planeScale * upNormal[1];
	point1[2] = origin[2] + 2.0 * planeScale * upNormal[2];

	point2[0] = origin[0] + 2.0 * planeScale * rightNormal[0];
	point2[1] = origin[1] + 2.0 * planeScale * rightNormal[1];
	point2[2] = origin[2] + 2.0 * planeScale * rightNormal[2];
	
	planeSource->SetOrigin(origin);
	planeSource->SetPoint1(point1);
	planeSource->SetPoint2(point2);
	planeSource->Update();
	
	planeActor->Modified();
	
	
	vtkFeatureEdges* edges = vtkFeatureEdges::New();
	edges->SetInput(planeSource->GetOutput());
	edges->FeatureEdgesOff();
	edges->BoundaryEdgesOn();
	edges->NonManifoldEdgesOff();
	
	vtkCleanPolyData* cleaner = vtkCleanPolyData::New();
	cleaner->SetInput(edges->GetOutput());
	
	vtkStripper* stripper = vtkStripper::New();
	stripper->SetInput(cleaner->GetOutput());
	
	vtkPolyDataMapper* edgeMapper = vtkPolyDataMapper::New();
	edgeMapper->SetInput(stripper->GetOutput());
	
	edgeActor->SetMapper(edgeMapper);
	edgeActor->GetProperty()->SetLineWidth(2.0f);
	edgeActor->GetProperty()->SetColor(0.0,0.0,0.0);
	
	edges->Delete();
	cleaner->Delete();
	stripper->Delete();
	edgeMapper->Delete();

	
	normalData->Delete();
	upNormalData->Delete();
	normalGlypher->Delete();
	upNormalGlypher->Delete();
	arrowSource->Delete();
	append->Delete();
	
	[super update];
}

- (void)addToRenderer:(vtkRenderer*)renderer {
	[super addToRenderer:renderer];
	renderer->AddActor(planeActor);
	renderer->AddActor(edgeActor);
}

- (void)removeFromRenderer:(vtkRenderer*)renderer {
	renderer->RemoveActor(planeActor);
	renderer->RemoveActor(edgeActor);
	[super removeFromRenderer:renderer];
}

@end

#pragma mark BJBifurcationVectorsDataDisplay

@implementation BJBifurcationVectorsDataDisplay

- (id)initWithDataObjectUniqueIdentifier:(NSString*)uniqueIdentifier{
	self = [super initWithDataObjectUniqueIdentifier:uniqueIdentifier];
	if (self) {
		[displayPropertyList setObject:[NSNumber numberWithDouble:1.0] forKey:@"GlyphScale"];
		[displayPropertyList setObject:[NSNumber numberWithBool:YES] forKey:@"AngleVisibility"];
		[displayPropertyList setObject:[NSNumber numberWithBool:YES] forKey:@"PlanarityVisibility"];
		[displayPropertyList setObject:[NSNumber numberWithBool:YES] forKey:@"VectorsVisibility"];
		[displayPropertyList setObject:@"3D Vectors" forKey:@"Vectors"];

		[self addEditorPropertyWithName:@"GlyphScale" type:@"float" label:@"Scale" group:@"Geometry" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																												 [NSNumber numberWithDouble:0.0],@"MinValue",nil]];
		[self addEditorPropertyWithName:@"AngleVisibility" type:@"boolean" label:@"Angle" group:@"Geometry"];
		[self addEditorPropertyWithName:@"PlanarityVisibility" type:@"boolean" label:@"Planarity" group:@"Geometry"];
		[self addEditorPropertyWithName:@"VectorsVisibility" type:@"boolean" label:@"Vectors" group:@"Geometry"];
		[self addEditorPropertyWithName:@"Vectors" type:@"select" label:@"Vectors" group:@"Geometry" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																												 [NSArray arrayWithObjects:@"3D Vectors",@"Inplane Vectors",nil],@"Values",nil]];
		arcActor = vtkActor::New();
		angleTextActor = vtkTextActor::New();
		angleTextActor->GetProperty()->SetColor(0.0,1.0,0.0);
		planarityTextActor = vtkTextActor::New();
		angleTextActor->GetProperty()->SetColor(0.0,1.0,0.0);
	}
	return self;	
}

- (void)bindToDataObject:(BJBifurcationVectorsData*)theDataObject {
	[super bindToDataObject:theDataObject];

	vtkPolyDataMapper* arcMapper = vtkPolyDataMapper::New();

	arcActor->SetMapper(arcMapper);		
	arcMapper->Delete();
}

- (void)finalize {
	arcActor->Delete();
	angleTextActor->Delete();
	planarityTextActor->Delete();
	[super finalize];
}

- (void)copyToClone:(id)clone {
	[super copyToClone:clone];
}

- (id)copyWithZone:(NSZone*)zone {
	BJBifurcationVectorsDataDisplay* clone = [[BJBifurcationVectorsDataDisplay allocWithZone:zone] init];	
	[self copyToClone:clone];
	return clone;
}

- (BJBifurcationVectorsData*)bifurcationVectorsDataObject {
	return (BJBifurcationVectorsData*)dataObject;
}

+ (NSString*)dataCode {
	return [BJBifurcationVectorsData dataCode];
}

+ (NSString*)dataTypeName {
	return [BJBifurcationVectorsData dataTypeName];
}

- (void)addToRenderer:(vtkRenderer*)renderer {
	[super addToRenderer:renderer];
	renderer->AddActor(arcActor);
	renderer->AddActor(angleTextActor);
	renderer->AddActor(planarityTextActor);
}

- (void)removeFromRenderer:(vtkRenderer*)renderer {
	renderer->RemoveActor(arcActor);
	renderer->RemoveActor(angleTextActor);
	renderer->RemoveActor(planarityTextActor);
	[super removeFromRenderer:renderer];
}

- (void)update {
	if (!dataObject) {
		return;
	}
	
	if ([[self bifurcationVectorsDataObject] polyData]->GetNumberOfPoints() == 0) {
		return;
	}
	
	vtkArrowSource* arrowSource = vtkArrowSource::New();
	arrowSource->SetShaftResolution(20);
	arrowSource->SetTipResolution(20);

	float glyphScale = [[self displayPropertyValueWithName:@"GlyphScale"] floatValue];

	vtkPolyData* vectorData = vtkPolyData::New();
	vectorData->DeepCopy([[self bifurcationVectorsDataObject] polyData]);
	
	if ([[self displayPropertyValueWithName:@"Vectors"] isEqualToString:@"3D Vectors"]) {
		vectorData->GetPointData()->SetActiveVectors([[[self bifurcationVectorsDataObject] bifurcationVectorsArrayName] UTF8String]);		
	}
	else {
		vectorData->GetPointData()->SetActiveVectors([[[self bifurcationVectorsDataObject] inPlaneBifurcationVectorsArrayName] UTF8String]);				
	}
	
	vtkGlyph3D* vectorGlypher = vtkGlyph3D::New();
	vectorGlypher->SetInput(vectorData);
	vectorGlypher->SetSource(arrowSource->GetOutput());
	vectorGlypher->SetVectorModeToUseVector();
	vectorGlypher->SetScaleModeToDataScalingOff();
	vectorGlypher->SetScaleFactor(glyphScale);
		
	vtkPolyDataMapper::SafeDownCast(polyDataActor->GetMapper())->SetInput(vectorGlypher->GetOutput());

	if ([[self displayPropertyValueWithName:@"VectorsVisibility"] boolValue] == YES) {
		polyDataActor->VisibilityOn();
	}
	else {
		polyDataActor->VisibilityOff();
	}
	
	double point0[3], point1[3], point2[3];
	vectorData->GetPoint(0,point0);
	vectorData->GetPoint(1,point1);
	vectorData->GetPoint(2,point2);
	
	double vector1[3], vector2[3];
	vectorData->GetPointData()->GetVectors()->GetTuple(1,vector1);
	vectorData->GetPointData()->GetVectors()->GetTuple(2,vector2);
	
	point1[0] = point1[0] + glyphScale * vector1[0];
	point1[1] = point1[1] + glyphScale * vector1[1];
	point1[2] = point1[2] + glyphScale * vector1[2];

	point2[0] = point2[0] + glyphScale * vector2[0];
	point2[1] = point2[1] + glyphScale * vector2[1];
	point2[2] = point2[2] + glyphScale * vector2[2];
	
	vtkArcSource* arcSource = vtkArcSource::New();
	arcSource->SetResolution(30);
	arcSource->SetPoint1(point1);
	arcSource->SetPoint2(point2);
	arcSource->SetCenter(point0);
	arcSource->Update();
	
	vtkPolyDataMapper::SafeDownCast(arcActor->GetMapper())->SetInput(arcSource->GetOutput());
	

//	vtkDataArray* inPlaneAngleArray = vectorData->GetPointData()->GetArray([[[self bifurcationVectorsDataObject] inPlaneBifurcationVectorAnglesArrayName] UTF8String]);
//	double angleValue = fabs(inPlaneAngleArray->GetTuple1(2) - inPlaneAngleArray->GetTuple1(1));
	double angleValue = [[[self bifurcationVectorsDataObject] valueForInfo:@"BifurcationAngle"] doubleValue];
	NSString* angleAnnotation = [NSString stringWithFormat:@"Bifurcation Angle: %.2f deg",angleValue];

	double textPosition[3];
	vtkIdType numberOfPoints = arcSource->GetOutput()->GetNumberOfPoints();
	arcSource->GetOutput()->GetPoint(numberOfPoints/2,textPosition);
	angleTextActor->GetPositionCoordinate()->SetCoordinateSystemToWorld();
	angleTextActor->GetPositionCoordinate()->SetValue(textPosition);

	angleTextActor->SetInput([angleAnnotation UTF8String]);
	
	if ([[self displayPropertyValueWithName:@"AngleVisibility"] boolValue] == YES) {
		angleTextActor->VisibilityOn();
		arcActor->VisibilityOn();
	}
	else {
		angleTextActor->VisibilityOff();
		arcActor->VisibilityOff();
	}

	
//	vtkDataArray* outOfPlaneAngleArray = vectorData->GetPointData()->GetArray([[[self bifurcationVectorsDataObject] outOfPlaneBifurcationVectorAnglesArrayName] UTF8String]);
//	double planarityValue = fabs(outOfPlaneAngleArray->GetTuple1(1) + outOfPlaneAngleArray->GetTuple1(0));

	double planarityValue = [[[self bifurcationVectorsDataObject] valueForInfo:@"Planarity"] doubleValue];
	NSString* planarityAnnotation = [NSString stringWithFormat:@"Planarity: %.2f deg",planarityValue];

	vectorData->GetCenter(textPosition);
	planarityTextActor->GetPositionCoordinate()->SetCoordinateSystemToWorld();
	planarityTextActor->GetPositionCoordinate()->SetValue(textPosition);
	
	planarityTextActor->SetInput([planarityAnnotation UTF8String]);
	
	if ([[self displayPropertyValueWithName:@"PlanarityVisibility"] boolValue] == YES) {
		planarityTextActor->VisibilityOn();
	}
	else {
		planarityTextActor->VisibilityOff();
	}

	vectorData->Delete();
	arcSource->Delete();

	arrowSource->Delete();
	vectorGlypher->Delete();
	
	[super update];
}

@end


