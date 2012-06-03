//
//  DeleteTableView.m
//  NXT Browser
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "DeleteTableView.h"

@implementation DeleteTableView

@synthesize deleteCallback = _deleteCallback;

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
	if ([anItem action] == @selector(delete:)) {
		return [[self selectedRowIndexes] count] > 0;
	}
	
	return [super validateUserInterfaceItem:anItem];
}

- (IBAction)delete:(id)sender {
	if (_deleteCallback) {
		_deleteCallback([self selectedRow]);
	}
}

@end
