//
//  NXTBrowserAppDelegate.m
//  NXT Browser
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "NXTBrowserAppDelegate.h"

#import <IOBluetoothUI/IOBluetoothUI.h>

@interface NXTBrowserAppDelegate ()

- (void)showBTDeviceSelector;
- (void)showBrowserWithTransport:(MRDeviceTransport *)transport;

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
	NSArray *usbDevices = [MRUSBDeviceEntry matchingDevicesForProductID:0x2 vendorID:0x694];
	
	if ([usbDevices count]) {
		MRUSBDeviceEntry *entry = [usbDevices objectAtIndex:0];
		
		NSArray *pipes = [NSArray arrayWithObjects:
						  [MRUSBDevicePipeDescriptor pipeDescriptorWithTransferType:MRUSBTransferTypeBulk
																		  direction:MRUSBTransferDirectionIn],
						  [MRUSBDevicePipeDescriptor pipeDescriptorWithTransferType:MRUSBTransferTypeBulk
																		  direction:MRUSBTransferDirectionOut], nil];
		
		MRUSBDeviceTransport *t = [[MRUSBDeviceTransport alloc] initWithDeviceEntry:entry
																	   desiredPipes:pipes];
		
		[self showBrowserWithTransport:t];
	}
	else {
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
	MRBluetoothDeviceTransport *t = [[MRBluetoothDeviceTransport alloc] initWithBluetoothDevice:firstDevice];
	
	[self showBrowserWithTransport:t];
}

- (void)showBrowserWithTransport:(MRDeviceTransport *)transport {
	BrowserWindowController *wc = [[BrowserWindowController alloc] initWithDeviceTransport:transport];
	[wc showWindow:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(closedBrowser:)
												 name:NSWindowWillCloseNotification
											   object:[wc window]];
	
	[_browsers addObject:wc];
}

- (void)closedBrowser:(id)sender {
	[self performSelector:@selector(cleanupBrowser) withObject:nil afterDelay:0.0f];
}

- (void)cleanupBrowser {
	[_browsers removeLastObject];
	[NSApp terminate:nil];
}

@end
