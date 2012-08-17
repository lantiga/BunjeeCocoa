//
//  BJData.mm
//  Bunjee
//  Created by Luca Antiga on 4/27/09.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import "BJData.h"
#import "BJDataDisplay.h"

#import "vtkImageData.h"
#import "vtkPolyData.h"
#import "vtkPointData.h"
#import "vtkStringArray.h"
#import "vtkDoubleArray.h"
#import "vtkCellArray.h"

#import "vtkMetaImageReader.h"
#import "vtkMetaImageWriter.h"

#import "vtkvmtkITKArchetypeImageSeriesScalarReader.h"
#import "vtkvmtkITKImageWriter.h"

#import "vtkImageImport.h"
#import "vtkImagePermute.h"
#import "vtkImageFlip.h"
#import "vtkImageReslice.h"

#import "vtkXMLPolyDataReader.h"
#import "vtkXMLPolyDataWriter.h"

#import "vtkPNGReader.h"
#import "vtkPNGWriter.h"

#import "vtkImageTranslateExtent.h"
#import "vtkMarchingCubes.h"
#import "vtkSplineFilter.h"

#import "vtkCellData.h"
#import "vtkCell.h"
#import "vtkMath.h"

#import "vtkCommand.h"

class vtkUpdateOnModifiedCallback : public vtkCommand
{
public:
	static vtkUpdateOnModifiedCallback *New()
	{ return new vtkUpdateOnModifiedCallback; }
	virtual void Execute(vtkObject *caller, unsigned long event, void* data)
	{
		[Data update];
	}
	vtkUpdateOnModifiedCallback()
	{
	}
	BJData* Data;
};

#pragma mark BJData

@implementation BJData

@synthesize dataPropertyList;
@synthesize infoPropertyList;

- (id)init {
	self = [super init];
	if (self) {
		dataPropertyList = [[NSMutableDictionary alloc] init];
		[dataPropertyList setObject:[NSNumber numberWithBool:YES] forKey:@"Listed"];
		[dataPropertyList setObject:[NSNumber numberWithBool:YES] forKey:@"Stored"];
		[dataPropertyList setObject:[NSNumber numberWithBool:NO] forKey:@"TimeDependent"];
		[dataPropertyList setObject:[NSNumber numberWithDouble:0.0] forKey:@"CurrentTime"];
		[dataPropertyList setObject:[NSNumber numberWithInteger:0] forKey:@"CurrentCycle"];
		[dataPropertyList setObject:[NSNumber numberWithInteger:0.0] forKey:@"TimeMin"];
		[dataPropertyList setObject:[NSNumber numberWithInteger:0.0] forKey:@"TimeMax"];
		[dataPropertyList setObject:@"" forKey:@"Name"];
		[dataPropertyList setObject:@"" forKey:@"Folder"];
		[dataPropertyList setObject:@"" forKey:@"DataFileExtension"];
		[dataPropertyList setObject:[self generateUniqueIdentifier] forKey:@"UniqueIdentifier"];
		infoPropertyList = [[NSMutableDictionary alloc] init];
		updateOnModifiedEventTag = -1;
		observedObject = NULL;
	}
	return self;
}

- (void)finalize {
	[super finalize];
}

+ (NSString*)dataCode {
	return @"";
}

- (NSString*)dataCode {
	return [[self class] dataCode];
}

+ (NSString*)dataTypeName {
	return @"";
}

- (NSString*)dataTypeName {
	return [[self class] dataTypeName];
}

- (NSString*)generateUniqueIdentifier {
	long randomNumber = random();
	NSString* uniqueIdentifier = [NSString stringWithFormat:@"%@-%ld",[self className],randomNumber];
	return uniqueIdentifier;
}

