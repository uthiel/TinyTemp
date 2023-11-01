//
//  IOHID.h
//  TinyTemp
//
//  Created by Udo Thiel on 28.10.23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IOHID: NSObject

@property(class, nonatomic, readonly) IOHID *shared;

- (instancetype)init;

- (float)readBatteryTemperature;
- (float)readCPUTemperature;
- (float)readSSDTemperature;

@end

NS_ASSUME_NONNULL_END
