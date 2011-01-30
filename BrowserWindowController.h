//
//  BrowserWindowController.h
//  NXT Browser
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

@class DeleteTableView, ProgressWindowController;

@interface BrowserWindowController : NSWindowController < NSWindowDelegate, NSTableViewDelegate, NSTableViewDataSource, MRDeviceDelegate > {
	
  @private
	DeleteTableView *_tableView;
	NSArrayController *_files;
	NSTextField *_statusLabel;
	
	MRNXTDevice *_device;
	id _pwc;
}

@property (nonatomic, assign) IBOutlet DeleteTableView *tableView;
@property (nonatomic, assign) IBOutlet NSArrayController *files;
@property (nonatomic, assign) IBOutlet NSTextField *statusLabel;

- (id)initWithDeviceTransport:(MRDeviceTransport *)transport;

- (IBAction)uploadFile:(id)sender;
- (IBAction)downloadFile:(id)sender;

- (IBAction)reload:(id)sender;

- (IBAction)startPlay:(id)sender;

@end
