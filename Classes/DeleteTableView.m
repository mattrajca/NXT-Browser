//
//  DeleteTableView.m
//  NXT Browser
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "DeleteTableView.h"

@implementation DeleteTableView

@synthesize deleteCallback = _deleteCallback;

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	if ([menuItem action] == @selector(delete:)) {
		return [[self selectedRowIndexes] count] > 0;
	}
	
	return [super validateMenuItem:menuItem];
}

- (IBAction)delete:(id)sender {
	if (_deleteCallback) {
		_deleteCallback([self selectedRow]);
	}
}

@end
