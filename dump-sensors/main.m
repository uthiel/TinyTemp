//
//  main.m
//  dump-sensors
//
//  Created by Udo Thiel on 31.10.23.
//

#import <Foundation/Foundation.h>
#import "../TinyTemp/IOHID/IOHID.h"

static void timerCallback(CFRunLoopTimerRef timer, void *info) {
	IOHID *iohid = (__bridge IOHID *) info;
	puts([NSDate.date descriptionWithLocale:NSLocale.currentLocale].UTF8String);
	puts(iohid.description.UTF8String);
}


int main(int argc, const char * argv[]) {
	@autoreleasepool {
		dup2(fileno(stdout), fileno(stderr));// redirect stderr (NSLog) to stdout
		IOHID *iohid		= IOHID.shared;
		BOOL repeat			= NO;
		NSUInteger interval	= 0;
		CFRunLoopTimerRef timer;
		
		if (argc > 1) {
			NSUInteger argv1	= strtol(argv[1], NULL, 0);

			if (argv1 > 0) {
				repeat		= YES;
				interval	= argv1;
			}
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
	}

	return 0;
}
