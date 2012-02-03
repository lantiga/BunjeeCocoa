//
//  BJCaseInfoController.h
//  Bunjee
//  Created by Luca Antiga on 2/7/11.
//  Copyright 2011 Orobix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BJWorkspace;

@interface BJCaseInfoController : NSViewController {
	IBOutlet NSTableView* caseInfoView;
	NSMutableArray* caseInfoTableData;
	IBOutlet NSPathControl* pathControl;
	NSString* caseName;
	BJWorkspace* workspace;
}

@property(readwrite,retain) BJWorkspace* workspace;
@property(readwrite,copy) NSString* caseName;

- (IBAction)copyText:(id)sender;

@end
