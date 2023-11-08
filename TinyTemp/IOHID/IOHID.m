//
//  IOHID.m
//  TinyTemp
//
//  Created by Udo Thiel on 28.10.23.
//

#import "IOHID.h"

#define IOHIDEventFieldBase( _type_ ) ( _type_ << 16 )
#define IOHIDEventTypeTemperature			0x0FLL

extern IOHIDEventSystemClientRef 	IOHIDEventSystemClientCreate(CFAllocatorRef);
extern CFTypeRef                 	IOHIDServiceClientCopyEvent(IOHIDServiceClientRef, int64_t, int64_t, int64_t);
extern double                    	IOHIDEventGetFloatValue(CFTypeRef, int64_t);

static NSString *pre_batt	= @"gas gauge battery";
static NSString *pre_ssd	= @"NAND CH";
static NSString *pre_pmu1	= @"PMU tdie";


//MARK: - TinySensor
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
		_prettyName	= _name.copy;
		if ([self matchesPrefix:pre_batt]) {
			_prettyName	= @"Battery";
		} else if ([self matchesPrefix:pre_ssd]) {
			// convert "NAND CH0 temp" to "SSD %0"
			NSString *pattern			= [NSString stringWithFormat:@"^%@(\\d) .*", pre_ssd];
			NSRegularExpression *reg	= [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
			NSTextCheckingResult *res	= [reg firstMatchInString:_name options:0 range:NSMakeRange(0, _name.length)];
			if (res && res.numberOfRanges > 1) {
				NSRange range	= [res rangeAtIndex:1];
				NSString *num	= [_name substringWithRange:range];
				_prettyName		= [@"SSD #" stringByAppendingString:num];
			}
		}
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

- (NSString *)nameAndTemperature {
	return [NSString stringWithFormat:@"%-12s %.1fºC", self.prettyName.UTF8String, self.temperature];
}

- (BOOL)matchesPrefix:(NSString *)prefix {
	return [self.name hasPrefix:prefix];
}
@end


//MARK: - IOHID
@implementation IOHID {
	IOHIDEventSystemClientRef client;
	NSArray *sensors_other, *sensors_pmu_die, *sensors_SSD, *sensors_Battery, *sensors_all;
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
		NSMutableArray *s_other		= NSMutableArray.array;
		NSMutableArray *s_cpu_die	= NSMutableArray.array;
		NSMutableArray *s_SSD		= NSMutableArray.array;
		NSMutableArray *s_Battery	= NSMutableArray.array;
		NSMutableArray *s_all		= NSMutableArray.array;
		
		// get services
		client				= IOHIDEventSystemClientCreate(kCFAllocatorDefault);
		NSArray *services	= CFBridgingRelease(IOHIDEventSystemClientCopyServices(client));
		
		// enumerate and classify sensors
		for (id o in services) {
			IOHIDServiceClientRef service	= (__bridge IOHIDServiceClientRef)o;
			TinySensor *sensor				= [TinySensor.alloc initWithService:service];
			
			if (sensor) {
				[s_all addObject:sensor];
				
				if ([sensor matchesPrefix:pre_pmu1]) {
					[s_cpu_die addObject:sensor];
					
				} else if ([sensor matchesPrefix:pre_batt]) {
					[s_Battery addObject:sensor];
					
				} else if ([sensor matchesPrefix:pre_ssd]) {
					[s_SSD addObject:sensor];

				} else {
					[s_other addObject:sensor];
				}
			}
		}
		// sort arrays
		NSSortDescriptor *d = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
		for (NSMutableArray *a in @[s_other, s_SSD, s_cpu_die, s_Battery, s_all]) {
			[a sortUsingDescriptors:@[d]];
		}
		// make arrays immutable
		sensors_other	= [NSArray arrayWithArray:s_other];
		sensors_pmu_die	= [NSArray arrayWithArray:s_cpu_die];
		sensors_SSD		= [NSArray arrayWithArray:s_SSD];
		sensors_Battery	= [NSArray arrayWithArray:s_Battery];
		sensors_all		= [NSArray arrayWithArray:s_all];
    }
    return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"PMU=%@ SSD=%@ Batt=%@ Other=%@", sensors_pmu_die, sensors_SSD, sensors_Battery, sensors_other];
}

- (double)avgForArray:(NSArray *)array {
	if (array.count == 0) {
		return -1.0;
	}
	double avg = 0.0;
	for (TinySensor *sensor in array) {
		double temp	= sensor.temperature;
		if (temp > 0) {// ignore negative temps
			avg += temp;
		}
	}
	avg = avg / array.count;
	
	return avg;
}

- (float)readPMUTemperature {
	return [self avgForArray:sensors_pmu_die];
}
- (float)readSSDTemperature {
	return [self avgForArray:sensors_SSD];
}
- (float)readBatteryTemperature {
	return [self avgForArray:sensors_Battery];
}

- (NSArray<TinySensor *> *)allSensors {
	return sensors_all;
}
@end
