//
//  BJDisplayEditorController.mm
//  Bunjee
//  Created by Luca Antiga on 5/14/10.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import "BJDisplayEditorController.h"

#import "Bunjee/BJDataDisplay.h"
#import "Bunjee/BJData.h"
#import "Bunjee/BJScene.h"
#import "Bunjee/BJWorkspace.h"

@implementation NSDictionary(propertyDictionary)

- (NSComparisonResult)comparePropertyIds:(id)obj2 {
	return [[self objectForKey:@"Id"] compare:[obj2 objectForKey:@"Id"]]; 
}

@end

@implementation BJPropertyBox

//- (void)drawRect:(NSRect)rect {
//
//	[[NSColor colorWithCalibratedWhite:256.0 / 256.0  alpha:1.0] set];
//	NSRectFill(rect);
//	
////	[[NSColor colorWithCalibratedWhite:50.0 / 256.0  alpha:1.0] set];
////	NSRect lineRect;
////	lineRect.size.width = rect.size.width;
////	lineRect.size.height = 1;
////	lineRect.origin.x = rect.origin.x + 50.0;
////	lineRect.origin.y = rect.origin.y + rect.size.height - 1;
////	NSRectFill(lineRect);
//	
//}

@end


@implementation BJDisplayEditorController

@synthesize targetObject;
@synthesize targetTitle;
@synthesize targetSubtitle;
@synthesize workspace;

- (id)init {
	self = [self initWithNibName:@"DisplayEditor" bundle:[NSBundle bundleWithIdentifier:@"orobix.BunjeeUI"]];
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];	
	if (self) {
		targetObject = nil;
		targetTitle = nil;
		targetSubtitle = nil;
		workspace = nil;
		containerView = nil;
		controlTagToPropertyDict = [[NSMutableDictionary alloc] init];
		propertyToControlsDict = [[NSMutableDictionary alloc] init];
		columnWidth = 100.0;
		rowHeight = 25.0;
		rowGap = 5.0;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sceneBrowserSelectionHasChanged:) name:@"SceneBrowserSelectionChanged" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(caseDataHasChanged:) name:@"CaseDataChanged" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sceneDataDisplayHasChanged:) name:@"SceneDataDisplayChanged" object:nil];
	}
	return self;
}

- (void)finalize {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"SceneBrowserSelectionChanged" object:nil];	
	[super finalize];
}

- (void)awakeFromNib {
//	containerView = [[NSBox alloc] initWithFrame:[[self view] bounds]];
//	[containerView setTitle:@"Display properties"];
//	[containerView setAutoresizingMask:NSViewMinXMargin|NSViewMaxXMargin|NSViewWidthSizable|NSViewMinYMargin|NSViewMaxYMargin|NSViewHeightSizable];
//	[[self view] addSubview:containerView];
	containerView = [self view];
}

- (void)caseDataHasChanged:(NSNotification*)notification {
	//TODO: rebuild only if targetObject is related to what's changing
	[self rebuildControlsForTargetObject];
}

- (void)sceneDataDisplayHasChanged:(NSNotification*)notification {
	//TODO: rebuild only if targetObject is related to what's changing
	//FIXME: this makes controls being reinstantiated as soon as the user starts interacting, resulting in erratic behavior
//	[self rebuildControlsForTargetObject];
}

- (void)rebuildControlsForTargetObject {
	[self createControlsForTargetObject:[self targetObject] withTitle:[self targetTitle] subtitle:[self targetSubtitle]];
}

- (void)sceneBrowserSelectionHasChanged:(NSNotification*)notification {
	NSDictionary* userInfo = [notification userInfo];
	id item = [userInfo objectForKey:@"Item"];
	if (item == targetObject) {
		return;
	}
	if (item == nil) {
		[self clearControls];
	}
	if ([item isKindOfClass:[BJDataDisplay class]] == YES) {
		[self createControlsForDataDisplay:item];
	}
	else if ([item isKindOfClass:[BJScene class]] == YES) {
		[self createControlsForScene:item];
	}
	else {
		[self clearControls];
	}
}

- (void)clearControls {
	while ([[containerView subviews] count]) {
		[[[containerView subviews] lastObject] removeFromSuperview];
	}
	targetObject = nil;
}

