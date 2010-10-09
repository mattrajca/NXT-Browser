//
//  UploadController.m
//  NXT Browser
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "UploadController.h"

@interface UploadController ()

- (void)openWrite;
- (void)enqueueWrites:(uint8_t)handle;
- (void)done:(uint8_t)handle;

@end


@implementation UploadController

@synthesize device = _device;
@synthesize uploadedFileBlock = _uploadedFileBlock;

#define WRITE_BLOCK_SIZE 64

- (id)initWithSourcePath:(NSString *)aPath {
	NSParameterAssert(aPath != nil);
	
	self = [super init];
	if (self) {
		_filename = [[aPath lastPathComponent] retain];
		_data = [[NSData alloc] initWithContentsOfFile:aPath];
	}
	return self;
}

- (void)windowDidLoad {
	[super windowDidLoad];
	
	[self openWrite];
}

- (void)openWrite {
	self.prompt = [NSString stringWithFormat:@"Uploading '%@'...", _filename];
	
	MRNXTOpenWriteCommand *ow = [[MRNXTOpenWriteCommand alloc] init];
	ow.size = [_data length];
	ow.filename = _filename;
	
	[_device enqueueCommand:ow responseBlock:^(MRNXTHandleResponse *resp) {
		
		if (resp.status == NXTStatusSuccess) {
			[self enqueueWrites:resp.handle];
		}
		
	}];
}

- (void)enqueueWrites:(uint8_t)handle {
	NSUInteger totalLength = [_data length];
	
	for (uint16_t idx = 0; idx < totalLength; idx += WRITE_BLOCK_SIZE) {
		NSUInteger bytesToWrite = MIN_INT(totalLength - idx, WRITE_BLOCK_SIZE);
		
		MRNXTWriteCommand *wr = [[MRNXTWriteCommand alloc] init];
		wr.handle = handle;
		wr.data = [_data subdataWithRange:NSMakeRange(idx, bytesToWrite)];
		
		[_device enqueueCommand:wr responseBlock:^(MRNXTHandleSizeResponse *resp) {
			
			_currIdx += resp.size;
			self.progress = _currIdx / (float) totalLength;
			
		}];
	}
	
	[self done:handle];
}

- (void)done:(uint8_t)handle {
	MRNXTCloseCommand *close = [[MRNXTCloseCommand alloc] init];
	close.handle = handle;
	
	[_device enqueueCommand:close responseBlock:^(MRNXTResponse *resp) {
		
		[self dismissSheet];
		
		if (_uploadedFileBlock) {
			_uploadedFileBlock(_filename, _currIdx);
		}
		
	}];
}

@end
