/*! ********************************************************************
 *
 * Copyright (c) 2018-2023, Fisherlea Systems
 *
 * Licensed under the MIT license. See the LICENSE file in the root
 * directory for more details.
 *
 ***********************************************************************/

#import "HeadsetControl.h"

#if 0
#define DBG(a)          NSLog(a)
#define DBG1(a, b)      NSLog(a, b)
#define DBG2(a, b, c)   NSLog(a, b, c)
#else
#define DBG(a)
#define DBG1(a, b)
#define DBG2(a, b, c)
#endif

@implementation HeadsetControl

- (void) pluginInitialize {
    NSError *error;
    AVAudioSessionRouteDescription *route;

    self.currentDevice = nil;
    self.a2dpConnected = NO;
    self.scoConnected = NO;
    self.isConnected = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChanged:) name:AVAudioSessionRouteChangeNotification object:nil];

    self.audioSession = [AVAudioSession sharedInstance];

    NSLog(@"[hc] AVAudioSession category: %@, categoryOptions = %d",
          [self.audioSession category], (int) self.audioSession.categoryOptions);
    NSLog(@"[hc] setCategory to PlayAndRecord and enable Bluetooth.");
    // Play and record is needed for access to bluetooth headsets.
    // See https://developer.apple.com/documentation/avfoundation/avaudiosessioncategoryoptions/avaudiosessioncategoryoptionallowbluetooth
    if(![self.audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                           withOptions:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionAllowBluetoothA2DP
                                 error:&error]) {
        NSLog(@"[hc] Unable to setCategory: %@", error);
    }

    route = self.audioSession.currentRoute;
    @try {
        if([route.inputs count] > 0) {
            self.currentDevice = route.inputs[0];

            if(self.currentDevice) {
                if([self.currentDevice.portType isEqualToString:AVAudioSessionPortHeadphones] ||
                [self.currentDevice.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
                    self.isConnected = YES;
                }
            }
        }
    }
    @catch(NSException *exception) {
        // This only seems to fail during Apple's review testing.
        // Likely something related to their test harness.
        // The issue is that an exception occurs dereferencing route.inputs.
        // We don't need that info yet, so can wait to get it later.
        // Feb 3, 2023 added check on count of route.inputs entries above so this is unlikely to happen any more.
        self.currentDevice = nil;
        NSLog(@"[hc] Unable to determine the current device.");
    }
}

- (void)routeChanged:(NSNotification *)notification {
    NSNumber *reason = [notification.userInfo objectForKey:AVAudioSessionRouteChangeReasonKey];
    NSArray<AVAudioSessionPortDescription *> *inputs;
    AVAudioSessionPortDescription *port;

    DBG(@"[hc] routeChanged");

    inputs = [self.audioSession.currentRoute inputs];
    if([inputs count] < 1) {
        NSLog(@"[hc] No inputs for current route! UNKNOWN change. ****");
        port = nil;
    } else {
        port = inputs[0];
    }

    if ([reason unsignedIntegerValue] == AVAudioSessionRouteChangeReasonNewDeviceAvailable) {
        NSLog(@"[hc] AVAudioSessionRouteChangeReasonNewDeviceAvailable");
        [self logRouteInformation:self.audioSession.currentRoute];
        [self connectToDevice:port isRouteChange:YES fireConnectEvents:NO];
    } else if ([reason unsignedIntegerValue] == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        NSLog(@"[hc] AVAudioSessionRouteChangeReasonOldDeviceUnavailable");
        [self logRouteInformation:[notification.userInfo objectForKey:AVAudioSessionRouteChangePreviousRouteKey]];
        [self logRouteInformation:self.audioSession.currentRoute];
        NSLog(@"[hc] New route:");
        [self connectToDevice:port isRouteChange:YES fireConnectEvents:NO];
    } else if ([reason unsignedIntegerValue] == AVAudioSessionRouteChangeReasonCategoryChange) {
        NSLog(@"[hc] AVAudioSessionRouteChangeReasonCategoryChange");
        NSLog(@"[hc] AVAudioSession category: %@, categoryOptions = %d",
              [self.audioSession category], (int) self.audioSession.categoryOptions);

        [self logRouteInformation:self.audioSession.currentRoute];

        if(!self.currentDevice || port == nil || ![self.currentDevice.portType isEqualToString:port.portType]) {
            NSLog(@"[hc] input port has changed. Performing route change.");
            [self connectToDevice:port isRouteChange:YES fireConnectEvents:NO];
        }
    } else {
        NSLog(@"[hc] Unknown route change reason: %u", (unsigned)[reason unsignedIntegerValue]);
    }
    DBG2(@"[hc] AVAudioSession sampleRate: %lf, preferredSampleRate: %lf",
         [self.audioSession sampleRate], [self.audioSession preferredSampleRate]);
}