- (void)createControlsForBooleanProperty:(NSDictionary*)propertyDict withName:(NSString*)propertyName inSubview:(NSBox*)subview {

	NSRect buttonFrame;
//	buttonFrame.origin.x = columnWidth;
	buttonFrame.origin.x = 0.0;
	buttonFrame.origin.y = -rowHeight * row;
	NSButton* button = [[NSButton alloc] initWithFrame:buttonFrame];
	[button setButtonType:NSSwitchButton];
	[[button cell] setControlSize:NSSmallControlSize];
	CGFloat fontSize = [NSFont systemFontSizeForControlSize:NSSmallControlSize];
	[[button cell] setFont:[NSFont labelFontOfSize:fontSize]];
	[button setTitle:[propertyDict objectForKey:@"Label"]];
	[button setTarget:self];
	[button setAction:@selector(controlValueChanged:)];
	[button sizeToFit];
	[button setObjectValue:[targetObject displayPropertyValueWithName:propertyName]];
	[subview addSubview:button];
		
	NSInteger tag = [controlTagToPropertyDict count];
	[button setTag:tag];
	[controlTagToPropertyDict setObject:propertyName forKey:[NSNumber numberWithInteger:tag]];
	[propertyToControlsDict setObject:[NSArray arrayWithObject:button] forKey:propertyName];
}

- (void)createControlsForNumericProperty:(NSDictionary*)propertyDict withName:(NSString*)propertyName inSubview:(NSBox*)subview {
	//TODO: text field (clamping to ranges
	//		if ranges are both there, slider beside text field (extra tag in dictionary for enabling sliders)
	//		if components > 1: if no sliders, text fields one next to the other
	//						   if sliders, text fields and slides one above the other

	CGFloat fontSize = [NSFont systemFontSizeForControlSize:NSSmallControlSize];
	NSFont* smallFont = [NSFont labelFontOfSize:fontSize];
	
	NSRect textRect;
	textRect.origin.x = 0.0;
	textRect.origin.y = -rowHeight * row;	
	textRect.size.width = columnWidth;
	textRect.size.height = rowHeight - rowGap;
	NSTextField* labelTextField = [[NSTextField alloc] initWithFrame:textRect];
	[labelTextField setBezeled:NO];
	[labelTextField setDrawsBackground:NO];
	[labelTextField setEditable:NO];
	[[labelTextField cell] setControlSize:NSSmallControlSize];
	[[labelTextField cell] setFont:smallFont];
	[labelTextField setStringValue:[propertyDict objectForKey:@"Label"]];
	[labelTextField sizeToFit];
	[subview addSubview:labelTextField];
	
	textRect.origin.x = columnWidth;
	textRect.size.width = columnWidth - 15;
	NSTextField* textField = [[NSTextField alloc] initWithFrame:textRect];
    //XCode4
	//[textField setDelegate:self];
	[textField setTarget:self];
	[textField setAction:@selector(controlValueChanged:)];
	[[textField cell] setControlSize:NSSmallControlSize];
	[[textField cell] setSendsActionOnEndEditing:YES];
	[[textField cell] setFont:smallFont];
	[textField setObjectValue:[targetObject displayPropertyValueWithName:propertyName]];
	[subview addSubview:textField];

	textRect.origin.x = columnWidth + columnWidth - 12;
	textRect.size.width = 12;
	NSStepper* stepper = [[NSStepper alloc] initWithFrame:textRect];
	[stepper setTarget:self];
	[stepper setAction:@selector(controlValueChanged:)];
	[[stepper cell] setControlSize:NSSmallControlSize];
	if ([propertyDict objectForKey:@"MinValue"] != nil) {
		[stepper setMinValue:[[propertyDict objectForKey:@"MinValue"] floatValue]];
	}
	if ([propertyDict objectForKey:@"MaxValue"] != nil) {
		[stepper setMaxValue:[[propertyDict objectForKey:@"MaxValue"] floatValue]];
	}
	if ([propertyDict objectForKey:@"MinValue"] != nil and [propertyDict objectForKey:@"MaxValue"] != nil) {
		[stepper setIncrement:([[propertyDict objectForKey:@"MaxValue"] floatValue] - [[propertyDict objectForKey:@"MinValue"] floatValue])/10.0];
	}
	[subview addSubview:stepper];
	
	NSInteger tag = [controlTagToPropertyDict count];
	[textField setTag:tag];
	[stepper setTag:tag];
	[controlTagToPropertyDict setObject:propertyName forKey:[NSNumber numberWithInteger:tag]];
	[propertyToControlsDict setObject:[NSArray arrayWithObjects:textField,stepper,nil] forKey:propertyName];

	if ([propertyDict objectForKey:@"MinValue"] != nil and [propertyDict objectForKey:@"MaxValue"] != nil) {
		textRect.size.width = columnWidth;
		textRect.origin.x = columnWidth;	
		textRect.origin.y -= rowHeight;	
		NSSlider* slider = [[NSSlider alloc] initWithFrame:textRect];
		[slider setMinValue:[[propertyDict objectForKey:@"MinValue"] floatValue]];
		[slider setMaxValue:[[propertyDict objectForKey:@"MaxValue"] floatValue]];
		[slider setTarget:self];
		[slider setAction:@selector(controlValueChanged:)];
		//[slider setAllowsTickMarkValuesOnly:YES];
		//[slider setNumberOfTickMarks:101];
		[[slider cell] setControlSize:NSSmallControlSize];
		[[slider cell] setSendsActionOnEndEditing:YES];
		[[slider cell] setFont:smallFont];
		[subview addSubview:slider];
		row += 1;
		[slider setTag:tag];
		[propertyToControlsDict setObject:[NSArray arrayWithObjects:textField,stepper,slider,nil] forKey:propertyName];
	}
}

