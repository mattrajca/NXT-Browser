//
//  UploadController.h
//  NXT Browser
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "ProgressWindowController.h"

typedef void (^UploadedFileBlock) (NSString *filename, uint16_t size);

@interface UploadController : ProgressWindowController {
  @private
	__weak MRNXTDevice *_device;
	NSString *_filename;
	NSData *_data;
	NSUInteger _currIdx;
	UploadedFileBlock _uploadedFileBlock;
}

@property (nonatomic, assign) __weak MRNXTDevice *device;
@property (nonatomic, copy) UploadedFileBlock uploadedFileBlock;

- (id)initWithSourcePath:(NSString *)aPath;

@end