- (void) getStatus:(CDVInvokedUrlCommand*)command {
    AVAudioSessionRouteDescription *route;
    AVAudioSessionPortDescription *port;
    BOOL bluetooth = NO;
    BOOL headset = NO;

    DBG(@"[hc] getStatus()");
    DBG2(@"[hc] AVAudioSession sampleRate: %lf, preferredSampleRate: %lf",
         [self.audioSession sampleRate], [self.audioSession preferredSampleRate]);

    for (port in [self.audioSession availableInputs]) {
        if ([[port portType] isEqualToString:AVAudioSessionPortHeadphones]) {
            headset = YES;
        } else if([[port portType] isEqualToString:AVAudioSessionPortBluetoothHFP]) {
            headset = YES;
            bluetooth = YES;
        } else if( [[port portType] isEqualToString:AVAudioSessionPortBluetoothA2DP] ) {
            headset = YES;
            bluetooth = YES;
        } else if([[port portType] isEqualToString:AVAudioSessionPortBluetoothLE]) {
            headset = NO;
            bluetooth = YES;
        }
    }

    route = [self.audioSession currentRoute];

    [self logRouteInformation:route];

    NSMutableDictionary * status = [[NSMutableDictionary alloc]init];
    [status setValue:@(bluetooth) forKey:@"bluetooth"];
    [status setValue:@(headset) forKey:@"headset"];
    [status setValue:@(self.audioSession.availableInputs.count) forKey:@"sources"];
    [status setValue:@(route.outputs.count) forKey:@"sinks"];
    [status setValue:@(self.isConnected) forKey:@"connected"];

    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:status];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getPermissions:(CDVInvokedUrlCommand*)command {
    DBG(@"[hc] getPermissions()");

    // Doesn't currently do anything for iOS.

    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) init:(CDVInvokedUrlCommand*)command {
    AVAudioSessionRouteDescription *route;

    DBG(@"[hc] init()");

    self.command = command;

    // Try to get the currentDevice if we don't have it yet.
    if(!self.currentDevice) {
        route = self.audioSession.currentRoute;
        @try {
            if([route.inputs count] > 0) {
                self.currentDevice = route.inputs[0];

                if(self.currentDevice) {
                    if([self.currentDevice.portType isEqualToString:AVAudioSessionPortHeadphones] ||
                    [self.currentDevice.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
                        self.isConnected = YES;
                    }
                }
            }
        }
        @catch(NSException *exception) {
            // This only seems to fail during Apple's review testing. (In pluginInitialize)
            // Likely something related to their test harness.
            // The issue is that an exception occurs dereferencing route.inputs.
            // We don't need that info yet, so can wait to get it later.
            // Feb 3, 2023 added check on count of route.inputs entries above so this is unlikely to happen any more.
            self.currentDevice = nil;
            NSLog(@"[hc] Unable to determine current device.");
        }
    }

    NSMutableDictionary * event = [[NSMutableDictionary alloc]init];
    [event setValue:@"init" forKey:@"type"];

    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:event];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) connect:(CDVInvokedUrlCommand*)command {
    AVAudioSessionPortDescription *port;
    AVAudioSessionRouteDescription *route;
    NSArray<AVAudioSessionPortDescription *> *inputs;
    CDVPluginResult * pluginResult;
    BOOL routeChange = NO;

    DBG(@"[hc] connect()");

    route = [self.audioSession currentRoute];
    if([route.inputs count] > 0) {
        port = route.inputs[0];
        routeChange = NO;
    } else {
        NSLog(@"[hc] connect() - no inputs for the current route!");
        [self logRouteInformation:route];

        routeChange = YES;

        inputs = [self.audioSession availableInputs];
        if([inputs count] > 0) {
            port = inputs[0];
            NSLog(@"[hc] connect() - first available input is %@", [port portName]);
        } else {
            port = nil;
            NSLog(@"[hc] connect() - no inputs available! ***");
        }
    }

    if(port) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

        [self connectToDevice:port isRouteChange:routeChange fireConnectEvents:YES];
    } else {
        // No port available!
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No audio import ports found."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void) disconnect:(CDVInvokedUrlCommand*)command {
    DBG(@"[hc] disconnect()");

    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

    [self disconnectFromCurrentDevice:YES fireDisconnectEvents:YES];
}