- (void)createControlsForTextProperty:(NSDictionary*)propertyDict withName:(NSString*)propertyName inSubview:(NSBox*)subview {

	CGFloat fontSize = [NSFont systemFontSizeForControlSize:NSSmallControlSize];
	NSFont* smallFont = [NSFont labelFontOfSize:fontSize];
	
	NSRect textRect;
	textRect.origin.x = 0.0;
	textRect.origin.y = -rowHeight * row;
	textRect.size.width = columnWidth;
	textRect.size.height = rowHeight - rowGap;
	NSTextField* labelTextField = [[NSTextField alloc] initWithFrame:textRect];
	[labelTextField setBezeled:NO];
	[labelTextField setDrawsBackground:NO];
	[labelTextField setEditable:NO];
	[[labelTextField cell] setControlSize:NSSmallControlSize];
	[[labelTextField cell] setFont:smallFont];
	[labelTextField setStringValue:[propertyDict objectForKey:@"Label"]];
	[labelTextField sizeToFit];
	[subview addSubview:labelTextField];

	textRect.origin.x = columnWidth;
	NSTextField* textField = [[NSTextField alloc] initWithFrame:textRect];
    //XCode4
	//[textField setDelegate:self];
	[textField setTarget:self];
	[textField setAction:@selector(controlValueChanged:)];
	[[textField cell] setControlSize:NSSmallControlSize];
	[[textField cell] setSendsActionOnEndEditing:YES];
	[[textField cell] setFont:smallFont];
	[textField setObjectValue:[targetObject displayPropertyValueWithName:propertyName]];
	[subview addSubview:textField];
		
	NSInteger tag = [controlTagToPropertyDict count];
	[textField setTag:tag];
	[controlTagToPropertyDict setObject:propertyName forKey:[NSNumber numberWithInteger:tag]];
	[propertyToControlsDict setObject:[NSArray arrayWithObject:textField] forKey:propertyName];	
}

- (void)createControlsForColorProperty:(NSDictionary*)propertyDict withName:(NSString*)propertyName inSubview:(NSBox*)subview {
	CGFloat fontSize = [NSFont systemFontSizeForControlSize:NSSmallControlSize];
	NSFont* smallFont = [NSFont labelFontOfSize:fontSize];

	NSRect textRect;
	textRect.origin.x = 0.0;
	textRect.origin.y = -rowHeight * row;	
	NSTextField* labelTextField = [[NSTextField alloc] initWithFrame:textRect];
	[labelTextField setBezeled:NO];
	[labelTextField setDrawsBackground:NO];
	[labelTextField setEditable:NO];
	[[labelTextField cell] setControlSize:NSSmallControlSize];
	[[labelTextField cell] setFont:smallFont];
	[labelTextField setStringValue:[propertyDict objectForKey:@"Label"]];
	[labelTextField sizeToFit];	
	[subview addSubview:labelTextField];
	
	NSRect colorWellRect;
	colorWellRect.origin.x = columnWidth;
	colorWellRect.origin.y = -rowHeight * row;	
	colorWellRect.size.width = columnWidth;
	colorWellRect.size.height = rowHeight - rowGap;
	NSColorWell* colorWell = [[NSColorWell alloc] initWithFrame:colorWellRect];
	[colorWell setTarget:self];
	[colorWell setAction:@selector(controlValueChanged:)];
	//[[NSColorPanel sharedColorPanel] setContinuous:YES];
	//[[NSColorPanel sharedColorPanel] setAction:@selector(controlValueChanged:)];
	//[colorWell setContinuous:YES];
	[colorWell setObjectValue:[NSUnarchiver unarchiveObjectWithData:[targetObject displayPropertyValueWithName:propertyName]]];
	[subview addSubview:colorWell];	
	
	NSInteger tag = [controlTagToPropertyDict count];
	[colorWell setTag:tag];
	[controlTagToPropertyDict setObject:propertyName forKey:[NSNumber numberWithInteger:tag]];
	[propertyToControlsDict setObject:[NSArray arrayWithObject:colorWell] forKey:propertyName];
}

