//
//  BJConsoleController.h
//  Bunjee
//  Created by Luca Antiga on 7/23/10.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BJCase;

@interface BJConsoleController : NSViewController {
	IBOutlet NSTextView* consoleView;
}

- (IBAction)clearConsole:(id)sender;

@end