-(void) fireConnectEvent:(NSString *) type forDevice:(NSString *) deviceType withSubType:(NSString *) subType withName:(NSString *) name
{
    NSMutableDictionary * event = [[NSMutableDictionary alloc]init];
    [event setValue:type forKey:@"type"];
    [event setValue:deviceType forKey:@"device"];

    DBG2(@"[hc] fireConnectEvent(): type: %@, device: %@", type, deviceType);

    if(subType != NULL) {
        [event setValue:subType forKey:@"subType"];
        DBG1(@"[hc]                     subType: %@", subType);
    }

    if(name != NULL) {
        [event setValue:name forKey:@"name"];
        DBG1(@"[hc]                     name: %@", name);
    }

    self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:event];
    [self.pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:self.pluginResult callbackId:self.command.callbackId];
}

-(void) fireConnectEvent:(NSString *) type forDevice:(NSString *) deviceType withSubType:(NSString *) subType
{
    [self fireConnectEvent:type forDevice:deviceType withSubType:subType withName:NULL];
}

-(void) fireConnectEvent:(NSString *) type forDevice:(NSString *) deviceType withName:(NSString *) name
{
    [self fireConnectEvent:type forDevice:deviceType withSubType:deviceType withName:name];
}

-(void) fireConnectEvent:(NSString *) type forDevice:(NSString *) deviceType
{
    [self fireConnectEvent:type forDevice:deviceType withSubType:NULL withName:NULL];
}