- (void)createControlsForDataArrayProperty:(NSDictionary*)propertyDict withName:(NSString*)propertyName inSubview:(NSBox*)subview {
	
	CGFloat fontSize = [NSFont systemFontSizeForControlSize:NSSmallControlSize];
	NSFont* smallFont = [NSFont labelFontOfSize:fontSize];

	NSRect textRect;
	textRect.origin.x = 0.0;
	textRect.origin.y = -rowHeight * row;
	NSTextField* labelTextField = [[NSTextField alloc] initWithFrame:textRect];
	[labelTextField setBezeled:NO];
	[labelTextField setDrawsBackground:NO];
	[labelTextField setEditable:NO];
	[[labelTextField cell] setControlSize:NSSmallControlSize];
	[[labelTextField cell] setFont:smallFont];
	[labelTextField setStringValue:[propertyDict objectForKey:@"Label"]];
	[labelTextField sizeToFit];
	[subview addSubview:labelTextField];
	
	NSRect boxFrame;
	boxFrame.origin.x = columnWidth;
	boxFrame.origin.y = -rowHeight * row;	
	boxFrame.size.width = columnWidth;
	boxFrame.size.height = rowHeight - rowGap;
	NSPopUpButton* box = [[NSPopUpButton alloc] initWithFrame:boxFrame];
	[[box cell] setControlSize:NSSmallControlSize];
	[[box cell] setFont:smallFont];
	//[[box cell] setBezelStyle:NSTexturedRoundedBezelStyle];
	NSString* type = [propertyDict objectForKey:@"Type"];
	NSArray* arrayNames = nil;
	if ([type isEqualToString:@"dataarray"]) {
		arrayNames = [[self targetObject] dataObjectArrayNamesForPointData:YES cellData:YES];
	}
	else if ([type isEqualToString:@"pointarray"]) {
		arrayNames = [[self targetObject] dataObjectArrayNamesForPointData:YES cellData:NO];
	}
	else if ([type isEqualToString:@"cellarray"]) {
		arrayNames = [[self targetObject] dataObjectArrayNamesForPointData:NO cellData:YES];
	}
	NSMutableArray* titles = [[NSMutableArray alloc] initWithArray:arrayNames];
	[titles insertObject:@"" atIndex:0];
	[box addItemsWithTitles:titles];
	if ([titles count] == 1) {
		[box setEnabled:NO];
	}
	[box setTarget:self];
	[box setAction:@selector(controlValueChanged:)];
	[box setObjectValue:[targetObject displayPropertyValueWithName:propertyName]];
	[subview addSubview:box];
	
	NSInteger tag = [controlTagToPropertyDict count];
	[box setTag:tag];
	[controlTagToPropertyDict setObject:propertyName forKey:[NSNumber numberWithInteger:tag]];
	[propertyToControlsDict setObject:[NSArray arrayWithObject:box] forKey:propertyName];
}

