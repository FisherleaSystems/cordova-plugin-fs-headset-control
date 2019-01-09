#import "HeadsetControl.h"

@implementation HeadsetControl

- (void) pluginInitialize {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChanged:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)routeChanged:(NSNotification *)notification {
    NSNumber *reason = [notification.userInfo objectForKey:AVAudioSessionRouteChangeReasonKey];

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionRouteDescription *route;
    NSArray<AVAudioSessionPortDescription *> *ports;
    AVAudioSessionPortDescription *port;

    if ([reason unsignedIntegerValue] == AVAudioSessionRouteChangeReasonNewDeviceAvailable) {
        route = audioSession.currentRoute;
    } else if ([reason unsignedIntegerValue] == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        route = [notification.userInfo objectForKey:AVAudioSessionRouteChangePreviousRouteKey];
    }
    self.currentRoute = route;

#if 0
    int i;
    ports = route.inputs;

    for(i = 0; i < ports.count; i++) {
        port = ports[i];

        NSLog(@"input port %d: description: %@", i, port.description);
        NSLog(@"                      name: %@", port.portName);
        NSLog(@"                      type: %@", port.portType);
    }

    ports = route.outputs;

    for(i = 0; i < ports.count; i++) {
        port = ports[i];

        NSLog(@"output port %d: description: %@", i, port.description);
        NSLog(@"                       name: %@", port.portName);
        NSLog(@"                       type: %@", port.portType);
    }
#endif

    if ([reason unsignedIntegerValue] == AVAudioSessionRouteChangeReasonNewDeviceAvailable) {
        ports = route.outputs;
        port = ports[0];

        if([port.portType isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
            [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];
        } else if([port.portType isEqualToString:AVAudioSessionPortHeadphones]) {
            [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"wired"];
        }
    } else if ([reason unsignedIntegerValue] == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        ports = route.outputs;
        port = ports[0];

        if([port.portType isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
            [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];
        } else if([port.portType isEqualToString:AVAudioSessionPortHeadphones]) {
            [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"wired"];
        }
    }
}

- (void) getStatus:(CDVInvokedUrlCommand*)command {
    BOOL bluetooth = NO;
    BOOL headset = NO;

    NSLog(@"getStatus()");

    for (AVAudioSessionPortDescription* desc in [self.currentRoute outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones]) {
            headset = YES;
        } else if([[desc portType] isEqualToString:AVAudioSessionPortBluetoothHFP]) {
            headset = YES;
            bluetooth = YES;
        } else if( [[desc portType] isEqualToString:AVAudioSessionPortBluetoothA2DP] ) {
            headset = YES;
            bluetooth = YES;
        } else if([[desc portType] isEqualToString:AVAudioSessionPortBluetoothLE]) {
            headset = YES;
            bluetooth = YES;
        }
    }

    NSMutableDictionary * status = [[NSMutableDictionary alloc]init];
    [status setValue:bluetooth forKey:@"bluetooth"];
    [status setValue:headset forKey:@"headset"];
    [status setValue:route.inputs.count forKey:@"sources"];
    [status setValue:route.outputs.count forKey:@"sinks"];
    [status setValue:YES forKey:@"connected"];

    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:event];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) init:(CDVInvokedUrlCommand*)command {
    NSLog(@"init()");

    self.command = command;

    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) connect:(CDVInvokedUrlCommand*)command {
    int i;
    AVAudioSessionPortDescription *port;

    NSLog(@"connect()");

    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

    port = self.currentRoute.outputs[0];

    if([port.portType isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
        [self fireConnectEvent:(NSString *)@"connect" forDevice:(NSString *)@"bluetooth" withSubType:@"sco" withName:port.portName];
        [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];
        [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"bluetooth" withSubType:@"sco" withName:port.portName];
    } else if([port.portType isEqualToString:AVAudioSessionPortHeadphones]) {
        [self fireConnectEvent:(NSString *)@"connect" forDevice:(NSString *)@"wired"];
        [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"wired"];
    } else {
        [self fireConnectEvent:(NSString *)@"connect" forDevice:(NSString *)@"mic"];
        [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"mic"];
    }
}

- (void) disconnect:(CDVInvokedUrlCommand*)command {
    int i;
    AVAudioSessionPortDescription *port;

    NSLog(@"disconnect()");

    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

    port = self.currentRoute.outputs[0];

    if([port.portType isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
        [self fireConnectEvent:(NSString *)@"disconnect" forDevice:(NSString *)@"bluetooth" withSubType:@"sco" withName:port.portName];
        [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"bluetooth" withSubType:@"sco" withName:port.portName];
        [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];
    } else if([port.portType isEqualToString:AVAudioSessionPortHeadphones]) {
        [self fireConnectEvent:(NSString *)@"disconnect" forDevice:(NSString *)@"wired"];
        [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"wired"];
    } else {
        [self fireConnectEvent:(NSString *)@"disconnect" forDevice:(NSString *)@"mic"];
        [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"mic"];
    }
}

-(void) fireConnectEvent:(NSString *) type forDevice:(NSString *) deviceType withSubType:(NSString *) subType withName:(NSString *) name
{
    NSMutableDictionary * event = [[NSMutableDictionary alloc]init];
    [event setValue:type forKey:@"type"];

    NSLog(@"fireConnectEvent(): type: %@", type);

    if(deviceType != NULL) {
        [event setValue:deviceType forKey:@"device"];
        NSLog(@"                    device: %@", deviceType);
    }

    if(subType != NULL) {
        [event setValue:subType forKey:@"subType"];
        NSLog(@"                    subType: %@", subType);
    }

    if(name != NULL) {
        [event setValue:name forKey:@"name"];
        NSLog(@"                    name: %@", name);
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

@end