-(void) disconnectFromCurrentDevice:(BOOL) routeChange fireDisconnectEvents:(BOOL) disconnectEvents
{
    AVAudioSessionPortDescription *port;
    port = [self currentDevice];
    if(!port) {
        return;
    }

    DBG1(@"[hc] disconnectFromCurrentDevice: %@", port.portType);

    if([port.portType isEqualToString:AVAudioSessionPortBluetoothHFP]) {
        if(self.scoConnected || disconnectEvents) {
            [self fireConnectEvent:(NSString *)@"disconnect" forDevice:(NSString *)@"bluetooth" withSubType:@"sco" withName:port.portName];
            self.scoConnected = NO;
        }
        [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"bluetooth" withSubType:@"sco" withName:port.portName];

        if(routeChange) {
            [self fireConnectEvent:(NSString *)@"disconnect" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];
            [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];
        }
    } else if([port.portType isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
        if(self.a2dpConnected || disconnectEvents) {
            [self fireConnectEvent:(NSString *)@"disconnect" forDevice:(NSString *)@"bluetooth" withSubType:@"a2dp" withName:port.portName];
            self.a2dpConnected = NO;
        }
        [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"bluetooth" withSubType:@"a2dp" withName:port.portName];

        if(routeChange) {
            [self fireConnectEvent:(NSString *)@"disconnect" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];
            [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];
        }
    } else if([port.portType isEqualToString:AVAudioSessionPortHeadphones]) {
        if(disconnectEvents) {
            [self fireConnectEvent:(NSString *)@"disconnect" forDevice:(NSString *)@"wired" withName:port.portName];
        }
        [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"wired" withName:port.portName];
    } else {
        if(disconnectEvents) {
            [self fireConnectEvent:(NSString *)@"disconnect" forDevice:(NSString *)@"mic" withName:port.portName];
        }
        [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"mic" withName:port.portName];
    }

    self.isConnected = NO;
    self.currentDevice = nil;
}

-(void) connectToDevice:(AVAudioSessionPortDescription *) port isRouteChange:(BOOL) routeChange fireConnectEvents:(BOOL) connectEvents
{
    BOOL doConnect = self.isConnected || connectEvents;

    DBG(@"[hc] connectToDevice()");

    if(!port) {
        DBG(@"[hc] no port specified! Send disconnect events.");
        [self disconnectFromCurrentDevice:YES fireDisconnectEvents:YES];
        return;
    }

    if(routeChange) {
        [self disconnectFromCurrentDevice:routeChange fireDisconnectEvents:NO];
    }

    if(self.isConnected && ![port.portType isEqualToString:self.currentDevice.portType]) {
        [self disconnectFromCurrentDevice:NO fireDisconnectEvents:NO];
    }

    DBG1(@"[hc] connect to port: %@", port.portType);

    if([port.portType isEqualToString:AVAudioSessionPortBluetoothHFP]) {
        if(doConnect) {
            [self fireConnectEvent:(NSString *)@"connect" forDevice:(NSString *)@"bluetooth" withSubType:@"sco" withName:port.portName];
        }

        if(routeChange) {
            [self fireConnectEvent:(NSString *)@"connect" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];
        }

        [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];

        if(doConnect) {
            self.scoConnected = YES;
            [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"bluetooth" withSubType:@"sco" withName:port.portName];
        }
    } else if([port.portType isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
        if(doConnect) {
            [self fireConnectEvent:(NSString *)@"connect" forDevice:(NSString *)@"bluetooth" withSubType:@"a2dp" withName:port.portName];
        }

        if(routeChange) {
            [self fireConnectEvent:(NSString *)@"connect" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];
        }

        [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];

        if(doConnect) {
            self.a2dpConnected = YES;
            [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"bluetooth" withSubType:@"a2dp" withName:port.portName];
        }
    } else if([port.portType isEqualToString:AVAudioSessionPortHeadphones]) {
        if(doConnect) {
            [self fireConnectEvent:(NSString *)@"connect" forDevice:(NSString *)@"wired" withName:port.portName];
        }

        [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"wired" withName:port.portName];
    } else {
        if(doConnect) {
            [self fireConnectEvent:(NSString *)@"connect" forDevice:(NSString *)@"mic" withName:port.portName];
        }

        [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"mic" withName:port.portName];
    }

    self.isConnected = YES;
    self.currentDevice = port;
}

-(void) logRouteInformation:(AVAudioSessionRouteDescription *) route
{
    int i;
    NSArray<AVAudioSessionPortDescription *> *ports;
    AVAudioSessionPortDescription *port;

    NSLog(@"[hc] logRouteInformation()");

    ports = route.inputs;

    for(i = 0; i < ports.count; i++) {
        port = ports[i];

        NSLog(@"[hc]  input %d - type: %@, name %@", i, port.portType, port.portName);
    }

    ports = route.outputs;

    for(i = 0; i < ports.count; i++) {
        port = ports[i];

        NSLog(@"[hc] output %d - type: %@, name %@", i, port.portType, port.portName);
    }

    ports = [self.audioSession availableInputs];

    for(i = 0; i < ports.count; i++) {
        port = ports[i];

        NSLog(@"[hc]  avail %d - type: %@, name %@", i, port.portType, port.portName);
    }
}

@end
