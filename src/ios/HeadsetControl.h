#import <AVFoundation/AVFoundation.h>
#import <Cordova/CDV.h>

@interface HeadsetControl:CDVPlugin

@property (nonatomic, strong) CDVInvokedUrlCommand * command;
@property (nonatomic, strong) CDVPluginResult* pluginResult;
@property (nonatomic, strong) AVAudioSessionRouteDescription *currentRoute;

- (void) getStatus:(CDVInvokedUrlCommand*)command;
- (void) init:(CDVInvokedUrlCommand*)command;
- (void) connect:(CDVInvokedUrlCommand*)command;
- (void) disconnect:(CDVInvokedUrlCommand*)command;

@end
