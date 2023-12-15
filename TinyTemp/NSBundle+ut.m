//
//  NSBundle+ut.m
//
//  Created by Udo Thiel on 07.11.23.
//

#import "NSBundle+ut.h"

@implementation NSBundle (ut)
+ (NSString *)ut_bundleName {
	NSBundle 	*mb	= NSBundle.mainBundle;
	NSString	*n	= [mb objectForInfoDictionaryKey:@"CFBundleName"];
	return n;
}
+ (NSString *)ut_bundleStats {
	NSBundle 	*mb	= NSBundle.mainBundle;
	NSString	*n	= [mb objectForInfoDictionaryKey:@"CFBundleName"];
	NSString	*v	= [mb objectForInfoDictionaryKey:@"CFBundleVersion"];
	NSString	*sv	= [mb objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	return [NSString stringWithFormat:@"%@ (%@) %@ (%@)",n, mb.bundleIdentifier,sv,v];
}
@end
