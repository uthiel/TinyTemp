//
//  UTStatusItemViewController.h
//  TinyBatt
//
//  Created by Udo Thiel on 07.11.23.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const kStatusItemViewControllerDefaultsKey;

@interface UTStatusItemViewController : NSViewController

/// Creates a Popover below the status item containing a OK button.
/// - Parameters:
///   - item: The `NSStatusItem` to connect to.
///   - message: The message shown inside the Popover. If `nil`, a standard message will be used.
///   - block: An optional block to execute after the Popover was dismissed.
- (instancetype)initWithStatusItem:(NSStatusItem*)item
						   message:( NSString * _Nullable )message
				   popoverDidCLose:(void (^_Nullable)(void))block;

/// Creates a Popover below the status item containing a OK button and a default message.
/// - Parameters:
///   - item: The `NSStatusItem` to connect to.
- (instancetype)initWithStatusItem:(NSStatusItem*)item;

/// Shows the Popover once to the user.
- (void)showPopover;
@end

NS_ASSUME_NONNULL_END
