//
//  IOHID.h
//  TinyTemp
//
//  Created by Udo Thiel on 28.10.23.
//

#import <Foundation/Foundation.h>
#import <IOKit/hidsystem/IOHIDEventSystemClient.h>
#import <IOKit/hidsystem/IOHIDServiceClient.h>
@class TinySensor;


NS_ASSUME_NONNULL_BEGIN

//MARK: - IOHID
@interface IOHID: NSObject

@property(class, nonatomic, readonly) IOHID *shared;

- (instancetype)init;

- (float)readBatteryTemperature;
- (float)readPMUTemperature;
- (float)readSSDTemperature;

- (NSArray <TinySensor*> *)allSensors;
- (NSArray <TinySensor*> *)cpuSensors;
- (NSArray <TinySensor*> *)ssdSensors;
- (NSArray <TinySensor*> *)battSensors;
@end

NS_ASSUME_NONNULL_END
