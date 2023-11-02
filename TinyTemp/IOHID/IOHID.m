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
		if ([self matchesPrefix:pre_batt]) {
			_prettyName	= @"Battery";
		} else if ([self matchesPrefix:pre_ssd]) {
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
	NSString *name	= (self.prettyName) ? self.prettyName : self.name;
	return [NSString stringWithFormat:@"%-12s %.1fºC", name.UTF8String, self.temperature];
}

- (BOOL)matchesRegex:(NSRegularExpression *)regex {
	return ([regex numberOfMatchesInString:self.name options:0 range:NSMakeRange(0, self.name.length)] > 0);
}
- (BOOL)matchesPrefix:(NSString *)prefix {
	return [self.name hasPrefix:prefix];
}
@end


//MARK: - IOHID
@interface IOHID()
@property( nonatomic, readwrite, assign, nullable ) IOHIDEventSystemClientRef client;
@property NSArray *sensors_all, *sensors_cpu_die, *sensors_SSD, *sensors_Battery;
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
		NSMutableArray *_s_all		= NSMutableArray.array;
		NSMutableArray *_s_cpu_die	= NSMutableArray.array;
		NSMutableArray *_s_SSD		= NSMutableArray.array;
		NSMutableArray *_s_Battery	= NSMutableArray.array;
		
		// get services
		self.client			= IOHIDEventSystemClientCreate(kCFAllocatorDefault);
		NSArray *services	= CFBridgingRelease(IOHIDEventSystemClientCopyServices(self.client));
		
		// find temperature sensors
		NSRegularExpression *regex_cpu_die	= [NSRegularExpression regularExpressionWithPattern:@"^PMU.* tdie" options:0 error:nil];
		
		for (id o in services) {
			IOHIDServiceClientRef service	= (__bridge IOHIDServiceClientRef)o;
			TinySensor *sensor				= [TinySensor.alloc initWithService:service];
			
			// add sensor to all
			if (sensor) {
				[_s_all addObject:sensor];
			}

			// categorize sensor
			if ([sensor matchesRegex:regex_cpu_die]) {
				[_s_cpu_die addObject:sensor];
				
			} else if ([sensor matchesPrefix:pre_batt]) {
				[_s_Battery addObject:sensor];
				
			} else if ([sensor matchesPrefix:pre_ssd]) {
				[_s_SSD addObject:sensor];
			}
		}
		// sort arrays
		NSSortDescriptor *d = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
		for (NSMutableArray *a in @[_s_all,_s_SSD, _s_cpu_die, _s_Battery]) {
			[a sortUsingDescriptors:@[d]];
		}
		// make arrays immutable
		_sensors_all		= [NSArray arrayWithArray:_s_all];
		_sensors_cpu_die	= [NSArray arrayWithArray:_s_cpu_die];
		_sensors_SSD		= [NSArray arrayWithArray:_s_SSD];
		_sensors_Battery	= [NSArray arrayWithArray:_s_Battery];
    }
    return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"CPU=%@ SSD=%@ Batt=%@ All=%@", _sensors_cpu_die, _sensors_SSD, _sensors_Battery, _sensors_all];
}

- (double)avgForArray:(NSArray *)array {
	if (array.count == 0) {
		return -1.0;
	}
	double avg = 0.0;
	for (TinySensor *sensor in array) {
		double temp	= sensor.temperature;
		if (temp > 0) {
			avg += temp;
		}
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

- (NSArray<TinySensor *> *)allSensors {
	return _sensors_all;
}
@end
