//
//  AppDelegate.m
//  TinyTemp
//
//  Created by Udo Thiel on 28.10.23.
//

#import "AppDelegate.h"
#import "IOHID/IOHID.h"
#import "TinySensor.h"
#import "UTStatusItemViewController.h"
#import <ServiceManagement/ServiceManagement.h>


// user defaults keys
static NSString *def_sensor_selection	= @"sensor_selection_2";


// MARK: - AppDeleghate
@interface AppDelegate () <NSMenuDelegate>
@property IBOutlet NSMenu *statusItemMenu;
@property IBOutlet NSMenu *cpuMenu, *ssdMenu, *battMenu;
@property IBOutlet NSMenuItem *lal;
@property (readonly) NSStatusItem * _Nonnull statusItem;
@end

@implementation AppDelegate {
	IOHID *iohid;
	NSTimer *timer_cpu, *timer_ssd, *timer_batt;
	double    temp_cpu,   temp_ssd,   temp_batt;
	BOOL    update_cpu, update_ssd, update_batt;
	NSMeasurementFormatter *t_formatter_0, *t_formatter_1;
}

- (void)awakeFromNib {
	// NSStatusItem
	_statusItem							= [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
	_statusItem.behavior				= NSStatusItemBehaviorTerminationOnRemoval;
	_statusItem.button.imagePosition	= NSImageLeft;
	_statusItem.menu					= self.statusItemMenu;
	_statusItem.button.font				= [NSFont monospacedSystemFontOfSize:-1.0 weight:NSFontWeightRegular];
	_statusItem.button.title			= @"-";
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	// configure temp formatter
	t_formatter_0										= NSMeasurementFormatter.alloc.init;
	t_formatter_0.locale								= NSLocale.autoupdatingCurrentLocale;
	t_formatter_0.unitStyle								= NSFormattingUnitStyleMedium;
	t_formatter_0.numberFormatter.maximumFractionDigits	= 0; // we like to keep it tiny in the status bar
	t_formatter_0.numberFormatter.minimumFractionDigits	= 0;

	t_formatter_1										= NSMeasurementFormatter.alloc.init;
	t_formatter_1.locale								= NSLocale.autoupdatingCurrentLocale;
	t_formatter_1.unitStyle								= NSFormattingUnitStyleMedium;
	t_formatter_1.numberFormatter.maximumFractionDigits	= 1; // increase precision for menu temps
	t_formatter_1.numberFormatter.minimumFractionDigits	= 1;

	// show initial popover
	UTStatusItemViewController *vc	= [UTStatusItemViewController.alloc initWithStatusItem:self.statusItem];
	[vc showPopover];
	
	// update lal
	[self updateLaunchAtLoginMenuItem];
	
	// start sensor singleton
	iohid = IOHID.shared;
	
	// populate sensor selection with reasonable defaults at first launch
	NSSet *selections	= [self userDefaultSensorSelections];
	if (!selections || !selections.count) {
		[(TinySensor *) iohid.cpuSensors.firstObject  setSelected:YES];
		[(TinySensor *) iohid.ssdSensors.firstObject  setSelected:YES];
		[(TinySensor *) iohid.battSensors.firstObject setSelected:YES];
		
		[self writeUserDefaultsSensorSelection];
	}
	
	// start cpu timer
	timer_cpu			= [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(updateCPU:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer_cpu forMode:NSRunLoopCommonModes];// required for menu items to update while a menu is open
	timer_cpu.tolerance	= 1.0;
	// start ssd timer
	timer_ssd			= [NSTimer timerWithTimeInterval:30.0 target:self selector:@selector(updateSSD:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer_ssd forMode:NSRunLoopCommonModes];// required for menu items to update while a menu is open
	timer_ssd.tolerance	= 1.0;
	// start batt timer
	timer_batt			= [NSTimer timerWithTimeInterval:30.0 target:self selector:@selector(updateBatt:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer_batt forMode:NSRunLoopCommonModes];// required for menu items to update while a menu is open
	timer_batt.tolerance= 1.0;
	
	// populate cpu/ssd/batt menus
	[self configureMenu:self.cpuMenu  withSensorArray:iohid.cpuSensors ];
	[self configureMenu:self.ssdMenu  withSensorArray:iohid.ssdSensors ];
	[self configureMenu:self.battMenu withSensorArray:iohid.battSensors];
	
	// update StatusItem after selections have been read from user defaults
	[self updateCPU:nil];
	[self updateSSD:nil];
	[self updateBatt:nil];
}

- (void)configureMenu:(NSMenu *)menu withSensorArray:(NSArray *)array {
	menu.font		= [NSFont monospacedSystemFontOfSize:-1.0 weight:NSFontWeightRegular];
	menu.delegate	= self;
	
	NSSet *selections	= [self userDefaultSensorSelections];
	
	for (TinySensor *sensor in array) {
		for (NSString *locationID in selections) {
			if ([sensor.locationID isEqualToString:locationID]) {
				sensor.selected	= YES;
			}
		}
		NSString *title			= [self titleForSensor:sensor];
		NSMenuItem *item 		= [menu addItemWithTitle:title action:@selector(toggleSensor:) keyEquivalent:@""];
		item.representedObject	= sensor;
		[item bind:NSValueBinding toObject:sensor withKeyPath:@"selected" options:nil];
	}
}

//MARK: formatting
- (NSString *)localisedTempForTemp:(double)temp withFormatter:(NSMeasurementFormatter *)formatter {
	if (temp < 0.0) {// will be negative if sensor count is 0
		return @"-";
	} else {
		NSMeasurement *m	= [NSMeasurement.alloc initWithDoubleValue:temp unit:NSUnitTemperature.celsius];
		return [formatter stringFromMeasurement:m];
	}
}
- (NSString *)localisedTempForTemp:(double)temp {
	return [self localisedTempForTemp:temp withFormatter:t_formatter_0];
}
- (NSString *)localisedMenuTempForTemp:(double)temp {
	return [self localisedTempForTemp:temp withFormatter:t_formatter_1];
}

//MARK: Sensor Selection User Defaults
- (NSSet <NSString *>*)userDefaultSensorSelections {
	NSArray *selections	= [NSUserDefaults.standardUserDefaults objectForKey:def_sensor_selection];
	return [NSSet setWithArray:selections];
}
- (void)writeUserDefaultsSensorSelection {
	NSMutableSet *selections = NSMutableSet.set;
	for (TinySensor *sensor in iohid.allSensors) {
		if (sensor.selected) {
			[selections addObject:sensor.locationID];
		}
	}
	NSArray *array	= [selections sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:nil ascending:YES]]];
	[NSUserDefaults.standardUserDefaults setObject:array forKey:def_sensor_selection];
}

//MARK: StatusItem Updates
- (void)updateStatusItemToolTip {
	NSString *cpu	= self.statusItem.button.title;
	NSString *ssd	= [self localisedTempForTemp:temp_ssd];
	NSString *batt	= [self localisedTempForTemp:temp_batt];
	
	self.statusItem.button.toolTip	= [NSString stringWithFormat:@"CPU:%@ SSD:%@ Batt:%@", cpu, ssd, batt];
}
- (void)updateCPU:(NSTimer *)timer {
	temp_cpu						= [iohid readPMUTemperature];
	self.statusItem.button.title	= [self localisedTempForTemp:temp_cpu];
	[self updateStatusItemToolTip];
	
	if (update_cpu) {
		[self updateSensorMenu:self.cpuMenu];
	}
}
- (void)updateSSD:(NSTimer *)timer {
	temp_ssd = [iohid readSSDTemperature];
	[self updateStatusItemToolTip];
	
	if (update_ssd) {
		[self updateSensorMenu:self.ssdMenu];
	}
}
- (void)updateBatt:(NSTimer *)timer {
	temp_batt = [iohid readBatteryTemperature];
	[self updateStatusItemToolTip];
	
	if (update_batt) {
		[self updateSensorMenu:self.battMenu];
	}
}

//MARK: all cpu/ssd/batt menus
- (void)menuWillOpen:(NSMenu *)menu {
	// for performance reasons, we only update the temperature menus if they are actually open
	// we need to update the menu immediately, otherwise it will show outdated values
	if (menu == self.cpuMenu ) { update_cpu		= YES; [self updateSensorMenu:menu];}
	if (menu == self.ssdMenu ) { update_ssd		= YES; [self updateSensorMenu:menu];}
	if (menu == self.battMenu) { update_batt	= YES; [self updateSensorMenu:menu];}
}
- (void)menuDidClose:(NSMenu *)menu {
	if (menu == self.cpuMenu ) { update_cpu		= NO;}
	if (menu == self.ssdMenu ) { update_ssd		= NO;}
	if (menu == self.battMenu) { update_batt	= NO;}
}
- (void)updateSensorMenu:(NSMenu *)menu {
	for (NSMenuItem *item in menu.itemArray) {
		if ([item.representedObject isKindOfClass:TinySensor.class]) {
			TinySensor *sensor	= (TinySensor *)item.representedObject;
			item.title			= [self titleForSensor:sensor];
		}
	}
}
- (NSString *)titleForSensor:(TinySensor *)sensor {
	return [sensor nameAndTemperature];
}
- (void)toggleSensor:(NSMenuItem *)item {
	// at this point, item.state isn't toggled yet, therefore we need to wait for the next run loop
	[NSOperationQueue.mainQueue addOperationWithBlock:^{
		// this block will be executed after item.state has been toggled
		[self updateCPU:nil];
		[self updateStatusItemToolTip];
		// write clientIDs of selected sensors to user defaults
		[self writeUserDefaultsSensorSelection];
	}];
}

//MARK: Launch at Login
- (void)updateLaunchAtLoginMenuItem {
	if (@available(macOS 13.0, *)) {
		SMAppServiceStatus status	= SMAppService.mainAppService.status;
		self.lal.state				=  (status == SMAppServiceStatusEnabled);
		self.lal.enabled			= YES;
	}
}
- (IBAction)toggleLaunchAtLogin:(NSMenuItem *)sender {
	if (@available(macOS 13.0, *)) {
		SMAppService *as	= SMAppService.mainAppService;
		NSError *error;
		if (as.status == SMAppServiceStatusEnabled) {
			[as unregisterAndReturnError:&error];
			if (error) {
				NSLog(@"Unregistered with error: %@",error);
			}
		} else {
			[as registerAndReturnError:&error];
			if (error) {
				NSLog(@"Registered with error: %@",error);
			}
		}
		sender.state	= !sender.state;
	}
}


//MARK: AppDelegate
- (void)applicationWillTerminate:(NSNotification *)aNotification {
}
- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
	return NO;
}
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return NO;
}
@end
