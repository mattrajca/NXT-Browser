//
//  BrowserWindowController.m
//  NXT Browser
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "BrowserWindowController.h"

#import "DeleteTableView.h"
#import "DownloadController.h"
#import "UploadController.h"
#import "NXT.h"

@interface BrowserWindowController ()

- (void)windowDidAppear;

- (NSDictionary *)fileWithName:(NSString *)name size:(uint16_t)size;
- (NSString *)selectedFileName;
- (NSString *)fileNameAtIndex:(NSUInteger)idx;

- (void)setupDeviceTransport:(MRDeviceTransport *)transport;
- (void)getDeviceInfo;

- (void)loadFiles;
- (void)handleFileResponse:(MRNXTFileResponse *)resp;

- (void)displayDownloadControllerWithDestinationPath:(NSString *)dp filename:(NSString *)fn;
- (void)selectedDestinationDirectory:(NSString *)dp;

@end


@implementation BrowserWindowController

@synthesize tableView = _tableView;
@synthesize files = _files;
@synthesize statusLabel = _statusLabel;

- (id)initWithDeviceTransport:(MRDeviceTransport *)transport {
	self = [super initWithWindowNibName:@"BrowserWindow"];
	if (self) {
		[self setupDeviceTransport:transport];
	}
	return self;
}

- (void)awakeFromNib {
	[_tableView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
	[_tableView setDraggingSourceOperationMask:NSDragOperationAll forLocal:NO];
	
	_tableView.deleteCallback = ^(NSUInteger row) {
		
		NSDictionary *file = [[_files arrangedObjects] objectAtIndex:row];
		
		MRNXTDeleteCommand *del = [[MRNXTDeleteCommand alloc] init];
		del.filename = [file valueForKey:@"name"];
		
		[_device enqueueCommand:del
				  responseBlock:^(MRNXTResponse *resp) {
					  
					  [_files removeObject:file];
					  
				  }];
	};
}

#pragma mark Window

- (void)windowDidAppear {
	[[self window] setDelegate:self];
}

- (void)showWindow:(id)sender {
	[super showWindow:sender];
	
	[self windowDidAppear];
}

- (void)windowWillClose:(NSNotification *)notification {
	[_device close];
}

#pragma mark UI

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	SEL action = [menuItem action];
	
	if (action == @selector(reload:) || action == @selector(uploadFile:)) {
		return _device.open;
	}
	else if (action == @selector(downloadFile:)) {
		return _device.open && [_tableView selectedRow] >= 0;
	}
	
	return YES;
}

- (NSArray *)tableView:(NSTableView *)tableView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination 
forDraggedRowsWithIndexes:(NSIndexSet *)indexSet {
	
	NSString *name = [self fileNameAtIndex:[indexSet firstIndex]];
	NSString *dp = [dropDestination path];
	
	[self displayDownloadControllerWithDestinationPath:dp filename:name];
	
	return [NSArray arrayWithObject:name];
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes
	 toPasteboard:(NSPasteboard *)pboard {
	
	[pboard declareTypes:[NSArray arrayWithObject:NSFilesPromisePboardType]
				   owner:self];
	
	NSString *ext = [[self fileNameAtIndex:[rowIndexes firstIndex]] pathExtension];
	
	[pboard setPropertyList:[NSArray arrayWithObject:ext]
					forType:NSFilesPromisePboardType];
	
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id < NSDraggingInfo >)info
				 proposedRow:(NSInteger)row
	   proposedDropOperation:(NSTableViewDropOperation)dropOperation {
	
	[tableView setDropRow:-1 dropOperation:NSTableViewDropOn];
	
	if (!_device.open)
		return NSDragOperationNone;
	
	return NSDragOperationEvery;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id < NSDraggingInfo >)info
			  row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
	
	NSArray *names = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	
	if (![names count])
		return NO;
	
	NSString *first = [names objectAtIndex:0];
	[self performSelector:@selector(selectedFileToUpload:) withObject:first afterDelay:0.0f];
	
	return YES;
}