- (void)createControlsForDataNameProperty:(NSDictionary*)propertyDict withName:(NSString*)propertyName inSubview:(NSBox*)subview {
	
	CGFloat fontSize = [NSFont systemFontSizeForControlSize:NSSmallControlSize];
	NSFont* smallFont = [NSFont labelFontOfSize:fontSize];
	
	NSRect textRect;
	textRect.origin.x = 0.0;
	textRect.origin.y = -rowHeight * row;
	NSTextField* labelTextField = [[NSTextField alloc] initWithFrame:textRect];
	[labelTextField setBezeled:NO];
	[labelTextField setDrawsBackground:NO];
	[labelTextField setEditable:NO];
	[[labelTextField cell] setControlSize:NSSmallControlSize];
	[[labelTextField cell] setFont:smallFont];
	[labelTextField setStringValue:[propertyDict objectForKey:@"Label"]];
	[labelTextField sizeToFit];
	[subview addSubview:labelTextField];
	
	NSRect boxFrame;
	boxFrame.origin.x = columnWidth;
	boxFrame.origin.y = -rowHeight * row;	
	boxFrame.size.width = columnWidth;
	boxFrame.size.height = rowHeight - rowGap;
	NSPopUpButton* box = [[NSPopUpButton alloc] initWithFrame:boxFrame];
	[[box cell] setControlSize:NSSmallControlSize];
	[[box cell] setFont:smallFont];
	//[[box cell] setBezelStyle:NSTexturedRoundedBezelStyle];
	NSArray* dataTypes = [propertyDict objectForKey:@"DataTypes"];

	NSMutableArray* dataKeysWithType = [[NSMutableArray alloc] init];
	NSMutableArray* dataNamesWithType = [[NSMutableArray alloc] init];
	for (id dataType in dataTypes) {
		NSArray* keys = [[self targetObject] allListedKeysWithType:dataType];
		[dataKeysWithType addObjectsFromArray:keys];
		for (id key in keys) {
			[dataNamesWithType addObject:[[[self targetObject] dataDisplayForKey:key] name]];
		}
	}

	NSMutableArray* titles = [[NSMutableArray alloc] initWithArray:dataNamesWithType];
	[titles insertObject:@"" atIndex:0];
	[box addItemsWithTitles:titles];
	if ([titles count] == 1) {
		[box setEnabled:NO];
	}
	[box setTarget:self];
	[box setAction:@selector(controlValueChanged:)];
	[box setObjectValue:[targetObject displayPropertyValueWithName:propertyName]];
	[subview addSubview:box];
	
	NSInteger tag = [controlTagToPropertyDict count];
	[box setTag:tag];
	[controlTagToPropertyDict setObject:propertyName forKey:[NSNumber numberWithInteger:tag]];
	[propertyToControlsDict setObject:[NSArray arrayWithObject:box] forKey:propertyName];
}

- (void)createControlsForSceneTemplateProperty:(NSDictionary*)propertyDict withName:(NSString*)propertyName inSubview:(NSBox*)subview {
	
	CGFloat fontSize = [NSFont systemFontSizeForControlSize:NSSmallControlSize];
	NSFont* smallFont = [NSFont labelFontOfSize:fontSize];
	
	NSRect textRect;
	textRect.origin.x = 0.0;
	textRect.origin.y = -rowHeight * row;
	NSTextField* labelTextField = [[NSTextField alloc] initWithFrame:textRect];
	[labelTextField setBezeled:NO];
	[labelTextField setDrawsBackground:NO];
	[labelTextField setEditable:NO];
	[[labelTextField cell] setControlSize:NSSmallControlSize];
	[[labelTextField cell] setFont:smallFont];
	[labelTextField setStringValue:[propertyDict objectForKey:@"Label"]];
	[labelTextField sizeToFit];
	[subview addSubview:labelTextField];
	
	NSRect boxFrame;
	boxFrame.origin.x = columnWidth;
	boxFrame.origin.y = -rowHeight * row;	
	boxFrame.size.width = columnWidth;
	boxFrame.size.height = rowHeight - rowGap;
	NSPopUpButton* box = [[NSPopUpButton alloc] initWithFrame:boxFrame];
	[[box cell] setControlSize:NSSmallControlSize];
	[[box cell] setFont:smallFont];
	//[[box cell] setBezelStyle:NSTexturedRoundedBezelStyle];

	NSArray* availableSceneTemplates = [workspace sortedSceneTemplateNames];
	
	NSMutableArray* titles = [[NSMutableArray alloc] initWithArray:availableSceneTemplates];
	[titles insertObject:@"" atIndex:0];
	[box addItemsWithTitles:titles];
	if ([titles count] == 1) {
		[box setEnabled:NO];
	}
	[box setTarget:self];
	[box setAction:@selector(controlValueChanged:)];
	[box setObjectValue:[targetObject displayPropertyValueWithName:propertyName]];
	[subview addSubview:box];
	
	NSInteger tag = [controlTagToPropertyDict count];
	[box setTag:tag];
	[controlTagToPropertyDict setObject:propertyName forKey:[NSNumber numberWithInteger:tag]];
	[propertyToControlsDict setObject:[NSArray arrayWithObject:box] forKey:propertyName];
}

