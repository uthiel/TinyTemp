//
//  AppDelegate.m
//  TinyTemp
//
//  Created by Udo Thiel on 28.10.23.
//

#import "AppDelegate.h"
#import "IOHID/IOHID.h"

@interface AppDelegate ()
@property IBOutlet NSMenu * _Nonnull statusItemMenu;
@property (readonly) NSStatusItem * _Nonnull statusItem;
@end

@implementation AppDelegate {
	IOHID *iohid;
	NSTimer *timer_cpu, *timer_ssd, *timer_batt;
	double temp_cpu, temp_ssd, temp_batt;
}

- (void)awakeFromNib {
	// NSStatusItem
	_statusItem							= [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
	_statusItem.behavior				= NSStatusItemBehaviorTerminationOnRemoval;
	_statusItem.menu					= self.statusItemMenu;
	_statusItem.button.title			= [NSBundle.mainBundle objectForInfoDictionaryKey:(__bridge NSString*)kCFBundleNameKey];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// start sensor singleton
	iohid = IOHID.shared;
	
	// update StatusItem immediately
	[self updateCPU:nil];
	[self updateSSD:nil];
	[self updateBatt:nil];
	
	// start cpu timer
	timer_cpu			= [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(updateCPU:) userInfo:nil repeats:YES];
	timer_cpu.tolerance	= 1.0;
	// start ssd timer
	timer_ssd			= [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(updateSSD:) userInfo:nil repeats:YES];
	timer_cpu.tolerance	= 1.0;
	// start batt timer
	timer_batt			= [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(updateSSD:) userInfo:nil repeats:YES];
	timer_batt.tolerance= 1.0;
}

//MARK: StatusItem Updates
- (void)updateStatusItemToolTip {
	NSString *cpu	= [self formattedTempForTemp:temp_cpu];
	NSString *ssd	= [self formattedTempForTemp:temp_ssd];
	NSString *batt	= [self formattedTempForTemp:temp_batt];
	self.statusItem.button.toolTip	= [NSString stringWithFormat:@"CPU:%@ SSD:%@ Batt:%@", cpu, ssd, batt];
}
- (void)updateCPU:(NSTimer *)timer {
	temp_cpu	= [iohid readCPUTemperature];
	self.statusItem.button.title	= [self formattedTempForTemp:temp_cpu];
	[self updateStatusItemToolTip];
}
- (void)updateSSD:(NSTimer *)timer {
	temp_ssd = [iohid readSSDTemperature];
	[self updateStatusItemToolTip];
}
- (void)updateBatt:(NSTimer *)timer {
	temp_batt = [iohid readBatteryTemperature];
	[self updateStatusItemToolTip];
}

- (NSString *)formattedTempForTemp:(double)temp {
	return [NSString stringWithFormat:@"%.0fºC", round(temp)];
}

//MARK: AppDelegate Stuff
- (void)applicationWillTerminate:(NSNotification *)aNotification {
}
- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
	return NO;
}
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return NO;
}
@end
