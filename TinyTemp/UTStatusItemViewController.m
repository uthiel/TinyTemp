//
//  UTStatusItemViewController.m
//  TinyBatt
//
//  Created by Udo Thiel on 07.11.23.
//

#import "UTStatusItemViewController.h"
#import "NSBundle+ut.h"

@interface UTStatusItemViewController ()
@property NSPopover *pop;
@property (weak) NSStatusItem *statusItem;
@property (copy) NSString *message;
@property (nonatomic, copy, nullable) void (^block)(void);
@end

@implementation UTStatusItemViewController
- (instancetype)initWithStatusItem:(NSStatusItem *)item message:(NSString *)message popoverDidCLose:(void (^)(void))block {
	self = [super init];
	if (self) {
		_statusItem	= item;
		_message	= (message) ? message : self.class.standardMessage;
		_block		= block;
	}
	return self;

}
- (instancetype)initWithStatusItem:(NSStatusItem *)item {
	return [self initWithStatusItem:item message:self.class.standardMessage popoverDidCLose:nil];
}

+ (NSString *)standardMessage {
	NSString *app = NSBundle.ut_bundleName;
	NSString *msg = [NSString stringWithFormat:@" %@ is ready, click here to access the menu. ", app];
	return msg;
}

- (void)viewDidLoad {
	[super viewDidLoad];
}

- (void)showPopover {
	
	NSString *defaultsKey= @"didViewStatusItemPopOver";
	
	if (![NSUserDefaults.standardUserDefaults boolForKey:defaultsKey]) {
		
		[NSUserDefaults.standardUserDefaults setBool:YES forKey:defaultsKey];
		
		NSTextField *tf	= [NSTextField labelWithString:self.message];
		tf.alignment	= NSTextAlignmentCenter;
		
		NSButton *butt	= [NSButton buttonWithTitle:@"OK" target:self action:@selector(closePopOver:)];
		
		NSStackView *sv	= [NSStackView stackViewWithViews:@[tf, butt]];
		sv.orientation	= NSUserInterfaceLayoutOrientationVertical;
		sv.spacing		= 15.0;
		sv.edgeInsets	= NSEdgeInsetsMake(15.0, 10.0, 15.0, 10.0);
		self.view		= sv;
		
		self.pop						= NSPopover.alloc.init;
		self.pop.contentViewController	= self;
		[self.pop showRelativeToRect:self.statusItem.button.bounds ofView:self.statusItem.button preferredEdge:NSMinYEdge];
	}
}

- (IBAction)closePopOver:(id)sender {
	[self.pop close];
	self.pop	= nil;
	if (self.block) {
		self.block();
	}
}
@end
