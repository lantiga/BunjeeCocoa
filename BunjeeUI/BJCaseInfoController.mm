//
//  BJCaseInfoController.mm
//  Bunjee
//  Created by Luca Antiga on 2/7/11.
//  Copyright 2011 Orobix. All rights reserved.
//

#import "BJCaseInfoController.h"
#import "Bunjee/BJWorkspace.h"
#import "Bunjee/BJCase.h"
#import "Bunjee/BJData.h"

@implementation BJCaseInfoController

@synthesize workspace;
@synthesize caseName;

- (id)init {
	self = [self initWithNibName:@"CaseInfoView" bundle:[NSBundle bundleWithIdentifier:@"orobix.BunjeeUI"]];
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];	
    if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldShowInfoForCase:) name:@"ShouldShowInfoForCase" object:nil];
		caseName = [NSString string];
		caseInfoTableData = nil;
    }
    return self;
}

- (void)awakeFromNib {
    //XCode4
	//[caseInfoView setDataSource:self];
}

- (void)finalize {
	[super finalize];
}

- (void)shouldShowInfoForCase:(NSNotification*)notification {
	
	NSString* currentCaseName = [[notification userInfo] objectForKey:@"CaseName"];
	id currentFolder = [[notification userInfo] objectForKey:@"Folder"];
	id currentDataName = [[notification userInfo] objectForKey:@"DataName"];
	NSString* currentPath = [[notification userInfo] objectForKey:@"Path"];

	[pathControl setURL:[NSURL URLWithString:currentPath]];
	
	[self setCaseName:currentCaseName];

	caseInfoTableData = [[NSMutableArray alloc] init];
	
	id theCase = [workspace caseWithName:caseName];
	
	NSDictionary* foldersToKeys = [theCase foldersToKeys];
	NSMutableArray* folders = [NSMutableArray arrayWithArray:[foldersToKeys allKeys]];
	BOOL hasNull = NO;
	if ([foldersToKeys objectForKey:[NSNull null]] != nil) {
		hasNull = YES;
		[folders removeObject:[NSNull null]]; 
	}
	
	NSMutableArray* sortedFolders = [NSMutableArray arrayWithArray:[folders sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
	[sortedFolders insertObject:[NSNull null] atIndex:0];
	for (id folder in sortedFolders) {
		if (currentFolder != [NSNull null]) {
			//TODO: in case folder is subfolder of currentFolder, avoid skipping it
			if ([currentFolder isEqualToString:folder] == NO) {
				continue;
			}
		}
		NSMutableArray* folderOutputLines = [NSMutableArray array];
		id keys = [foldersToKeys objectForKey:folder];
		BOOL showFolder = NO;
		if (folder != [NSNull null]) {
			if (currentFolder == [NSNull null]) {
				showFolder = YES;
			}
			else {
				if ([folder isEqualToString:currentFolder] == NO) {
					showFolder = YES;
				}
			}
		}
		if (showFolder == YES) {
			[folderOutputLines addObject:[NSDictionary dictionaryWithObjectsAndKeys:folder,@"Data",[NSNull null],@"Index",[NSNull null],@"Value",[NSNull null],@"Unit",nil]];
		}
		BOOL anyInfoFound = NO;
		for (id key in keys) {
			id theData = [theCase dataForKey:key];
			if (currentDataName != [NSNull null]) {
				if ([currentDataName isEqualToString:[theData name]] == NO) {
					continue;
				}
			}
			if ([theData listed] == NO) {
				continue;
			}
			NSArray* infoNames = [[theData infoPropertyList] allKeys];
			NSArray* sortedInfoNames = [infoNames sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
			BOOL first = YES;
			for (id name in sortedInfoNames) {
				NSString* outputValueString;
				if ([[theData typeForInfo:name] isEqualToString:@"float"] == YES) {
					double value = [[theData valueForInfo:name] doubleValue];
					NSString* valueFormat = @"%.2f";
					if (fabs(value) < 1.0) {
						valueFormat = @"%.4f";
					}
					outputValueString = [NSString stringWithFormat:valueFormat,value];
				}
				else {
					outputValueString = [NSString stringWithFormat:@"%@",[theData valueForInfo:name]];
				}
				id dataColumn = [NSNull null];
				if (first == YES) {
					dataColumn = [[theData name] copy];
				}
				[folderOutputLines addObject:[NSDictionary dictionaryWithObjectsAndKeys:dataColumn,@"Data",[theData labelForInfo:name],@"Index",outputValueString,@"Value",[theData unitForInfo:name],@"Unit",nil]];
				anyInfoFound = YES;
				first = NO;
			}
		}
		if (anyInfoFound) {
			[caseInfoTableData addObjectsFromArray:folderOutputLines];
		}
	}

	[caseInfoView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [caseInfoTableData count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	id theRecord = [caseInfoTableData objectAtIndex:rowIndex];
    id theValue = [theRecord objectForKey:[aTableColumn identifier]];
	if (theValue == [NSNull null]) {
		theValue = [NSString string];
	}
	if ([theRecord objectForKey:@"Value"] == [NSNull null]) {
		CGFloat fontSize = [NSFont systemFontSizeForControlSize:NSSmallControlSize];
		NSFont* folderFont = [NSFont boldSystemFontOfSize:fontSize];
		theValue = [[NSAttributedString alloc] initWithString:theValue attributes:[NSDictionary dictionaryWithObject:folderFont forKey:NSFontAttributeName]];
	}
    return theValue;
}

- (IBAction)copyText:(id)sender {
	NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
	NSMutableString* tableString = [[NSMutableString alloc] init];
	for (id theRecord in caseInfoTableData) {
		id dataName = [theRecord objectForKey:@"Data"];
		if (dataName == [NSNull null]) {
			dataName = @"";
		}
		id index = [theRecord objectForKey:@"Index"];
		if (index == [NSNull null]) {
			index = @"";
		}		
		id value = [theRecord objectForKey:@"Value"];
		if (value == [NSNull null]) {
			value = @"";
		}
		id unit = [theRecord objectForKey:@"Unit"];
		if (unit == [NSNull null]) {
			unit = @"";
		}		
		[tableString appendFormat:@"%@\t%@\t%@\t%@\n",dataName,index,value,unit];
	}
	[pasteboard declareTypes:[NSArray arrayWithObjects:NSTabularTextPboardType, NSStringPboardType, nil] owner:nil];
	[pasteboard setString:[tableString copy] forType:NSTabularTextPboardType];
	[pasteboard setString:[tableString copy] forType:NSStringPboardType];
}

@end
