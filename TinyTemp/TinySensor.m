//
//  TinySensor.m
//  TinyTemp
//
//  Created by Udo Thiel on 17.11.23.
//

#import "TinySensor.h"
#import "AppDelegate.h"

extern CFTypeRef	IOHIDServiceClientCopyEvent(IOHIDServiceClientRef, int64_t, int64_t, int64_t);
extern double   	IOHIDEventGetFloatValue(CFTypeRef, int64_t);

static NSString *pre_batt	= @"gas gauge battery";
static NSString *pre_ssd	= @"NAND CH";
static NSString *pre_pmu_1	= @"PMU tdie";
static NSString *pre_pmu_2	= @"PMU2 tdie";
static NSString *pre_pmu_tp	= @"PMU TP";

#define IOHIDEventTypeTemperature			0x0FLL
#define IOHIDEventFieldBase( _type_ ) ( _type_ << 16 )

@implementation TinySensor {
	IOHIDServiceClientRef _service;
}

- (instancetype)initWithService:(IOHIDServiceClientRef)service {
	
	CFTypeRef event		= IOHIDServiceClientCopyEvent(service, IOHIDEventTypeTemperature, 0, 0);
	NSString *sensor	= CFBridgingRelease(IOHIDServiceClientCopyProperty(service, CFSTR(kIOHIDProductKey)));
	
	if (sensor != nil && event != nil) {
		self 		= [super init];
		_service	= service;
		_name		= sensor;
		_prettyName	= _name.copy;
		
		NSNumber *l	= CFBridgingRelease(IOHIDServiceClientCopyProperty(service, CFSTR(kIOHIDLocationIDKey)));
		_locationID	= [NSString stringWithFormat:@"%llX", l.unsignedLongLongValue];
		
		if ([self isBattery]) {
			_prettyName	= [@"Battery #" stringByAppendingString:_locationID];
			
		} else if ([self isSSD]) {
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

-(void)dealloc {
	//	NSLog(@"Dealloc: %@", self);
}

- (NSString *)description {
	return [NSString stringWithFormat:@"sel=%u locationID=%@ %@ : %f C", self.selected, self.locationID, self.name, self.temperature];
}

- (double)temperature {
	static int64_t IOHIDEventFieldTemperatureLevel = IOHIDEventFieldBase(IOHIDEventTypeTemperature);
	
	if (_service) {
		CFTypeRef event	= IOHIDServiceClientCopyEvent(_service, IOHIDEventTypeTemperature, 0, 0);
		double value	= IOHIDEventGetFloatValue(event, IOHIDEventFieldTemperatureLevel);
		
		if (event) CFRelease(event);
		
		return value;;
	} else {
		return -1.0;;
	}
}

- (NSString *)nameAndTemperature {
	NSString *temp	= [(AppDelegate *)NSApp.delegate localisedMenuTempForTemp:self.temperature];
	return [NSString stringWithFormat:@"%-12s %@", self.prettyName.UTF8String, temp];
}

- (BOOL)matchesPrefix:(NSString *)prefix {
	return [self.name hasPrefix:prefix];
}
- (BOOL)isCPU		{ return [self matchesPrefix:pre_pmu_1] ||[self matchesPrefix:pre_pmu_2] || [self matchesPrefix:pre_pmu_tp];}
- (BOOL)isSSD		{ return [self matchesPrefix:pre_ssd];}
- (BOOL)isBattery	{ return [self matchesPrefix:pre_batt];}
@end
