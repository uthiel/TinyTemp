//
//  IOHID.m
//  TinyTemp
//
//  Created by Udo Thiel on 28.10.23.
//

#import "IOHID.h"
#import "../TinySensor.h"

extern IOHIDEventSystemClientRef 	IOHIDEventSystemClientCreate(CFAllocatorRef);



@implementation IOHID {
	IOHIDEventSystemClientRef client;
	NSArray *sensors_other, *sensors_cpu, *sensors_SSD, *sensors_Battery, *sensors_all;
}

+ (IOHID *)shared {
    static dispatch_once_t once;
    static IOHID         * instance;

    dispatch_once(&once, ^(void) {
            instance = [[IOHID alloc] init];
        });
    return instance;
}

- (instancetype)init {
    if ((self = [super init])) {
		NSMutableArray *s_cpu		= NSMutableArray.array;
		NSMutableArray *s_SSD		= NSMutableArray.array;
		NSMutableArray *s_Battery	= NSMutableArray.array;
		NSMutableArray *s_all		= NSMutableArray.array;
		NSMutableArray *s_other		= NSMutableArray.array;
		
		// get services
		client				= IOHIDEventSystemClientCreate(kCFAllocatorDefault);
		NSArray *services	= CFBridgingRelease(IOHIDEventSystemClientCopyServices(client));
		
		// enumerate and classify sensors
		for (id o in services) {
			IOHIDServiceClientRef service	= (__bridge IOHIDServiceClientRef)o;
			TinySensor *sensor				= [TinySensor.alloc initWithService:service];
			
			if (sensor) {
				[s_all addObject:sensor];
				
				if ([sensor isCPU]) {
					[s_cpu addObject:sensor];
					
				} else if ([sensor isBattery]) {
					[s_Battery addObject:sensor];
					
				} else if ([sensor isSSD]) {
					[s_SSD addObject:sensor];

				} else {
					[s_other addObject:sensor];
				}
			}
		}
		// sort arrays
		NSSortDescriptor *d1 = [NSSortDescriptor sortDescriptorWithKey:@"name"			ascending:YES];
		NSSortDescriptor *d2 = [NSSortDescriptor sortDescriptorWithKey:@"locationID"	ascending:YES];
		
		for (NSMutableArray *a in @[s_other, s_SSD, s_cpu, s_Battery, s_all]) {
			[a sortUsingDescriptors:@[d1, d2]];
		}
		// make arrays immutable
		sensors_other	= [NSArray arrayWithArray:s_other];
		sensors_cpu		= [NSArray arrayWithArray:s_cpu];
		sensors_SSD		= [NSArray arrayWithArray:s_SSD];
		sensors_Battery	= [NSArray arrayWithArray:s_Battery];
		sensors_all		= [NSArray arrayWithArray:s_all];
    }
    return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"PMU=%@ SSD=%@ Batt=%@ Other=%@", sensors_cpu, sensors_SSD, sensors_Battery, sensors_other];
}

- (double)avgForArray:(NSArray *)array {
	
	if (array.count == 0) {
//		NSLog(@"Array count is zero");
		return -1.0;
	}
	
	double sum			= 0.0;
	NSUInteger count	= 0;
	
	for (TinySensor *sensor in array) {
		if (sensor.selected) {
			double temp	= sensor.temperature;
			sum += temp;
			count++;
		}
	}
	
	if (count) {
		return sum / count;
	}
//	NSLog(@"No object selected");
	return -1.0;
}

- (float)readPMUTemperature 	{ return [self avgForArray:sensors_cpu];}
- (float)readSSDTemperature 	{ return [self avgForArray:sensors_SSD];}
- (float)readBatteryTemperature	{ return [self avgForArray:sensors_Battery];}

- (NSArray<TinySensor *> *)allSensors	{ return sensors_all;}
- (NSArray<TinySensor *> *)cpuSensors	{ return sensors_cpu;}
- (NSArray<TinySensor *> *)ssdSensors	{ return sensors_SSD;}
- (NSArray<TinySensor *> *)battSensors	{ return sensors_Battery;}
@end
