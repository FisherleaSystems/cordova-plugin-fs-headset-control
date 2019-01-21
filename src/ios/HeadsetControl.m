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

    self.a2dpConnected = NO;
    self.scoConnected = NO;
    self.headsetConnected = NO;
    self.headphonesConnected = NO;
    self.micConnected = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChanged:) name:AVAudioSessionRouteChangeNotification object:nil];

    self.audioSession = [AVAudioSession sharedInstance];

    NSLog(@"[hc] setCategory to PlayAndRecord and enable Bluetooth.");
    // Play and record is needed for access to bluetooth headsets.
    // See https://developer.apple.com/documentation/avfoundation/avaudiosessioncategoryoptions/avaudiosessioncategoryoptionallowbluetooth
    if(![self.audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                           withOptions:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionAllowBluetoothA2DP
                                 error:&error]) {
        NSLog(@"[hc] Unable to setCategory: %@", error);
    }
}

- (void)routeChanged:(NSNotification *)notification {
    NSNumber *reason = [notification.userInfo objectForKey:AVAudioSessionRouteChangeReasonKey];

    DBG(@"[hc] routeChanged");

    AVAudioSessionRouteDescription *route;
    NSArray<AVAudioSessionPortDescription *> *ports;
    AVAudioSessionPortDescription *port;

    route = self.audioSession.currentRoute;

    if ([reason unsignedIntegerValue] == AVAudioSessionRouteChangeReasonNewDeviceAvailable) {
        NSLog(@"[hc] AVAudioSessionRouteChangeReasonNewDeviceAvailable");
    } else if ([reason unsignedIntegerValue] == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        NSLog(@"[hc] AVAudioSessionRouteChangeReasonOldDeviceUnavailable");
        route = [notification.userInfo objectForKey:AVAudioSessionRouteChangePreviousRouteKey];
    } else if ([reason unsignedIntegerValue] == AVAudioSessionRouteChangeReasonCategoryChange) {
        NSLog(@"[hc] AVAudioSessionRouteChangeReasonCategoryChange");
        NSLog(@"[hc] AVAudioSession category: %@, categoryOptions = %d",
              [self.audioSession category], (int) self.audioSession.categoryOptions);
    } else {
        NSLog(@"[hc] Unknown reason: %u", (unsigned)[reason unsignedIntegerValue]);
    }
    DBG2(@"[hc] AVAudioSession sampleRate: %lf, preferredSampleRate: %lf",
         [self.audioSession sampleRate], [self.audioSession preferredSampleRate]);

#if 0
    logRouteInformation(route);
#endif

    if ([reason unsignedIntegerValue] == AVAudioSessionRouteChangeReasonNewDeviceAvailable) {
        ports = route.outputs;
        port = ports[0];

        if(self.micConnected) {
            self.micConnected = NO;
            [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"wired" withSubType:@"mic"];
        }

        if([port.portType isEqualToString:AVAudioSessionPortBluetoothHFP]) {
            if(self.a2dpConnected) {
                [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"bluetooth" withSubType:@"a2dp"];
            }
            [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];
            if(self.a2dpConnected) {
                self.a2dpConnected = NO;
                self.scoConnected = YES;
                [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"bluetooth" withSubType:@"sco" withName:port.portName];
            }
        } else if([port.portType isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
            if(self.scoConnected) {
                [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"bluetooth" withSubType:@"sco"];
            }
            [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];
            if(self.scoConnected) {
                self.scoConnected = NO;
                self.a2dpConnected = YES;
                [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"bluetooth" withSubType:@"audio" withName:port.portName];
            }
        } else if([port.portType isEqualToString:AVAudioSessionPortHeadphones]) {
            self.headphonesConnected = YES;
            [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"wired" withSubType:@"mic" withName:port.portName];
        } else {
            [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"unknown" withSubType:@"unknown" withName:port.portName];
        }
    } else if ([reason unsignedIntegerValue] == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        ports = route.outputs;
        port = ports[0];

        if([port.portType isEqualToString:AVAudioSessionPortBluetoothHFP]) {
            if(self.scoConnected) {
                self.scoConnected = NO;
                [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"bluetooth" withSubType:@"sco" withName:port.portName];
            }
            self.headsetConnected = NO;
            [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];
        } else if([port.portType isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
            if(self.a2dpConnected) {
                self.a2dpConnected = NO;
                [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"bluetooth" withSubType:@"a2dp" withName:port.portName];
            }
            self.headsetConnected = NO;
            [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"bluetooth" withSubType:@"audio" withName:port.portName];
        } else if([port.portType isEqualToString:AVAudioSessionPortHeadphones]) {
            self.headphonesConnected = NO;
            [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"wired" withSubType:@"mic" withName:port.portName];
        } else {
            self.micConnected = NO;
            [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"unknown" withSubType:@"unknown" withName:port.portName];
        }
    }
}

- (void) getStatus:(CDVInvokedUrlCommand*)command {
    AVAudioSessionRouteDescription *route;
    AVAudioSessionPortDescription *port;
    BOOL bluetooth = NO;
    BOOL headset = NO;
    BOOL connected = NO;

    NSLog(@"[hc] getStatus()");
    NSLog(@"[hc] AVAudioSession sampleRate: %lf, preferredSampleRate: %lf",
          [self.audioSession sampleRate], [self.audioSession preferredSampleRate]);

    for (port in [audioSession availableInputs]) {
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

    route = [audioSession currentRoute];
    port = route.inputs[0];
    if(bluetooth) {
        if(headset) {
            if( [[port portType] isEqualToString:AVAudioSessionPortBluetoothHFP] ||
                [[port portType] isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
                connected = YES;
            }
        }
    } else {
        connected = YES;
    }

#if 0
    logRouteInformation(route);
#endif

    NSMutableDictionary * status = [[NSMutableDictionary alloc]init];
    [status setValue:@(bluetooth) forKey:@"bluetooth"];
    [status setValue:@(headset) forKey:@"headset"];
    [status setValue:@(audioSession.availableInputs.count) forKey:@"sources"];
    [status setValue:@(route.outputs.count) forKey:@"sinks"];
    [status setValue:@(connected) forKey:@"connected"];

    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:status];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) init:(CDVInvokedUrlCommand*)command {
    NSLog(@"[hc] init()");

    self.command = command;

    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) connect:(CDVInvokedUrlCommand*)command {
    AVAudioSessionPortDescription *port;
    AVAudioSessionRouteDescription *route;

    DBG(@"[hc] connect()");

    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

    route = [self.audioSession currentRoute];
    port = route.inputs[0];

    if([port.portType isEqualToString:AVAudioSessionPortBluetoothHFP]) {
        [self fireConnectEvent:(NSString *)@"connect" forDevice:(NSString *)@"bluetooth" withSubType:@"sco" withName:port.portName];
        self.headsetConnected = YES;
        [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];
        self.scoConnected = YES;
        [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"bluetooth" withSubType:@"sco" withName:port.portName];
    } else if([port.portType isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
        [self fireConnectEvent:(NSString *)@"connect" forDevice:(NSString *)@"bluetooth" withSubType:@"a2dp" withName:port.portName];
        self.headsetConnected = YES;
        [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];
        self.a2dpConnected = YES;
        [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"bluetooth" withSubType:@"a2dp" withName:port.portName];
    } else if([port.portType isEqualToString:AVAudioSessionPortHeadphones]) {
        [self fireConnectEvent:(NSString *)@"connect" forDevice:(NSString *)@"wired"];
        self.headphonesConnected = YES;
        [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"wired"];
    } else {
        [self fireConnectEvent:(NSString *)@"connect" forDevice:(NSString *)@"mic"];
        self.micConnected = YES;
        [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"mic"];
    }
}

- (void) disconnect:(CDVInvokedUrlCommand*)command {
    AVAudioSessionPortDescription *port;
    AVAudioSessionRouteDescription *route;

    DBG(@"[hc] disconnect()");

    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

    route = [self.audioSession currentRoute];
    port = route.inputs[0];

    if([port.portType isEqualToString:AVAudioSessionPortBluetoothHFP]) {
        [self fireConnectEvent:(NSString *)@"disconnect" forDevice:(NSString *)@"bluetooth" withSubType:@"sco" withName:port.portName];
        self.scoConnected = NO;
        [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"bluetooth" withSubType:@"sco" withName:port.portName];
        // The headset disconnect event will come from the routeChanged(0) handler
        //[self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];
    } else if([port.portType isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
        [self fireConnectEvent:(NSString *)@"disconnect" forDevice:(NSString *)@"bluetooth" withSubType:@"a2dp" withName:port.portName];
        self.a2dpConnected = NO;
        [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"bluetooth" withSubType:@"a2dp" withName:port.portName];
        // The headset disconnect event will come from the routeChanged(0) handler
        //[self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];
    } else if([port.portType isEqualToString:AVAudioSessionPortHeadphones]) {
        [self fireConnectEvent:(NSString *)@"disconnect" forDevice:(NSString *)@"wired"];
        self.headphonesConnected = NO;
        [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"wired"];
    } else {
        [self fireConnectEvent:(NSString *)@"disconnect" forDevice:(NSString *)@"mic"];
        self.micConnected = NO;
        [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"mic"];
    }
}

-(void) fireConnectEvent:(NSString *) type forDevice:(NSString *) deviceType withSubType:(NSString *) subType withName:(NSString *) name
{
    NSMutableDictionary * event = [[NSMutableDictionary alloc]init];
    [event setValue:type forKey:@"type"];

    NSLog(@"[hc] fireConnectEvent(): type: %@, device: %@", type, deviceType);

    if(subType != NULL) {
        [event setValue:subType forKey:@"subType"];
        NSLog(@"[hc]                     subType: %@", subType);
    }

    if(name != NULL) {
        [event setValue:name forKey:@"name"];
        NSLog(@"[hc]                     name: %@", name);
    }

    self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:event];
    [self.pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:self.pluginResult callbackId:self.command.callbackId];
}

-(void) fireConnectEvent:(NSString *) type forDevice:(NSString *) deviceType withSubType:(NSString *) subType
{
    [self fireConnectEvent:type forDevice:deviceType withSubType:subType withName:NULL];
}

-(void) fireConnectEvent:(NSString *) type forDevice:(NSString *) deviceType
{
    [self fireConnectEvent:type forDevice:deviceType withSubType:NULL withName:NULL];
}

-(void) logRouteInformation:(AVAudioSessionRouteDescription *) route
{
    int i;
    NSArray<AVAudioSessionPortDescription *> *ports;
    ports = route.inputs;

    for(i = 0; i < ports.count; i++) {
        port = ports[i];

        NSLog(@"[hc] input %d: description: %@", i, port.description);
        //NSLog(@"[hc]                  name: %@", port.portName);
        //NSLog(@"[hc]                  type: %@", port.portType);
    }

    ports = route.outputs;

    for(i = 0; i < ports.count; i++) {
        port = ports[i];

        NSLog(@"[hc] output %d: description: %@", i, port.description);
        //NSLog(@"[hc]                   name: %@", port.portName);
        //NSLog(@"[hc]                   type: %@", port.portType);
    }

    ports = [self.audioSession availableInputs];

    for(i = 0; i < ports.count; i++) {
        port = ports[i];

        NSLog(@"[hc] avail %d: description: %@", i, port.description);
        //NSLog(@"[hc]                  name: %@", port.portName);
        //NSLog(@"[hc]                  type: %@", port.portType);
    }
}

@end