- (void)createControlsForSelectProperty:(NSDictionary*)propertyDict withName:(NSString*)propertyName inSubview:(NSBox*)subview {
	CGFloat fontSize = [NSFont systemFontSizeForControlSize:NSSmallControlSize];
	NSFont* smallFont = [NSFont labelFontOfSize:fontSize];
	
	NSRect textRect;
	textRect.origin.x = 0.0;
	textRect.origin.y = -rowHeight * row;
	NSTextField* labelTextField = [[NSTextField alloc] initWithFrame:textRect];
	[labelTextField setBezeled:NO];
	[labelTextField setDrawsBackground:NO];
	[labelTextField setEditable:NO];
	[[labelTextField cell] setControlSize:NSSmallControlSize];
	[[labelTextField cell] setFont:smallFont];
	[labelTextField setStringValue:[propertyDict objectForKey:@"Label"]];
	[labelTextField sizeToFit];
	[subview addSubview:labelTextField];
	
	NSRect boxFrame;
	boxFrame.origin.x = columnWidth;
	boxFrame.origin.y = -rowHeight * row;
	boxFrame.size.width = columnWidth;
	boxFrame.size.height = rowHeight - rowGap;
	NSPopUpButton* box = [[NSPopUpButton alloc] initWithFrame:boxFrame];
	[[box cell] setControlSize:NSSmallControlSize];
	[[box cell] setFont:smallFont];
	//[[box cell] setBezelStyle:NSTexturedRoundedBezelStyle];
	NSArray* titles = [propertyDict objectForKey:@"Values"];
	[box addItemsWithTitles:titles];
	if ([titles count] == 0) {
		[box setEnabled:NO];
	}
	[box setTarget:self];
	[box setAction:@selector(controlValueChanged:)];
	[box setObjectValue:[targetObject displayPropertyValueWithName:propertyName]];
	[subview addSubview:box];
	
	NSInteger tag = [controlTagToPropertyDict count];
	[box setTag:tag];
	[controlTagToPropertyDict setObject:propertyName forKey:[NSNumber numberWithInteger:tag]];
	[propertyToControlsDict setObject:[NSArray arrayWithObject:box] forKey:propertyName];	
}

- (void)createControlsForDataDisplay:(BJDataDisplay*)theDataDisplay {
	NSString* caseName = [[workspace caseForDataWithUniqueIdentifier:[theDataDisplay dataUniqueIdentifier]] name];
	NSString* location = nil;
	if (caseName == nil) {
		location = @"Not found";
	}
	else {
		NSString* folder = [theDataDisplay dataFolder];
		if ([folder isEqualToString:@""] == YES) {
			location = [NSString stringWithFormat:@"%@/%@",caseName,[theDataDisplay dataName]];
		}
		else {
			location = [NSString stringWithFormat:@"%@/%@/%@",caseName,folder,[theDataDisplay dataName]];
		}
	}
	
	NSString* titleString = [NSString stringWithFormat:@"%@",[theDataDisplay name]];
	NSString* subtitleString = [NSString stringWithFormat:@"\nData type: %@\nCase data: %@",[theDataDisplay dataTypeName],location];
	
	[self createControlsForTargetObject:theDataDisplay withTitle:titleString subtitle:subtitleString];
}

- (void)createControlsForScene:(BJScene*)theScene {
	NSString* titleString = [NSString stringWithFormat:@"%@",[theScene name]];
	NSString* subtitleString = [NSString stringWithFormat:@""];

	[self createControlsForTargetObject:theScene withTitle:titleString subtitle:subtitleString];
}

- (void)createControlsForTargetObject:(id)theTargetObject withTitle:(NSString*)theTitle subtitle:(NSString*)theSubtitle {
	
	//TODO: this could be implemented using an NSOutlineView with proper NSCell subclasses, one for each group.
	
//	if (theTargetObject == targetObject) {
//		return;
//	}
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"DisplayPropertyChanged" object:targetObject];

	while ([[containerView subviews] count]) {
		[[[containerView subviews] lastObject] removeFromSuperview];
	}
	
	targetObject = theTargetObject;
	targetTitle = [theTitle copy];
	targetSubtitle = [theSubtitle copy];
	
	if (targetTitle == nil) {
		targetTitle = @"";
	}

	if (targetSubtitle == nil) {
		targetSubtitle = @"";
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayPropertyHasChanged:) name:@"DisplayPropertyChanged" object:targetObject];

	NSDictionary* displayEditorPropertyList = [targetObject displayEditorPropertyList];

	CGFloat height = [containerView bounds].size.height;
	
	CGFloat yspacing = 5.0;
	
	NSPoint currentOrigin;
	currentOrigin.x = 5.0;
	currentOrigin.y = height - 5.0;

	[controlTagToPropertyDict removeAllObjects];
	[propertyToControlsDict removeAllObjects];
	
	NSString* previousGroup = nil;
	BJPropertyBox* subview = nil;
	