#pragma mark Utility

- (NSDictionary *)fileWithName:(NSString *)name size:(uint16_t)size {
	NSString *sizeString = [NSString stringWithFormat:@"%.2f KB", size / 1024.0f];
    
    NXTFileType fileType = [self fileTypeFromName:name];
    NSString *fileTypeString = @"Unknown";
    switch (fileType) {
        case NXTFileUserProgram:
            fileTypeString = NSLocalizedString(@"NXTFileUserProgram", nil);
            break;
        case NXTFileSampleProgram:
            fileTypeString = NSLocalizedString(@"NXTFileSampleProgram", nil);
            break;
        case NXTFileSystemProgram:
            fileTypeString = NSLocalizedString(@"NXTFileSystemProgram", nil);
            break;
        case NXTFileSound:
            fileTypeString = NSLocalizedString(@"NXTFileSound", nil);
            break;
        case NXTFileImage:
            fileTypeString = NSLocalizedString(@"NXTFileImage", nil);
            break;
        default:
            break;
    }
	
	NSDictionary *file = [NSDictionary dictionaryWithObjectsAndKeys:
						  name, @"name", sizeString, @"size", fileTypeString, @"type", nil];
	
	return file;
}

- (NSString *)selectedFileName {
	return [self fileNameAtIndex:[_tableView selectedRow]];
}

- (NSString *)fileNameAtIndex:(NSUInteger)idx {
	return [[[_files arrangedObjects] objectAtIndex:idx] valueForKey:@"name"];
}

- (NXTFileType)fileTypeFromName:(NSString *) name {
    if ([name rangeOfString:@".rxe"].location != NSNotFound) {
        return NXTFileUserProgram;
	}
    else if ([name rangeOfString:@".rtm"].location != NSNotFound) {
        return NXTFileSampleProgram;
	}
    else if ([name rangeOfString:@".sys"].location != NSNotFound) {
        return NXTFileSystemProgram;
	}
	else if ([name rangeOfString:@".rso"].location != NSNotFound) {
        return NXTFileSound;
	}
    else if ([name rangeOfString:@".ric"].location != NSNotFound) {
        return NXTFileImage;
	}
    else {
        return NXTFileUnknown;
    }
}

#pragma mark Device

- (void)setupDeviceTransport:(MRDeviceTransport *)transport {
	NSError *error = nil;
	
	_device = [[MRNXTDevice alloc] initWithTransport:transport];
	[_device setDelegate:self];
	
	if (![_device open:&error]) {
		[NSApp presentError:error];
		[self close];
	}
}

- (void)deviceDidOpen:(MRDevice *)aDevice {
	[_statusLabel setStringValue:NSLocalizedString(@"LoadingInformation", nil)];
	
	[self getDeviceInfo];
	[self loadFiles];
}

- (void)device:(MRDevice *)aDevice didFailToOpen:(NSError *)error {
	[NSApp presentError:error];
	[self close];
}

- (void)deviceDidClose:(MRDevice *)aDevice {
	NSWindow *sheet = [[self window] attachedSheet];
	
	if (sheet) {
		[NSApp endSheet:sheet];
		[sheet orderOut:nil];
	}
	
	[self close];
}

- (void)getDeviceInfo {
	MRNXTGetDeviceInfoCommand *gc = [[MRNXTGetDeviceInfoCommand alloc] init];
	
	[_device enqueueCommand:gc
			  responseBlock:^(MRNXTDeviceInfoResponse *resp) {
				  
				  NSString *str = [NSString stringWithFormat:NSLocalizedString(@"ConnectedStringFormat", nil),
								   resp.brickName, resp.freeSpace / 1024.0f];
				  
				  [_statusLabel setStringValue:str];
				  
			  }];
}

#pragma mark Files

