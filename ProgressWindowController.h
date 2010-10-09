//
//  ProgressWindowController.h
//  NXT Browser
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

typedef void (^WindowClosedCallback) (void);

@interface ProgressWindowController : NSWindowController {
  @private
	IBOutlet NSTextField *_label;
	IBOutlet NSProgressIndicator *_indicator;
	WindowClosedCallback _callback;
}

@property (nonatomic, copy) WindowClosedCallback closedCallback;

@property (nonatomic, copy) NSString *prompt;
@property (nonatomic, assign) double progress;

- (void)presentAsSheetInWindow:(NSWindow *)parentWindow;
- (void)dismissSheet;

@end
