//
//  ProgressWindowController.m
//  NXT Browser
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "ProgressWindowController.h"

@implementation ProgressWindowController

@synthesize closedCallback = _callback;

@dynamic prompt, progress;

- (id)init {
	return [super initWithWindowNibName:@"ProgressWindow"];
}

- (void)presentAsSheetInWindow:(NSWindow *)parentWindow {
	NSWindow *window = [self window];
	
	[NSApp beginSheet:window modalForWindow:parentWindow
		modalDelegate:self
	   didEndSelector:@selector(windowDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
}

- (void)windowDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode
		 contextInfo:(void *)contextInfo {
	
	_callback();
}

- (NSString *)prompt {
	return [_label stringValue];
}

- (void)setPrompt:(NSString *)prompt {
	[_label setStringValue:prompt];
}

- (double)progress {
	return [_indicator doubleValue];
}

- (void)setProgress:(double)val {
	[_indicator setDoubleValue:val];
}

- (void)dismissSheet {
	[NSApp endSheet:[self window]];
	[self close];
}

@end