- (NSString*)generateFileNameFromName:(NSString*)name {
	return [[name stringByAppendingPathExtension:[self dataFileExtension]] stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
}

- (void)copyDataToClone:(id)clone {
	[[clone infoPropertyList] removeAllObjects];
	for (id key in infoPropertyList) {
		[[clone infoPropertyList] setObject:[[infoPropertyList objectForKey:key] copy] forKey:[key copy]];
	}
}

- (void)copyToClone:(id)clone {
	id uniqueIdentifier = [((BJData*)clone)->dataPropertyList objectForKey:@"UniqueIdentifier"];
	[((BJData*)clone)->dataPropertyList removeAllObjects];
	for (id key in self->dataPropertyList) {
		[((BJData*)clone)->dataPropertyList setObject:[[self->dataPropertyList objectForKey:key] copy] forKey:key];
	}
//	[((BJData*)clone)->dataPropertyList setObject:[self generateUniqueIdentifier] forKey:@"UniqueIdentifier"];
	[((BJData*)clone)->dataPropertyList setObject:uniqueIdentifier forKey:@"UniqueIdentifier"];
	[self copyDataToClone:clone];
}

- (id)copyWithZone:(NSZone*)zone {
	BJData* clone = [[BJData allocWithZone:zone] init];
	[self copyToClone:clone];
	return clone;
}

- (void)addInfoWithName:(NSString*)name type:(NSString*)type label:(NSString*)label unit:(NSString*)unit group:(NSString*)group attributes:(NSDictionary*)attributes {
	NSMutableDictionary* propertyDict = [[NSMutableDictionary alloc] init];
	[propertyDict setObject:type forKey:@"Type"];
	[propertyDict setObject:unit forKey:@"Unit"];
	[propertyDict setObject:label forKey:@"Label"];
	if (group != nil) {
		[propertyDict setObject:group forKey:@"Group"];
	}
	[propertyDict setObject:[NSNumber numberWithInteger:[infoPropertyList count]] forKey:@"Id"];
	[propertyDict addEntriesFromDictionary:attributes];
	[infoPropertyList setObject:propertyDict forKey:name];	
}

- (void)addInfoWithName:(NSString*)name type:(NSString*)type label:(NSString*)label unit:(NSString*)unit group:(NSString*)group {
	[self addInfoWithName:name type:type label:label unit:unit group:group attributes:nil];
}

- (void)removeInfoWithName:(NSString*)name {
	[infoPropertyList removeObjectForKey:name];
}

- (void)setValue:(id)value forInfo:(NSString*)name {
	[[infoPropertyList objectForKey:name] setObject:value forKey:@"Value"];
}

- (id)valueForInfo:(NSString*)name {
	return [[infoPropertyList objectForKey:name] objectForKey:@"Value"];
}

- (id)typeForInfo:(NSString*)name {
	return [[infoPropertyList objectForKey:name] objectForKey:@"Type"];
}

- (id)labelForInfo:(NSString*)name {
	return [[infoPropertyList objectForKey:name] objectForKey:@"Label"];
}

- (id)unitForInfo:(NSString*)name {
	return [[infoPropertyList objectForKey:name] objectForKey:@"Unit"];
}

- (id)groupForInfo:(NSString*)name {
	return [[infoPropertyList objectForKey:name] objectForKey:@"Group"];
}

- (void)update {
//	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self, @"DataObject", nil];
//	[[NSNotificationCenter defaultCenter] postNotificationName:@"DataUpdated" object:self userInfo:userInfo];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DataUpdated" object:self];
}

- (void)writeDataToPath:(NSString*)path {
}

- (void)readDataFromPath:(NSString*)path {
}

//////////////////////////////////////////////////////////////////////////////////
//TODO: extend observedObject to a collection, otherwise troubles when subclassing
//////////////////////////////////////////////////////////////////////////////////
- (void)enableUpdateOnModifiedWithVTKObject:(vtkObject*)object {
	if (updateOnModifiedEventTag != -1) {
		[self disableUpdateOnModified];
	}
	vtkUpdateOnModifiedCallback *updateOnModifiedCallback = vtkUpdateOnModifiedCallback::New();
	updateOnModifiedCallback->Data = self;
	updateOnModifiedEventTag = (int)object->AddObserver(vtkCommand::ModifiedEvent,updateOnModifiedCallback);
	observedObject = object;
	updateOnModifiedCallback->Delete();
}

- (void)disableUpdateOnModified {
	if (!observedObject || updateOnModifiedEventTag == -1) {
		return;
	}
	observedObject->RemoveObserver(updateOnModifiedEventTag);
	updateOnModifiedEventTag = -1;
	observedObject = NULL;
}

- (NSString*)name {
	return [dataPropertyList objectForKey:@"Name"];
}

- (void)setName:(NSString*)name {
	[dataPropertyList setObject:name forKey:@"Name"];
}

- (NSString*)folder {
	return [dataPropertyList objectForKey:@"Folder"];
}

- (void)setFolder:(NSString*)folder {
	[dataPropertyList setObject:folder forKey:@"Folder"];
}

- (BOOL)listed {
	return [[dataPropertyList objectForKey:@"Listed"] boolValue];
}

- (void)setListed:(BOOL)listed {
	[dataPropertyList setObject:[NSNumber numberWithBool:listed] forKey:@"Listed"];
}

- (BOOL)stored {
	return [[dataPropertyList objectForKey:@"Stored"] boolValue];
}

- (BOOL)timeDependent {
	return [[dataPropertyList objectForKey:@"TimeDependent"] boolValue];
}

- (double)currentTime {
	return [[dataPropertyList objectForKey:@"CurrentTime"] doubleValue];
}

- (void)setCurrentTime:(double)currentTime {
	[dataPropertyList setObject:[NSNumber numberWithDouble:currentTime] forKey:@"CurrentTime"];
}

- (NSInteger)currentCycle {
	return [[dataPropertyList objectForKey:@"CurrentCycle"] integerValue];
}

- (void)setCurrentCycle:(NSInteger)currentCycle {
	[dataPropertyList setObject:[NSNumber numberWithInteger:currentCycle] forKey:@"CurrentCycle"];
}

- (double)timeMin {
	return [[dataPropertyList objectForKey:@"TimeMin"] doubleValue];    
}

- (double)timeMax {
    return [[dataPropertyList objectForKey:@"TimeMax"] doubleValue];
}

- (void)setTimeMin:(double)min max:(double)max {
	[dataPropertyList setObject:[NSNumber numberWithDouble:min] forKey:@"TimeMin"];
	[dataPropertyList setObject:[NSNumber numberWithDouble:max] forKey:@"TimeMax"];    
}

- (double)minTime {
	return 0.0;
}

- (double)maxTime {
	return 1.0;
}

- (NSString*)dataFileExtension {
	return [dataPropertyList objectForKey:@"DataFileExtension"];
}

- (id)createDisplayObject {
	return [[BJDataDisplay alloc] initWithDataObject:self];
}

- (id)defaultDisplayObjectName {
	return [NSString stringWithFormat:@"%@/%@",[self folder],[self name]];
}

- (NSString*)uniqueIdentifier {
	return [dataPropertyList objectForKey:@"UniqueIdentifier"];
}

- (void)setUniqueIdentifier:(NSString*)theUniqueIdentifier {
	[dataPropertyList setObject:theUniqueIdentifier forKey:@"UniqueIdentifier"];
}

- (void)requestDelete:(vtkObject*)obj {
    [[self class] performSelectorOnMainThread:@selector(performDelete:) withObject:[NSValue valueWithPointer:obj] waitUntilDone:NO];
}

+ (void)performDelete:(id)obj {
    vtkObject* vtkobj = ((vtkObject*)[obj pointerValue]);
    if (vtkobj) {
        vtkobj->Delete();   
    }
}

@end


#pragma mark BJImageData

@implementation BJImageData

@synthesize imageData;

- (id)init {
	self = [super init];
	if (self) {
		imageData = vtkImageData::New();
		[self enableUpdateOnModifiedWithVTKObject:imageData];
		[dataPropertyList setObject:@"mha" forKey:@"DataFileExtension"];
	}
	return self;
}

- (void)finalize {
	[self disableUpdateOnModified];
    //[self requestDelete:imageData];
	imageData->Delete();
	[super finalize];
}

+ (NSString*)dataCode {
	return @"I";
}

+ (NSString*)dataTypeName {
	return @"Image";
}

- (void)copyDataToClone:(id)clone {
	[super copyDataToClone:clone];
	((BJImageData*)clone)->imageData->DeepCopy(self->imageData);
}

- (id)copyWithZone:(NSZone*)zone {
	BJImageData* clone = [[BJImageData allocWithZone:zone] init];
	[self copyToClone:clone];
	return clone;
}

- (id)createDisplayObject {
	return [[BJImageDataDisplay alloc] initWithDataObject:self];
}

- (void)writeDataToPath:(NSString*)path {
//	NSURL* url = [NSURL URLWithString:dataFileName];

	vtkvmtkITKImageWriter* writer = vtkvmtkITKImageWriter::New();
	writer->SetInput(imageData);
	writer->SetFileName([path fileSystemRepresentation]);
	writer->SetUseCompression(1);
	try {
		writer->Write();
	}
	catch (itk::ExceptionObject excp) {
		// do nothing for now
	}
	writer->Delete();
}

- (void)readDataFromPath:(NSString*)path {
	vtkvmtkITKArchetypeImageSeriesScalarReader* reader = vtkvmtkITKArchetypeImageSeriesScalarReader::New();
	reader->SetArchetype([path fileSystemRepresentation]);
	reader->SetOutputScalarTypeToNative();
	reader->SetDesiredCoordinateOrientationToNative();
	//reader->SetDesiredCoordinateOrientationToAxial();
	reader->SetSingleFile(0);
	try {
		reader->Update();
	}
	catch (itk::ExceptionObject excp) {
	}	
	//TODO get transform
	imageData->DeepCopy(reader->GetOutput());
	reader->Delete();
}

- (void)readDataInAxialOrientationFromPath:(NSString*)path {
	
	vtkvmtkITKArchetypeImageSeriesScalarReader* reader = vtkvmtkITKArchetypeImageSeriesScalarReader::New();
	reader->SetArchetype([path fileSystemRepresentation]);
	reader->SetOutputScalarTypeToNative();
	reader->SetDesiredCoordinateOrientationToAxial();
	reader->SetSingleFile(0);
	try {
		reader->Update();
	}
	catch (itk::ExceptionObject excp) {
	}	
	//TODO get transform
	imageData->DeepCopy(reader->GetOutput());
	reader->Delete();
}

- (void)importVolumeData:(NSData*)volumeData info:(NSDictionary*)info {
	
	int width = [[info objectForKey:@"Width"] intValue];
	int height = [[info objectForKey:@"Height"] intValue];
	int count = [[info objectForKey:@"Count"] intValue];

	double spacing[3], origin[3];
	
	spacing[0] = [[info objectForKey:@"Spacing0"] doubleValue];
	spacing[1] = [[info objectForKey:@"Spacing1"] doubleValue];
	spacing[2] = [[info objectForKey:@"Spacing2"] doubleValue];

	origin[0] = [[info objectForKey:@"Origin0"] doubleValue];
	origin[1] = [[info objectForKey:@"Origin1"] doubleValue];
	origin[2] = [[info objectForKey:@"Origin2"] doubleValue];

	double orientation[3][3];
		
	orientation[0][0] = [[info objectForKey:@"Orientation00"] doubleValue];
	orientation[0][1] = [[info objectForKey:@"Orientation01"] doubleValue];
	orientation[0][2] = [[info objectForKey:@"Orientation02"] doubleValue];
	orientation[1][0] = [[info objectForKey:@"Orientation10"] doubleValue];
	orientation[1][1] = [[info objectForKey:@"Orientation11"] doubleValue];
	orientation[1][2] = [[info objectForKey:@"Orientation12"] doubleValue];
	orientation[2][0] = [[info objectForKey:@"Orientation20"] doubleValue];
	orientation[2][1] = [[info objectForKey:@"Orientation21"] doubleValue];
	orientation[2][2] = [[info objectForKey:@"Orientation22"] doubleValue];
	
	//TODO: desume flipping through directions, not from newAxes.
	
	int newAxes[3];

	if (fabs(orientation[0][0]) >= fabs(orientation[0][1]) && fabs(orientation[0][0]) >= fabs(orientation[0][2])) {
		newAxes[0] = 0;
	}
	else if (fabs(orientation[0][1]) >= fabs(orientation[0][0]) && fabs(orientation[0][1]) >= fabs(orientation[0][2])) {
		newAxes[0] = 1;
	}
	else {
		newAxes[0] = 2;
	}
	
	if (fabs(orientation[1][0]) >= fabs(orientation[1][1]) && fabs(orientation[1][0]) >= fabs(orientation[1][2]) && newAxes[0] != 0) {
		newAxes[1] = 0;
	}
	else if (fabs(orientation[1][1]) >= fabs(orientation[1][0]) && fabs(orientation[1][1]) >= fabs(orientation[1][2]) && newAxes[0] != 1) {
		newAxes[1] = 1;
	}
	else {
		newAxes[1] = 2;
	}
	
	newAxes[2] = 3 - (newAxes[0] + newAxes[1]);

	vtkImageImport* import = vtkImageImport::New();
	import->SetWholeExtent(0,width-1,0,height-1,0,count-1);
	import->SetDataSpacing(spacing);
	import->SetDataExtentToWholeExtent();
	import->SetDataScalarTypeToFloat();
	import->SetImportVoidPointer((void*)[volumeData bytes]);
	import->Update();

	vtkImageData* importedImage = vtkImageData::New();
	
	importedImage->DeepCopy(import->GetOutput());

	int dim[3];
	dim[0] = width;
	dim[1] = height;
	dim[2] = count;
	
	int flipLPS[3];

	flipLPS[0] = 1;
	flipLPS[1] = 1;
	flipLPS[2] = 0;

//	NSLog(@"Origin: %f %f %f",origin[0],origin[1],origin[2]);

//	NSLog(@"Orientation: %f %f %f %f %f %f %f %f %f",orientation[0][0],orientation[0][1],orientation[0][2],orientation[1][0],orientation[1][1],orientation[1][2],orientation[2][0],orientation[2][1],orientation[2][2]);

	double tmpOrigin[3];
	for (int i=0; i<3; i++)
	{
		tmpOrigin[i] = origin[newAxes[i]];
	    if (orientation[i][0] + orientation[i][1] + orientation[i][2] < 0.0) {
			tmpOrigin[i] *= -1.0;
		}
	}
	
	for (int i=0; i<3; i++)
	{
		int doFlip = 0;
		doFlip = flipLPS[newAxes[i]];
		if (doFlip == 1) {
			orientation[i][0] *= -1.0;
			orientation[i][1] *= -1.0;
			orientation[i][2] *= -1.0;
//			NSLog(@"Flipping %d. Spacing %f, dim %d",i,spacing[i],dim[i]);
		}
	}

	importedImage->SetOrigin(tmpOrigin);
	
	vtkImageReslice* reslice = vtkImageReslice::New();
	reslice->SetInput(importedImage);
	reslice->SetResliceAxesDirectionCosines(orientation[0][0],orientation[1][0],orientation[2][0],
											orientation[0][1],orientation[1][1],orientation[2][1],
											orientation[0][2],orientation[1][2],orientation[2][2]);

	reslice->Update();
	
	imageData->DeepCopy(reslice->GetOutput());

	double newOrigin[3];
	imageData->GetOrigin(newOrigin);

//	NSLog(@"New origin: %f %f %f",newOrigin[0],newOrigin[1],newOrigin[2]);

	import->Delete();
	reslice->Delete();
}

- (void)getScalarRange:(double*)range {
	imageData->GetScalarRange(range);
}

@end

#pragma mark BJPolyData

@implementation BJPolyData

@synthesize polyData;

- (id)init {
	self = [super init];
	if (self) {
		polyData = vtkPolyData::New();
		[self enableUpdateOnModifiedWithVTKObject:polyData];
		[dataPropertyList setObject:@"vtp" forKey:@"DataFileExtension"];
	}
	return self;
}

- (void)finalize {
	[self disableUpdateOnModified];
	//[self requestDelete:polyData];
    polyData->Delete();
	[super finalize];
}

+ (NSString*)dataCode {
	return @"S";
}

+ (NSString*)dataTypeName {
	return @"Surface";
}

- (void)copyDataToClone:(id)clone {
	[super copyDataToClone:clone];
	((BJPolyData*)clone)->polyData->DeepCopy(self->polyData);
}

- (id)copyWithZone:(NSZone*)zone {
	BJPolyData* clone = [[BJPolyData allocWithZone:zone] init];
	[self copyToClone:clone];
	return clone;
}

- (id)createDisplayObject {
	return [[BJPolyDataDisplay alloc] initWithDataObject:self];
}

- (void)writeDataToPath:(NSString*)path {
	//	NSURL* url = [NSURL URLWithString:dataFileName];
	//TODO: how to check for success?
	vtkXMLPolyDataWriter* writer = vtkXMLPolyDataWriter::New();
	writer->SetInput(polyData);
	writer->SetFileName([path fileSystemRepresentation]);
	writer->Write();
	writer->Delete();
}

- (void)readDataFromPath:(NSString*)path {
	//TODO: how to check for success?
	vtkXMLPolyDataReader* reader = vtkXMLPolyDataReader::New();
	reader->SetFileName([path fileSystemRepresentation]);
	reader->Update();
	polyData->DeepCopy(reader->GetOutput());
	reader->Delete();
}

@end

#pragma mark BJLevelSetData

@implementation BJLevelSetData

- (id)init {
	self = [super init];
	if (self) {
	}
	return self;
}

- (void)finalize {
	[super finalize];
}

+ (NSString*)dataCode {
	return @"LS";
}

+ (NSString*)dataTypeName {
	return @"Level sets";
}

- (id)copyWithZone:(NSZone*)zone {
	BJLevelSetData* clone = [[BJLevelSetData allocWithZone:zone] init];
	[self copyToClone:clone];
	return clone;
}

- (id)createDisplayObject {
	return [[BJLevelSetDataDisplay alloc] initWithDataObject:self];
}

- (void)generateIsoSurface:(vtkPolyData*)polyData {
	if (polyData == NULL) {
		return;
	}
	
	int extent[6];
	vtkImageData* localImageData = vtkImageData::New();
	localImageData->DeepCopy([self imageData]);
	localImageData->GetWholeExtent(extent);
	
	vtkImageTranslateExtent* translateExtent = vtkImageTranslateExtent::New();
	translateExtent->SetInput(localImageData);
	translateExtent->SetTranslation(-extent[0],-extent[2],-extent[4]);
	translateExtent->Update();
	
	vtkMarchingCubes* marchingCubes = vtkMarchingCubes::New();
	marchingCubes->SetInput(translateExtent->GetOutput());
	marchingCubes->SetValue(0,0.0);
	marchingCubes->Update();
	
	polyData->DeepCopy(marchingCubes->GetOutput());
	
	translateExtent->Delete();
	marchingCubes->Delete();	
}

@end

#pragma mark BJSeedData

@implementation BJSeedData

- (id)init {
	self = [super init];
	if (self) {
		[dataPropertyList setObject:@"Labels" forKey:@"LabelsArrayName"];
		[dataPropertyList setObject:[NSNumber numberWithInt:-1] forKey:@"MaximumNumberOfSeeds"];	
		
		vtkPoints* points = vtkPoints::New();
		polyData->SetPoints(points);
		points->Delete();

		vtkStringArray* labelArray = vtkStringArray::New();
		labelArray->SetName([[self labelsArrayName] UTF8String]);
		polyData->GetPointData()->AddArray(labelArray);
        labelArray->Delete();
	}
	return self;
}

- (void)finalize {
	[super finalize];
}

+ (NSString*)dataCode {
	return @"SD";
}

+ (NSString*)dataTypeName {
	return @"Seeds";
}

- (id)copyWithZone:(NSZone*)zone {
	BJSeedData* clone = [[BJSeedData allocWithZone:zone] init];
	[self copyToClone:clone];
	return clone;
}

- (id)createDisplayObject {
	return [[BJSeedDataDisplay alloc] initWithDataObject:self];
}

- (void)setLabel:(NSString*)label {
	//TODO: DO NOT ACCESS DICTIONARY DIRECTLY (UNLESS KEY-VALUE BINDING IS USED). INSTEAD USE METHOD AND POST NOTIFICATION (OR CALL UPDATE).
	[dataPropertyList setObject:label forKey:@"Label"];
    vtkStringArray* labelArray = vtkStringArray::SafeDownCast(polyData->GetPointData()->GetAbstractArray([[self labelsArrayName] UTF8String]));

	if (!labelArray) {
		return;
	}
	unsigned int i;
	for (i=0; i<polyData->GetNumberOfPoints(); i++) {
		labelArray->InsertValue(i,[label UTF8String]);
	}
	polyData->Modified();
}

- (NSString*)label {
	return [dataPropertyList objectForKey:@"Label"];
}

- (void)setMaximumNumberOfSeeds:(NSInteger)numberOfSeeds {
	[dataPropertyList setObject:[NSNumber numberWithInteger:numberOfSeeds] forKey:@"MaximumNumberOfSeeds"];
}

- (NSInteger)maximumNumberOfSeeds {
	return [[dataPropertyList objectForKey:@"MaximumNumberOfSeeds"] intValue];
}

- (NSString*)labelsArrayName {
	return [dataPropertyList objectForKey:@"LabelsArrayName"];
}

- (void)addSeed:(double*)point {
	NSInteger maximumNumberOfSeeds = [self maximumNumberOfSeeds];
	if (maximumNumberOfSeeds > 0 and [self numberOfSeeds] == maximumNumberOfSeeds) {
		return;
	}
    vtkStringArray* labelArray = vtkStringArray::SafeDownCast(polyData->GetPointData()->GetAbstractArray([[self labelsArrayName] UTF8String]));

	polyData->GetPoints()->InsertNextPoint(point);
	BOOL validLabel = NO;
	if ([self label] != nil) {
		if ([[self label] isEqualToString:@""] == NO) {
			validLabel = YES;
		}
	}
	if (validLabel == YES) {
		labelArray->InsertNextValue([[self label] UTF8String]);
	}
	else {
		labelArray->InsertNextValue("Seed");
	}
	polyData->Modified();
}

- (void)setSingleSeed:(double*)point {
    vtkStringArray* labelArray = vtkStringArray::SafeDownCast(polyData->GetPointData()->GetAbstractArray([[self labelsArrayName] UTF8String]));

	polyData->GetPoints()->SetNumberOfPoints(1);
	polyData->GetPoints()->SetPoint(0,point);
	labelArray->SetNumberOfTuples(1);
	BOOL validLabel = NO;
	if ([self label] != nil) {
		if ([[self label] isEqualToString:@""] == NO) {
			validLabel = YES;
		}
	}
	if (validLabel == YES) {
		labelArray->InsertValue(0,[[self label] UTF8String]);
	}
	else {
		labelArray->InsertValue(0,"Seed");
	}
 	polyData->Modified();
}

- (void)removeSeed:(int)seedId {
    vtkStringArray* labelArray = vtkStringArray::SafeDownCast(polyData->GetPointData()->GetAbstractArray([[self labelsArrayName] UTF8String]));

	vtkIdType numberOfPoints = polyData->GetNumberOfPoints();
	if (seedId > numberOfPoints-1) {
		return;
	}
	vtkPoints* points = polyData->GetPoints();
	vtkIdType i;
	for (i=seedId; i<numberOfPoints-1; i++) {
		points->SetPoint(i,points->GetPoint(i+1));
		labelArray->SetValue(i,labelArray->GetValue(i+1));
	}
	points->SetNumberOfPoints(numberOfPoints-1);
	labelArray->SetNumberOfTuples(numberOfPoints-1);
	polyData->Modified();
}

- (void)removeLastSeed {
    vtkStringArray* labelArray = vtkStringArray::SafeDownCast(polyData->GetPointData()->GetAbstractArray([[self labelsArrayName] UTF8String]));

	vtkIdType numberOfPoints = polyData->GetNumberOfPoints();
	polyData->GetPoints()->SetNumberOfPoints(numberOfPoints-1);
	labelArray->SetNumberOfTuples(numberOfPoints-1);
	polyData->Modified();
}

- (void)removeAllSeeds {
    vtkStringArray* labelArray = vtkStringArray::SafeDownCast(polyData->GetPointData()->GetAbstractArray([[self labelsArrayName] UTF8String]));
	polyData->GetPoints()->SetNumberOfPoints(0);
	labelArray->SetNumberOfTuples(0);
	polyData->Modified();
}

- (NSInteger)numberOfSeeds {
	return polyData->GetNumberOfPoints();
}

- (void)readDataFromPath:(NSString*)path {
    [super readDataFromPath:path];
}

@end

#pragma mark BJTubeData

@implementation BJTubeData

- (id)init {
	self = [super init];
	if (self) {
		[dataPropertyList setObject:@"Radius" forKey:@"RadiusArrayName"];
		[dataPropertyList setObject:@"Tube" forKey:@"Label"];
		[dataPropertyList setObject:[NSNumber numberWithDouble:1.0] forKey:@"CurrentRadius"];
		[dataPropertyList setObject:[NSNumber numberWithInteger:-1] forKey:@"CurrentPointId"];

		vtkPoints* points = vtkPoints::New();
		polyData->SetPoints(points);
		points->Delete();
		
		vtkCellArray* cellArray = vtkCellArray::New();
		polyData->SetLines(cellArray);
		cellArray->Delete();
		
		vtkDoubleArray* radiusArray = vtkDoubleArray::New();
		radiusArray->SetName([[self radiusArrayName] UTF8String]);
		polyData->GetPointData()->AddArray(radiusArray);
        radiusArray->Delete();
	}
	return self;
}

- (void)finalize {
	[super finalize];
}

+ (NSString*)dataCode {
	return @"TB";
}

+ (NSString*)dataTypeName {
	return @"Tube";
}

- (id)copyWithZone:(NSZone*)zone {
	BJTubeData* clone = [[BJTubeData allocWithZone:zone] init];
	[self copyToClone:clone];
	return clone;
}

- (id)createDisplayObject {
	return [[BJTubeDataDisplay alloc] initWithDataObject:self];
}

- (void)generateSpline:(vtkPolyData*)splinePolyData {
	if (splinePolyData == NULL) {
		return;
	}
	
	vtkSplineFilter* splineFilter = vtkSplineFilter::New();
	splineFilter->SetInput([self polyData]);
	splineFilter->SetSubdivideToLength();
	splineFilter->SetLength(0.5);
	splineFilter->Update();

	splinePolyData->DeepCopy(splineFilter->GetOutput());

	splineFilter->Delete();
}

- (void)setLabel:(NSString*)label {
	[dataPropertyList setObject:label forKey:@"Label"];
}

- (NSString*)label {
	return [dataPropertyList objectForKey:@"Label"];
}

- (NSString*)radiusArrayName {
	return [dataPropertyList objectForKey:@"RadiusArrayName"];
}

- (void)addPoint:(double*)point {
	[self addPoint:point withRadius:[self currentRadius]];
}

- (void)addPoint:(double*)point atId:(int)pointId {
	[self addPoint:point withRadius:[self currentRadius] atId:pointId];
}

- (void)addPoint:(double*)point withRadius:(double)radius {
	[self addPoint:point withRadius:radius atId:(int)[self numberOfPoints]];
}

- (void)addPoint:(double*)point withRadius:(double)radius atId:(int)pointId {    
    vtkIdType numberOfPoints = polyData->GetNumberOfPoints();
        
	if (pointId < 0 || pointId > numberOfPoints) {
		return;
	}
    
    vtkDoubleArray* radiusArray = vtkDoubleArray::SafeDownCast(polyData->GetPointData()->GetArray([[self radiusArrayName] UTF8String]));

    vtkPoints* points = polyData->GetPoints();
	vtkIdType i;
    double apoint[3], aradius;
	for (i=numberOfPoints-1; i>=pointId; i--) {
        points->GetPoint(i,apoint);
		points->InsertPoint(i+1,apoint);
		aradius = radiusArray->GetValue(i);
        radiusArray->InsertValue(i+1,aradius);
	}

    points->InsertPoint(pointId,point);
    radiusArray->InsertValue(pointId,radius);

    points->SetNumberOfPoints(numberOfPoints+1);
	radiusArray->SetNumberOfTuples(numberOfPoints+1);

    numberOfPoints = points->GetNumberOfPoints();
    
	vtkCellArray* cellArray = polyData->GetLines();
	cellArray->Initialize();
	cellArray->InsertNextCell((int)numberOfPoints);
	for (int i=0; i<numberOfPoints; i++) {
		cellArray->InsertCellPoint(i);
	}
	
	polyData->Modified();
    
    [self setCurrentPointId:pointId];
}

- (void)removePoint:(int)pointId {
	
	vtkIdType numberOfPoints = polyData->GetNumberOfPoints();
	if (numberOfPoints == 0 || pointId < 0 || pointId > numberOfPoints-1) {
		return;
	}
    
    vtkDoubleArray* radiusArray = vtkDoubleArray::SafeDownCast(polyData->GetPointData()->GetArray([[self radiusArrayName] UTF8String]));
    
	vtkCellArray* cellArray = polyData->GetLines();
	cellArray->Initialize();
	cellArray->InsertNextCell((int)numberOfPoints-1);
	for (int i=0; i<numberOfPoints-1; i++) {
		cellArray->InsertCellPoint(i);
	}	
	
	vtkPoints* points = polyData->GetPoints();
	vtkIdType i;
	for (i=pointId; i<numberOfPoints-1; i++) {
		points->SetPoint(i,points->GetPoint(i+1));
		radiusArray->SetValue(i,radiusArray->GetValue(i+1));
	}
	
	points->SetNumberOfPoints(numberOfPoints-1);
	radiusArray->SetNumberOfTuples(numberOfPoints-1);
	
	polyData->Modified();
    
    if (pointId == numberOfPoints-1) {
        [self setCurrentPointId:numberOfPoints-2];
    }
    else {
        [self setCurrentPointId:pointId];
    }
}

- (void)removeLastPoint {
	[self removePoint:(int)[self numberOfPoints]-1];
}

- (void)removeAllPoints {    
    vtkDoubleArray* radiusArray = vtkDoubleArray::SafeDownCast(polyData->GetPointData()->GetArray([[self radiusArrayName] UTF8String]));

	polyData->GetPoints()->SetNumberOfPoints(0);
	polyData->GetLines()->Initialize();
	radiusArray->SetNumberOfTuples(0);
	polyData->Modified();
    [self setCurrentPointId:-1];
}

- (NSInteger)numberOfPoints {
	return polyData->GetNumberOfPoints();
}

- (void)setCurrentRadius:(double)radius {
    vtkDoubleArray* radiusArray = vtkDoubleArray::SafeDownCast(polyData->GetPointData()->GetArray([[self radiusArrayName] UTF8String]));

	[dataPropertyList setObject:[NSNumber numberWithDouble:radius] forKey:@"CurrentRadius"];
	vtkIdType numberOfPoints = polyData->GetNumberOfPoints();
    vtkIdType pointId = [self currentPointId];
	if (numberOfPoints == 0 || pointId == -1) {
		return;
	}
	radiusArray->SetValue(pointId,radius);
	polyData->Modified();
}

- (double)currentRadius {
	return [[dataPropertyList objectForKey:@"CurrentRadius"] doubleValue];
}

- (void)setCurrentPointId:(NSInteger)pointId {
	[dataPropertyList setObject:[NSNumber numberWithInteger:pointId] forKey:@"CurrentPointId"];    
}

- (NSInteger)currentPointId {
    return [[dataPropertyList objectForKey:@"CurrentPointId"] integerValue];
}

- (void)readDataFromPath:(NSString*)path {
    [super readDataFromPath:path];
    [self setCurrentPointId:polyData->GetNumberOfPoints()-1];
}

@end

#pragma mark BJCenterlineData

@implementation BJCenterlineData

- (id)init {
	self = [super init];
	if (self) {
		[dataPropertyList setObject:@"MaximumInscribedSphereRadius" forKey:@"RadiusArrayName"];
		[dataPropertyList setObject:@"GroupIds" forKey:@"GroupIdsArrayName"];
		[dataPropertyList setObject:@"CenterlineIds" forKey:@"CenterlineIdsArrayName"];
		[dataPropertyList setObject:@"TractIds" forKey:@"TractIdsArrayName"];
		[dataPropertyList setObject:@"Blanking" forKey:@"BlankingArrayName"];
	}
	return self;
}

+ (NSString*)dataCode {
	return @"C";
}

+ (NSString*)dataTypeName {
	return @"Centerlines";
}

- (id)copyWithZone:(NSZone*)zone {
	BJCenterlineData* clone = [[BJCenterlineData allocWithZone:zone] init];
	[self copyToClone:clone];
	return clone;
}

- (id)createDisplayObject {
	return [[BJCenterlineDataDisplay alloc] initWithDataObject:self];
}

- (NSString*)radiusArrayName {
	return [dataPropertyList objectForKey:@"RadiusArrayName"];
}

- (NSString*)groupIdsArrayName {
	return [dataPropertyList objectForKey:@"GroupIdsArrayName"];
}

- (NSString*)centerlineIdsArrayName {
	return [dataPropertyList objectForKey:@"CenterlineIdsArrayName"];
}

- (NSString*)tractIdsArrayName {
	return [dataPropertyList objectForKey:@"TractIdsArrayName"];
}

- (NSString*)blankingArrayName {
	return [dataPropertyList objectForKey:@"BlankingArrayName"];
}

@end

#pragma mark BJReferenceSystemData

@implementation BJReferenceSystemData

- (id)init {
	self = [super init];
	if (self) {
		[dataPropertyList setObject:@"Normal" forKey:@"ReferenceSystemNormalArrayName"];
		[dataPropertyList setObject:@"UpNormal" forKey:@"ReferenceSystemUpNormalArrayName"];
	}
	return self;
}

- (void)finalize {
	[super finalize];
}

+ (NSString*)dataCode {
	return @"RS";
}

+ (NSString*)dataTypeName {
	return @"Reference systems";
}

- (id)copyWithZone:(NSZone*)zone {
	BJReferenceSystemData* clone = [[BJReferenceSystemData allocWithZone:zone] init];
	[self copyToClone:clone];
	return clone;
}

- (id)createDisplayObject {
	return [[BJReferenceSystemDataDisplay alloc] initWithDataObject:self];
}

- (NSString*)referenceSystemNormalArrayName {
	return [dataPropertyList objectForKey:@"ReferenceSystemNormalArrayName"];
}

- (NSString*)referenceSystemUpNormalArrayName {
	return [dataPropertyList objectForKey:@"ReferenceSystemUpNormalArrayName"];
}

@end

#pragma mark BJBifurcationVectorsData

@implementation BJBifurcationVectorsData

- (id)init {
	self = [super init];
	if (self) {
		[dataPropertyList setObject:@"BifurcationVectors" forKey:@"BifurcationVectorsArrayName"];
		[dataPropertyList setObject:@"InPlaneBifurcationVectors" forKey:@"InPlaneBifurcationVectorsArrayName"];
		[dataPropertyList setObject:@"OutOfPlaneBifurcationVectors" forKey:@"OutOfPlaneBifurcationVectorsArrayName"];
		[dataPropertyList setObject:@"InPlaneBifurcationVectorAngles" forKey:@"InPlaneBifurcationVectorAnglesArrayName"];
		[dataPropertyList setObject:@"OutOfPlaneBifurcationVectorAngles" forKey:@"OutOfPlaneBifurcationVectorAnglesArrayName"];
		[dataPropertyList setObject:@"BifurcationVectorsOrientation" forKey:@"BifurcationVectorsOrientationArrayName"];
		[dataPropertyList setObject:@"BifurcationGroupIds" forKey:@"BifurcationGroupIdsArrayName"];
		[self addInfoWithName:@"BifurcationAngle" type:@"float" label:@"Bifurcation Angle" unit:@"deg" group:@"Geometry"];
		[self addInfoWithName:@"Planarity" type:@"float" label:@"Planarity" unit:@"deg" group:@"Geometry"];
	}
	return self;
}

- (void)finalize {
	[super finalize];
}

+ (NSString*)dataCode {
	return @"BV";
}

+ (NSString*)dataTypeName {
	return @"Bifurcation vectors";
}

- (id)copyWithZone:(NSZone*)zone {
	BJBifurcationVectorsData* clone = [[BJBifurcationVectorsData allocWithZone:zone] init];	
	[self copyToClone:clone];
	return clone;
}

- (id)createDisplayObject {
	return [[BJBifurcationVectorsDataDisplay alloc] initWithDataObject:self];
}

- (void)update {
	
	if ([self polyData] == NULL) {
		[self setValue:[NSNumber numberWithDouble:0.0] forInfo:@"BifurcationAngle"];
		[self setValue:[NSNumber numberWithDouble:0.0] forInfo:@"Planarity"];	
		[super update];
		return;
	}
	
	if ([self polyData]->GetNumberOfPoints() != 3) {
		[self setValue:[NSNumber numberWithDouble:0.0] forInfo:@"BifurcationAngle"];
		[self setValue:[NSNumber numberWithDouble:0.0] forInfo:@"Planarity"];	
		[super update];
		return;
	}

	vtkPolyData* vectorData = vtkPolyData::New();
	vectorData->DeepCopy([self polyData]);

	vtkDataArray* inPlaneAngleArray = vectorData->GetPointData()->GetArray([[self inPlaneBifurcationVectorAnglesArrayName] UTF8String]);

	if (inPlaneAngleArray) {
		double angleValue = vtkMath::DegreesFromRadians(fabs(inPlaneAngleArray->GetTuple1(2) - inPlaneAngleArray->GetTuple1(1)));
		[self setValue:[NSNumber numberWithDouble:angleValue] forInfo:@"BifurcationAngle"];
	}
		
	vtkDataArray* outOfPlaneAngleArray = vectorData->GetPointData()->GetArray([[self outOfPlaneBifurcationVectorAnglesArrayName] UTF8String]);	
	
	if (outOfPlaneAngleArray) {
		//TODO: check signs
		double planarityValue = vtkMath::DegreesFromRadians(fabs(outOfPlaneAngleArray->GetTuple1(1) - outOfPlaneAngleArray->GetTuple1(0)));
		[self setValue:[NSNumber numberWithDouble:planarityValue] forInfo:@"Planarity"];	
	}
	
	[super update];
}

- (NSString*)bifurcationVectorsArrayName {
	return [dataPropertyList objectForKey:@"BifurcationVectorsArrayName"];
}

- (NSString*)inPlaneBifurcationVectorsArrayName {
	return [dataPropertyList objectForKey:@"InPlaneBifurcationVectorsArrayName"];
}

- (NSString*)outOfPlaneBifurcationVectorsArrayName {
	return [dataPropertyList objectForKey:@"OutOfPlaneBifurcationVectorsArrayName"];
}

- (NSString*)inPlaneBifurcationVectorAnglesArrayName {
	return [dataPropertyList objectForKey:@"InPlaneBifurcationVectorAnglesArrayName"];
}

- (NSString*)outOfPlaneBifurcationVectorAnglesArrayName {
	return [dataPropertyList objectForKey:@"OutOfPlaneBifurcationVectorAnglesArrayName"];
}

- (NSString*)bifurcationVectorsOrientationArrayName {
	return [dataPropertyList objectForKey:@"BifurcationVectorsOrientationArrayName"];
}

- (NSString*)bifurcationGroupIdsArrayName {
	return [dataPropertyList objectForKey:@"BifurcationGroupIdsArrayName"];
}

@end
 
#pragma mark BJScreenshotData

@implementation BJScreenshotData

- (id)init {
	self = [super init];
	if (self) {
        [dataPropertyList setObject:@"png" forKey:@"DataFileExtension"];
	}
	return self;
}

- (void)finalize {
	[super finalize];
}

+ (NSString*)dataCode {
	return @"SCR";
}

+ (NSString*)dataTypeName {
	return @"Screenshot";
}

- (id)copyWithZone:(NSZone*)zone {
	BJScreenshotData* clone = [[BJScreenshotData allocWithZone:zone] init];
	[self copyToClone:clone];
	return clone;
}

- (id)createDisplayObject {
	return nil;
}

- (void)writeDataToPath:(NSString*)path {
	vtkPNGWriter* writer = vtkPNGWriter::New();
	writer->SetInput(imageData);
	writer->SetFileName([path fileSystemRepresentation]);
    writer->Write();
	writer->Delete();
}

- (void)readDataFromPath:(NSString*)path {
	vtkPNGReader* reader = vtkPNGReader::New();
	reader->SetFileName([path fileSystemRepresentation]);
    reader->Update();

	imageData->DeepCopy(reader->GetOutput());
	reader->Delete();
}

- (NSString*)base64forData:(NSData*)theData {
    
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
}

- (NSString*)base64Image {
    vtkPNGWriter* writer = vtkPNGWriter::New();
    writer->SetInput([self imageData]);
    writer->WriteToMemoryOn();
    writer->Write();
    unsigned char* pixels = writer->GetResult()->GetPointer(0);
    NSUInteger length = writer->GetResult()->GetNumberOfTuples() * writer->GetResult()->GetNumberOfComponents();
        
    NSData *pixelData = [NSData dataWithBytes:pixels length:length];
    NSString *base64String = [NSString stringWithFormat:@"data:image/png;base64,%@",[self base64forData:pixelData]];
    
    return base64String;
}

@end

