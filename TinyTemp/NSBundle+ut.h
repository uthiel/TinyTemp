//
//  NSBundle+ut.h
//
//  Created by Udo Thiel on 07.11.23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (ut)
+ (NSString *)ut_bundleStats;
+ (NSString *)ut_bundleName;
@end

NS_ASSUME_NONNULL_END