//	CGFloat fontSize = [NSFont systemFontSizeForControlSize:NSSmallControlSize];
	CGFloat fontSize = [NSFont systemFontSizeForControlSize:NSRegularControlSize];
	NSFont* titleFont = [NSFont boldSystemFontOfSize:fontSize];
	NSFont* subtitleFont = [NSFont fontWithName: @"LucidaGrande" size: 10.0f];

	NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:targetTitle attributes:[NSDictionary dictionaryWithObject:titleFont forKey:NSFontAttributeName]];
	NSAttributedString *subtitle = [[NSAttributedString alloc] initWithString:targetSubtitle attributes:[NSDictionary dictionaryWithObjectsAndKeys:subtitleFont,NSFontAttributeName,[NSColor darkGrayColor],NSForegroundColorAttributeName,nil]];
	[title appendAttributedString:subtitle];
	
	currentOrigin.y -= 45.0;

	NSRect textRect;
	textRect.origin = currentOrigin;
	textRect.size = NSMakeSize(0,0);
	NSTextField* labelTextField = [[NSTextField alloc] initWithFrame:textRect];
	[labelTextField setBezeled:NO];
	[labelTextField setDrawsBackground:NO];
	[labelTextField setEditable:NO];
	//[[labelTextField cell] setControlSize:NSSmallControlSize];
	//[[labelTextField cell] setFont:titleFont];
	[labelTextField setAttributedStringValue:title];
	[labelTextField sizeToFit];
	[labelTextField setAutoresizingMask:NSViewMinXMargin|NSViewMinYMargin];

	[containerView addSubview:labelTextField];

	currentOrigin.y -= yspacing;
	row += 1;

	for (id key in [displayEditorPropertyList keysSortedByValueUsingSelector:@selector(comparePropertyIds:)]) {
		NSString* propertyName = key;
		NSDictionary* propertyDict = [displayEditorPropertyList objectForKey:key];
		NSString* type = [propertyDict objectForKey:@"Type"];
		NSString* group = [propertyDict objectForKey:@"Group"];
		if (previousGroup != nil && [group isEqualToString:previousGroup] == NO) {
			[subview sizeToFit];
			NSSize size = [subview frame].size;
			if ([subview titlePosition] != NSNoTitle) {
				size.height += 10.0;
			}
			size.width = [containerView frame].size.width - 10.0;
			[subview setFrameSize:size];
			[containerView addSubview:subview];
			currentOrigin.y = currentOrigin.y - [subview frame].size.height - yspacing;
			[subview setFrameOrigin:currentOrigin];
		}
		else {
			row += 1;
		}
		if (previousGroup == nil || [group isEqualToString:previousGroup] == NO) {
			NSRect subviewFrame = NSZeroRect;
			subview = [[BJPropertyBox alloc] initWithFrame:subviewFrame];
			NSSize margins;
			margins.width = 10.0;
			margins.height = 10.0;
			[subview setContentViewMargins:margins];			
			previousGroup = group;
			row = 1;
		}		
		if ([group isEqualToString:@""] == NO) {
			[subview setTitle:group];
		}
		else {
			[subview setTitlePosition:NSNoTitle];
//			[subview setBorderType:NSNoBorder];
		}
		if ([type isEqualToString:@"boolean"] == YES) {
			[self createControlsForBooleanProperty:propertyDict withName:propertyName inSubview:subview];
		}
		else if ([type isEqualToString:@"float"] == YES || [type isEqualToString:@"integer"] == YES) {
			[self createControlsForNumericProperty:propertyDict withName:propertyName inSubview:subview];
		}
		else if ([type isEqualToString:@"text"] == YES) {
			[self createControlsForTextProperty:propertyDict withName:propertyName inSubview:subview];
		}
		else if ([type isEqualToString:@"color"] == YES) {
			[self createControlsForColorProperty:propertyDict withName:propertyName inSubview:subview];
		}
		else if ([type isEqualToString:@"dataarray"] == YES || [type isEqualToString:@"pointarray"] == YES  || [type isEqualToString:@"cellarray"] == YES) {
			[self createControlsForDataArrayProperty:propertyDict withName:propertyName inSubview:subview];
		}
		else if ([type isEqualToString:@"dataname"] == YES) {
			[self createControlsForDataNameProperty:propertyDict withName:propertyName inSubview:subview];
		}
		else if ([type isEqualToString:@"scenetemplate"] == YES) {
			[self createControlsForSceneTemplateProperty:propertyDict withName:propertyName inSubview:subview];
		}
		else if ([type isEqualToString:@"select"] == YES) {
			[self createControlsForSelectProperty:propertyDict withName:propertyName inSubview:subview];
		}
		[subview setAutoresizingMask:NSViewMinYMargin];
		[self updatePropertyWithName:propertyName];
	}
	if (subview != nil) {
		[subview sizeToFit];
		NSSize size = [subview frame].size;
		if ([subview titlePosition] != NSNoTitle) {
			size.height += 5.0;
		}
		size.width = [containerView frame].size.width - 10.0;
		[subview setFrameSize:size];
		
		[containerView addSubview:subview];
		currentOrigin.y = currentOrigin.y - [subview frame].size.height - yspacing;
		[subview setFrameOrigin:currentOrigin];
	}
	
	CGFloat totalHeight = height - currentOrigin.y + 20.0 + yspacing;
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:totalHeight], @"Height", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DisplayEditorHeightChanged" object:self userInfo:userInfo];
}

