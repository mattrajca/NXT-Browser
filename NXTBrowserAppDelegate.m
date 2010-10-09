//
//  NXTBrowserAppDelegate.m
//  NXT Browser
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "NXTBrowserAppDelegate.h"

#import <IOBluetoothUI/IOBluetoothUI.h>

@interface NXTBrowserAppDelegate ()

- (void)showBTDeviceSelector;
- (BOOL)foundUSBBrick;

@end


@implementation NXTBrowserAppDelegate

- (id)init {
	self = [super init];
	if (self) {
		_browsers = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	if (![self foundUSBBrick]) {
		[self showBTDeviceSelector];
	}
}

- (void)showBTDeviceSelector {
	IOBluetoothDeviceSelectorController *ctrl = [IOBluetoothDeviceSelectorController deviceSelector];
	int res = [ctrl runModal];
	
	if (res != kIOBluetoothUISuccess) {
		if (res == kIOBluetoothUIUserCanceledErr) {
			[NSApp terminate:nil];
		}
		
		return;
	}
	
	NSArray *results = [ctrl getResults];
	
	if ([results count] == 0) {
		[NSApp terminate:nil];
		return;
	}
	
	IOBluetoothDevice *firstDevice = [results objectAtIndex:0];
	
	BrowserWindowController *win = [[BrowserWindowController alloc] initWithDevice:firstDevice];
	[win showWindow:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(closedBrowser:)
												 name:NSWindowWillCloseNotification
											   object:[win window]];
	
	[_browsers addObject:win];
}

- (void)closedBrowser:(id)sender {
	[self performSelector:@selector(cleanupBrowser) withObject:nil afterDelay:0.0f];
}

- (void)cleanupBrowser {
	[_browsers removeLastObject];
	[self showBTDeviceSelector];	
}

- (BOOL)foundUSBBrick {
	return NO;
}

@end
