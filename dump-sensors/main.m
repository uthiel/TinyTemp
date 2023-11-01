//
//  main.m
//  dump-sensors
//
//  Created by Udo Thiel on 31.10.23.
//

#import <Foundation/Foundation.h>
#import "../TinyTemp/IOHID/IOHID.h"

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		dup2(fileno(stdout), fileno(stderr));// redirect stderr (NSLog) to stdout
		IOHID *iohid	= IOHID.shared;
		puts(iohid.description.UTF8String);
	}
	return 0;
}
