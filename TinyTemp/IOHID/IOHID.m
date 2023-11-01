//
//  IOHID.m
//  TinyTemp
//
//  Created by Udo Thiel on 28.10.23.
//

#import "IOHID.h"
#import <IOKit/hidsystem/IOHIDEventSystemClient.h>
#import <IOKit/hidsystem/IOHIDServiceClient.h>

#define IOHIDEventFieldBase( _type_ ) ( _type_ << 16 )
#define IOHIDEventTypeTemperature			0x0FLL

extern IOHIDEventSystemClientRef 	IOHIDEventSystemClientCreate(CFAllocatorRef);
extern CFTypeRef                 	IOHIDServiceClientCopyEvent(IOHIDServiceClientRef, int64_t, int64_t, int64_t);
extern double                    	IOHIDEventGetFloatValue(CFTypeRef, int64_t);



//MARK: - TinySensor
@interface TinySensor : NSObject
@property (copy) NSString *name;

- (instancetype)initWithService:(IOHIDServiceClientRef)service;
- (double)temperature;
@end


@implementation TinySensor {
	IOHIDServiceClientRef _service;
}

- (instancetype)initWithService:(IOHIDServiceClientRef)service {
	CFTypeRef event		= IOHIDServiceClientCopyEvent(service, IOHIDEventTypeTemperature, 0, 0);
	NSString *sensor	= CFBridgingRelease(IOHIDServiceClientCopyProperty(service, CFSTR(kIOHIDProductKey)));
	
	if (sensor != nil && event != nil) {
		self = [super init];
		_service	= service;
		_name		= sensor;
		if (event) CFRelease(event);
		return self;
	} else {
		if (event) CFRelease(event);
		return nil;
	}
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ : %f C", self.name, self.temperature];
}

- (double)temperature {
	static int64_t IOHIDEventFieldTemperatureLevel = IOHIDEventFieldBase(IOHIDEventTypeTemperature);
	
	CFTypeRef event	= IOHIDServiceClientCopyEvent(_service, IOHIDEventTypeTemperature, 0, 0);
	double value	= IOHIDEventGetFloatValue(event, IOHIDEventFieldTemperatureLevel);

	if (event) CFRelease(event);

	return value;;
}

- (BOOL)matchesRegex:(NSRegularExpression *)regex {
	return ([regex numberOfMatchesInString:self.name options:0 range:NSMakeRange(0, self.name.length)] > 0);
}


@end


//MARK: - IOHID
@interface IOHID()
@property( nonatomic, readwrite, assign, nullable ) IOHIDEventSystemClientRef client;
@property NSMutableArray *sensors_cpu_die, *sensors_SSD, *sensors_Battery;
@end


@implementation IOHID

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
		_sensors_cpu_die	= NSMutableArray.array;
//		_sensors_cpu_dev	= NSMutableArray.array;
		_sensors_SSD		= NSMutableArray.array;
		_sensors_Battery	= NSMutableArray.array;
		
		// get services
		self.client			= IOHIDEventSystemClientCreate(kCFAllocatorDefault);
		NSArray *services	= CFBridgingRelease(IOHIDEventSystemClientCopyServices(self.client));
		
		// find temperature sensors
		NSRegularExpression *regex_cpu_die	= [NSRegularExpression regularExpressionWithPattern:@"^PMU.* tdie" options:0 error:nil];
//		NSRegularExpression *regex_cpu_dev	= [NSRegularExpression regularExpressionWithPattern:@"^PMU.* tdev" options:0 error:nil];
		NSRegularExpression *regex_batt		= [NSRegularExpression regularExpressionWithPattern:@"^gas gauge battery" options:0 error:nil];
		NSRegularExpression *regex_ssd		= [NSRegularExpression regularExpressionWithPattern:@"^NAND CH" options:0 error:nil];
		
		for (id o in services) {
			IOHIDServiceClientRef service	= (__bridge IOHIDServiceClientRef)o;
			TinySensor *sensor				= [TinySensor.alloc initWithService:service];

			if ([sensor matchesRegex:regex_cpu_die]) {
				[_sensors_cpu_die addObject:sensor];
				
//			} else if ([sensor matchesRegex:regex_cpu_dev]) {
//				[_sensors_cpu_dev addObject:sensor];
				
			} else if ([sensor matchesRegex:regex_batt]) {
				[_sensors_Battery addObject:sensor];
				
			} else if ([sensor matchesRegex:regex_ssd]) {
				[_sensors_SSD addObject:sensor];
				
			} else if (sensor) {
				NSLog(@"Unknown Temperature Sensor: '%@'", sensor);
			}
		}
		// sort arrays
		NSSortDescriptor *d = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
		for (NSMutableArray *a in @[_sensors_SSD, _sensors_cpu_die, _sensors_Battery]) {
			[a sortUsingDescriptors:@[d]];
		}
    }
    return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"CPU=%@ SSD=%@ Batt=%@", _sensors_cpu_die, _sensors_SSD, _sensors_Battery];
}

- (double)avgForArray:(NSArray *)array {
	double avg = 0.0;
	for (TinySensor *sensor in array) {
		avg += sensor.temperature;
	}
	avg = avg / array.count;
	
	return avg;
}

- (float)readCPUTemperature {
	return [self avgForArray:_sensors_cpu_die];
}
- (float)readSSDTemperature {
	return [self avgForArray:_sensors_SSD];
}
- (float)readBatteryTemperature {
	return [self avgForArray:_sensors_Battery];
}

@end
