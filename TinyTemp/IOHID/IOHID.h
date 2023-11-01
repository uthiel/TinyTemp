//
//  IOHID.h
//  TinyTemp
//
//  Created by Udo Thiel on 28.10.23.
//

#import <Foundation/Foundation.h>
#import <IOKit/hidsystem/IOHIDEventSystemClient.h>
#import <IOKit/hidsystem/IOHIDServiceClient.h>

NS_ASSUME_NONNULL_BEGIN

//MARK: - TinySensor
@interface TinySensor : NSObject

@property (copy) NSString *name, *prettyName;

- (instancetype)initWithService:(IOHIDServiceClientRef)service;
- (double)temperature;
- (NSString *)nameAndTemperature;
@end


//MARK: - IOHID
@interface IOHID: NSObject

@property(class, nonatomic, readonly) IOHID *shared;

- (instancetype)init;

- (float)readBatteryTemperature;
- (float)readCPUTemperature;
- (float)readSSDTemperature;

- (NSArray <TinySensor*> *)allSensors;
@end

NS_ASSUME_NONNULL_END
