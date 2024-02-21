//
//  main.m
//  TinyTemp
//
//  Created by Udo Thiel on 28.10.23.
//

#import <Cocoa/Cocoa.h>
#import "../TinyTemp/IOHID/IOHID.h"

static void timerCallback(CFRunLoopTimerRef timer, void *info) {
	IOHID *iohid = (__bridge IOHID *) info;
	puts([NSDate.date descriptionWithLocale:NSLocale.currentLocale].UTF8String);
	puts(iohid.description.UTF8String);
}



int main(int argc, const char * argv[]) {

	NSArray* arguments = NSProcessInfo.processInfo.arguments;

	if ([arguments containsObject:@"-dump"]) {
		// enter CLI mode and handle arg(s)
		
		dup2(fileno(stdout), fileno(stderr));// redirect stderr (NSLog) to stdout
		
		IOHID *iohid		= IOHID.shared;
		BOOL repeat			= NO;
		NSInteger interval	= 0;
		CFRunLoopTimerRef timer;
		
		if (arguments.count > 2) {
			repeat		= YES;
			interval	= [arguments[2] integerValue];
		}
		
		if (repeat) {
			CFRunLoopTimerContext timerContext;
			timerContext.version = 0;
			timerContext.info = (__bridge void *)(iohid);
			timerContext.retain = NULL;
			timerContext.release = NULL;
			timerContext.copyDescription = NULL;
			
			timer	= CFRunLoopTimerCreate(kCFAllocatorDefault,
										   CFAbsoluteTimeGetCurrent(),
										   interval, 0, 0, timerCallback, &timerContext);
			
			CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, kCFRunLoopDefaultMode);
			CFRunLoopRun();
		} else {
			puts(iohid.description.UTF8String);
		}
		return 0;
	} else {
		// switch to UI mode
		ProcessSerialNumber psn = { 0, kCurrentProcess };
		TransformProcessType(&psn, kProcessTransformToForegroundApplication);
		return NSApplicationMain(argc, argv);
	}
}