- (void)loadFiles {
	MRNXTFindFirstCommand *fc = [[MRNXTFindFirstCommand alloc] init];
	fc.filename = @"*.*";
	
	[_device enqueueCommand:fc
			  responseBlock:^(MRNXTFileResponse *resp) {
				  
				  [self handleFileResponse:resp];
	}];
}

- (void)handleFileResponse:(MRNXTFileResponse *)resp {
	if (resp.status != NXTFileNotFound) {
		MRNXTFindNextCommand *next = [[MRNXTFindNextCommand alloc] init];
		next.handle = resp.handle;
		
		[_files addObject:[self fileWithName:resp.filename size:resp.size]];
		
		[_device enqueueCommand:next
				  responseBlock:^(MRNXTFileResponse *nresp) {
					  
					  [self handleFileResponse:nresp];
					  
				  }];
	}	
}

#pragma mark Actions

- (IBAction)reload:(id)sender {
	[_files removeObjects:[_files arrangedObjects]];
	
	[self loadFiles];
}

- (IBAction)startPlay:(id)sender {
	if (!_device.open)
		return;
	
	if ([_files selectionIndex] == NSNotFound)
		return;
	
	NSString *name = [self selectedFileName];
	
    NXTFileType fileType = [self fileTypeFromName:name];
	if (NXTFileUserProgram == fileType || NXTFileSampleProgram == fileType) {
		MRNXTStartProgramCommand *comm = [[MRNXTStartProgramCommand alloc] init];
		comm.filename = name;
		
		[_device enqueueCommand:comm responseBlock:NULL];
	}
	else if (NXTFileSound == fileType) {
		MRNXTPlaySoundFileCommand *comm = [[MRNXTPlaySoundFileCommand alloc] init];
		comm.loop = NO;
		comm.filename = name;
		
		[_device enqueueCommand:comm responseBlock:NULL];
	}
}

- (IBAction)downloadFile:(id)sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:NO];
	[panel setCanChooseDirectories:YES];
	
	[panel beginSheetModalForWindow:[self window]
				  completionHandler:^(NSInteger result) {
					  
					  if (result != NSFileHandlingPanelOKButton)
						  return;
					  
					  NSString *dp = [[[panel URLs] objectAtIndex:0] path];
					  
					  [self performSelector:@selector(selectedDestinationDirectory:)
								 withObject:dp afterDelay:0.0f];
					  
				  }];
}

- (IBAction)uploadFile:(id)sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:YES];
	[panel setCanChooseDirectories:NO];
	
	[panel beginSheetModalForWindow:[self window]
				  completionHandler:^(NSInteger result) {
					  
					  if (result != NSFileHandlingPanelOKButton)
						  return;
					  
					  NSString *dp = [[[panel URLs] objectAtIndex:0] path];
					  
					  [self performSelector:@selector(selectedFileToUpload:)
								 withObject:dp afterDelay:0.0f];
					  
				  }];
}

#pragma mark Downloading

- (void)displayDownloadControllerWithDestinationPath:(NSString *)dp filename:(NSString *)fn {
	_pwc = [[DownloadController alloc] init];
	
	[_pwc setClosedCallback:^{
		_pwc = nil;
	}];
	
	[_pwc setDevice:_device];
	[_pwc setFilename:fn];
	[_pwc setDestination:dp];
	
	[_pwc presentAsSheetInWindow:[self window]];
}

- (void)selectedDestinationDirectory:(NSString *)dp {
	[self displayDownloadControllerWithDestinationPath:dp
											  filename:[self selectedFileName]];
}

#pragma mark Uploading

- (void)selectedFileToUpload:(NSString *)dp {
	_pwc = [[UploadController alloc] initWithSourcePath:dp];
	
	[_pwc setClosedCallback:^{
		_pwc = nil;
	}];
	
	[_pwc setDevice:_device];
	[_pwc setUploadedFileBlock:^(NSString *filename, uint16_t size) {
		
		[_files insertObject:[self fileWithName:filename size:size] atArrangedObjectIndex:0];
		
	}];
	
	[_pwc presentAsSheetInWindow:[self window]];
}

@end
