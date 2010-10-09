//
//  DeleteTableView.h
//  NXT Browser
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

typedef void (^DeleteCallback) (NSUInteger row);

@interface DeleteTableView : NSTableView {
  @private
	DeleteCallback _deleteCallback;
}

@property (nonatomic, copy) DeleteCallback deleteCallback;

- (IBAction)delete:(id)sender;

@end
