//
//  DownloadController.m
//  NXT Browser
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "DownloadController.h"

@interface DownloadController ()

- (void)openRead;
- (void)loadData:(MRNXTHandleSizeResponse *)resp;
- (void)loadedData:(NSData *)data;
- (void)done;

@end


@implementation DownloadController

@synthesize device = _device;
@synthesize filename = _filename;
@synthesize destination = _destination;

#define READ_BLOCK_SIZE 58

- (void)windowDidLoad {
	[super windowDidLoad];
	
	[self openRead];
}

- (void)openRead {
	_loadedData = [[NSMutableData alloc] init];
	
	self.prompt = [NSString stringWithFormat:@"Downloading '%@'...", _filename];
	
	MRNXTOpenReadCommand *or = [[MRNXTOpenReadCommand alloc] init];
	or.filename = _filename;
	
	[_device enqueueCommand:or responseBlock:^(MRNXTHandleSizeResponse *resp) {
		
		if (resp.status == NXTStatusSuccess) {
			[self loadData:resp];
		}
		
	}];
}

- (void)loadData:(MRNXTHandleSizeResponse *)resp {
	_totalSize = resp.size;
	
	for (uint16_t sz = 0; sz < resp.size; sz += READ_BLOCK_SIZE) {
		MRNXTReadCommand *rc = [[MRNXTReadCommand alloc] init];
		rc.handle = resp.handle;
		rc.bytesToRead = MIN_INT(READ_BLOCK_SIZE, resp.size - sz);
		
		[_device enqueueCommand:rc responseBlock:^(MRNXTDataResponse *resp) {
			[self loadedData:resp.data];
		}];
	}
	
	MRNXTCloseCommand *cc = [[MRNXTCloseCommand alloc] init];
	cc.handle = resp.handle;
	
	[_device enqueueCommand:cc responseBlock:^(MRNXTResponse *resp) {
		[self done];
	}];
}

- (void)loadedData:(NSData *)data {
	[_loadedData appendData:data];
	
	self.progress = [_loadedData length] / (float) _totalSize;
}

- (void)done {
	NSString *path = [_destination stringByAppendingPathComponent:_filename];
	[_loadedData writeToFile:path atomically:YES];
	
	[self dismissSheet];
}

@end