- (void)updatePropertyWithName:(NSString*)name {
	NSString* type = [[[targetObject displayEditorPropertyList] objectForKey:name] objectForKey:@"Type"];
	for (id control in [propertyToControlsDict objectForKey:name]) {
		if ([[control className] isEqualToString:@"NSPopUpButton"] == YES) {
			if ([type isEqualToString:@"dataname"] == YES) {
				id dataNameAndKey = [targetObject displayPropertyValueWithName:name];
				id key = [dataNameAndKey objectForKey:@"Key"];
				if (key != nil and [key isEqualToString:@""] == NO) {
					[control selectItemWithTitle:[dataNameAndKey objectForKey:@"Name"]];
				}
				else {
					[control selectItemWithTitle:@""];
				}
			}
			else {
				[control selectItemWithTitle:[targetObject displayPropertyValueWithName:name]];
			}
		}
		else if ([[control className] isEqualToString:@"NSTextField"] == YES) {
			if ([type isEqualToString:@"float"] == YES) {
				NSString* value = [targetObject displayPropertyValueWithName:name];
				if ([value floatValue] > 1.0) {
					[control setObjectValue:[NSString stringWithFormat:@"%.2f",[value floatValue]]];
				}
				else {
					[control setObjectValue:value];
				}
			}
			else if ([type isEqualToString:@"integer"] == YES) {
				NSString* value = [targetObject displayPropertyValueWithName:name];
				[control setObjectValue:[NSString stringWithFormat:@"%d",[value intValue]]];
			}
		}
		else {
			[control setObjectValue:[targetObject displayPropertyValueWithName:name]];		
		}
	}
}

- (void)displayPropertyHasChanged:(NSNotification*)notification {
	NSString* name = [[notification userInfo] objectForKey:@"Name"];
	[self updatePropertyWithName:name];
}

- (IBAction)controlValueChanged:(id)sender {
	id value = [sender objectValue];
	if ([[sender className] isEqualToString:@"NSPopUpButton"] == YES) {
		value = [[sender itemTitles] objectAtIndex:[[sender objectValue] intValue]];
	}
	else if ([[sender className] isEqualToString:@"NSColorWell"] == YES) {
		value = [NSArchiver archivedDataWithRootObject:[sender color]];
	}
	NSString* propertyName = [controlTagToPropertyDict objectForKey:[NSNumber numberWithInteger:[sender tag]]];
	
	NSString* type = [[[targetObject displayEditorPropertyList] objectForKey:propertyName] objectForKey:@"Type"];
	if ([type isEqualToString:@"dataname"] == YES) {
		id keys = [targetObject keysForDataDisplayWithName:value];
		if ([keys count] > 0) {
			[targetObject setDisplayPropertyValue:[NSDictionary dictionaryWithObjectsAndKeys:[keys objectAtIndex:0],@"Key",value,@"Name",nil] withName:propertyName];
		}
		else {
			[targetObject setDisplayPropertyValue:[NSDictionary dictionaryWithObjectsAndKeys:@"",@"Key",@"",@"Name",nil] withName:propertyName];
		}
	}
	else if ([type isEqualToString:@"scenetemplate"] == YES) {
		[targetObject setDisplayPropertyValue:value withName:propertyName];
		[targetObject applySceneTemplate:[workspace sceneTemplateWithName:value]];
	}
	else {
		[targetObject setDisplayPropertyValue:value withName:propertyName];
	}
}

@end
