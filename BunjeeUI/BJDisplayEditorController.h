//
//  BJDisplayEditorController.h
//  Bunjee
//  Created by Luca Antiga on 5/14/10.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BJPropertyBox : NSBox {
}

@end

@class BJDataDisplay;
@class BJScene;
@class BJWorkspace;

@interface NSDictionary(propertyDictionary)

- (NSComparisonResult)comparePropertyIds:(id)obj2;

@end 

@interface BJDisplayEditorController : NSViewController {
	id targetObject;
	NSString* targetTitle;
	NSString* targetSubtitle;
	NSView* containerView;
	NSMutableDictionary* controlTagToPropertyDict;
	NSMutableDictionary* propertyToControlsDict;
	CGFloat columnWidth;
	CGFloat rowHeight; 
	CGFloat rowGap; 
	NSUInteger row;
	BJWorkspace* workspace;
}

@property(readonly) id targetObject;
@property(readonly) NSString* targetTitle;
@property(readonly) NSString* targetSubtitle;
@property(readwrite,retain) BJWorkspace* workspace;

- (void)sceneBrowserSelectionHasChanged:(NSNotification*)notification;

- (void)createControlsForTargetObject:(id)theTargetObject withTitle:(NSString*)theTitle subtitle:(NSString*)theSubtitle;

- (void)rebuildControlsForTargetObject;

- (void)createControlsForDataDisplay:(BJDataDisplay*)theDataDisplay; 
- (void)createControlsForScene:(BJScene*)theScene; 
- (void)clearControls; 

- (void)createControlsForBooleanProperty:(NSDictionary*)propertyDict withName:(NSString*)propertyName inSubview:(NSBox*)subview;
- (void)createControlsForNumericProperty:(NSDictionary*)propertyDict withName:(NSString*)propertyName inSubview:(NSBox*)subview;
- (void)createControlsForTextProperty:(NSDictionary*)propertyDict withName:(NSString*)propertyName inSubview:(NSBox*)subview;
- (void)createControlsForColorProperty:(NSDictionary*)propertyDict withName:(NSString*)propertyName inSubview:(NSBox*)subview;
- (void)createControlsForDataArrayProperty:(NSDictionary*)propertyDict withName:(NSString*)propertyName inSubview:(NSBox*)subview;
- (void)createControlsForDataNameProperty:(NSDictionary*)propertyDict withName:(NSString*)propertyName inSubview:(NSBox*)subview;
- (void)createControlsForSceneTemplateProperty:(NSDictionary*)propertyDict withName:(NSString*)propertyName inSubview:(NSBox*)subview;

- (IBAction)controlValueChanged:(id)sender;

- (void)updatePropertyWithName:(NSString*)name;

@end
