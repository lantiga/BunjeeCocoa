//
//  BJConsoleController.mm
//  Bunjee
//  Created by Luca Antiga on 7/23/10.
//  Copyright 2010-2011 Orobix. All rights reserved.
//

#import "BJConsoleController.h"
#import "Bunjee/BJCase.h"
#import "Bunjee/BJData.h"


@implementation BJConsoleController

- (id)init {
	self = [self initWithNibName:@"ConsoleView" bundle:[NSBundle bundleWithIdentifier:@"orobix.BunjeeUI"]];
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(consoleShouldAppendText:) name:@"LogMessageSent" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(consoleShouldClear:) name:@"LogShouldReset" object:nil];
    }
    return self;
}

- (void)awakeFromNib {
	[[consoleView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[[consoleView textContainer] setWidthTracksTextView:NO];
	[consoleView setHorizontallyResizable:YES];
}

- (void)finalize {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"LogMessageSent" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"LogShouldReset" object:nil];
	[super finalize];
}

- (void)consoleShouldAppendText:(NSNotification*)notification {
	NSString* logMessage = [[notification userInfo] objectForKey:@"Text"];
	[self performSelectorOnMainThread:@selector(appendTextToConsole:) withObject:logMessage waitUntilDone:YES];
}

- (void)appendTextToConsole:(NSString*)text {
	NSString* formattedText = text;
	if ([[consoleView string] length] > 0) {
		formattedText = [NSString stringWithFormat:@"\n%@",text];
	}
	[[consoleView textStorage] appendAttributedString:[[NSAttributedString alloc] initWithString:formattedText attributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"LucidaGrande" size:10.0] forKey:NSFontAttributeName]]];
    [consoleView scrollRangeToVisible:NSMakeRange([[consoleView string] length],0)];
}

- (void)setTextToConsole:(NSString*)text {
	[[consoleView textStorage] setAttributedString:[[NSAttributedString alloc] initWithString:text attributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"LucidaGrande" size:10.0] forKey:NSFontAttributeName]]];
}

- (void)consoleShouldClear:(NSNotification*)notification {
	[self clearConsole:self];
}

- (IBAction)clearConsole:(id)sender {
	[self performSelectorOnMainThread:@selector(setTextToConsole:) withObject:[NSString string] waitUntilDone:YES];	
}

@end
