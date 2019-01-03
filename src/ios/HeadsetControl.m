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
            [self fireConnectEvent:(NSString *)@"connect" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];
        } else if([port.portType isEqualToString:AVAudioSessionPortHeadphones]) {
            [self fireConnectEvent:(NSString *)@"connect" forDevice:(NSString *)@"wired"];
        }
    } else if ([reason unsignedIntegerValue] == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        ports = route.outputs;
        port = ports[0];

        if([port.portType isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
            [self fireConnectEvent:(NSString *)@"disconnect" forDevice:(NSString *)@"bluetooth" withSubType:@"headset" withName:port.portName];
        } else if([port.portType isEqualToString:AVAudioSessionPortHeadphones]) {
            [self fireConnectEvent:(NSString *)@"disconnect" forDevice:(NSString *)@"wired"];
        }
    }
}

- (void) detect:(CDVInvokedUrlCommand*)command {
  NSLog(@"detect()");

  CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[self isHeadsetEnabled]];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) init:(CDVInvokedUrlCommand*)command {
    NSLog(@"init()");
    // not implemented

    self.command = command;

    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) connect:(CDVInvokedUrlCommand*)command {
    NSLog(@"connect()");

    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

    // Respond for MIC for now.
    [self fireConnectEvent:(NSString *)@"connected" forDevice:(NSString *)@"mic"];
}

- (void) disconnect:(CDVInvokedUrlCommand*)command {
    NSLog(@"disconnect()");
    // not implemented

    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

    // Respond for MIC for now.
    [self fireConnectEvent:(NSString *)@"disconnected" forDevice:(NSString *)@"mic"];
}

- (BOOL) isHeadsetEnabled {
  AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
  for (AVAudioSessionPortDescription* desc in [route outputs]) {
    if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones] ||
        [[desc portType] isEqualToString:AVAudioSessionPortBluetoothHFP] ||
        [[desc portType] isEqualToString:AVAudioSessionPortBluetoothA2DP] ||
        [[desc portType] isEqualToString:AVAudioSessionPortBluetoothLE]) {
      return YES;
    }
  }
  return NO;
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
