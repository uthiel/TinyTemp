//
//  TinySensor.h
//  TinyTemp
//
//  Created by Udo Thiel on 17.11.23.
//

#import <Foundation/Foundation.h>
#import <IOKit/hidsystem/IOHIDEventSystemClient.h>
#import <IOKit/hidsystem/IOHIDServiceClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface TinySensor : NSObject

@property (copy, readonly) NSString *name, *prettyName, *locationID;
@property BOOL selected;


- (instancetype)initWithService:(IOHIDServiceClientRef)service;
- (double)temperature;
- (NSString *)nameAndTemperature;

- (BOOL)isCPU;
- (BOOL)isSSD;
- (BOOL)isBattery;
@end

extern NSInteger DegreeUnit;

NS_ASSUME_NONNULL_END
