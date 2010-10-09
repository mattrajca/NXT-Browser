//
//  DownloadController.h
//  NXT Browser
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "ProgressWindowController.h"

@interface DownloadController : ProgressWindowController {
  @private
	__weak MRNXTDevice *_device;
	NSString *_filename;
	NSString *_destination;
	uint32_t _totalSize;
	
	NSMutableData *_loadedData;
}

@property (nonatomic, assign) __weak MRNXTDevice *device;
@property (nonatomic, copy) NSString *filename;
@property (nonatomic, copy) NSString *destination;

@end
