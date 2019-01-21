#import <AVFoundation/AVFoundation.h>
#import <Cordova/CDV.h>

@interface HeadsetControl:CDVPlugin

@property (nonatomic, readwrite) BOOL micConnected;
@property (nonatomic, readwrite) BOOL headphonesConnected;
@property (nonatomic, readwrite) BOOL headsetConnected;
@property (nonatomic, readwrite) BOOL scoConnected;
@property (nonatomic, readwrite) BOOL a2dpConnected;
@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, strong) CDVInvokedUrlCommand * command;
@property (nonatomic, strong) CDVPluginResult* pluginResult;

- (void) getStatus:(CDVInvokedUrlCommand*)command;
- (void) init:(CDVInvokedUrlCommand*)command;
- (void) connect:(CDVInvokedUrlCommand*)command;
- (void) disconnect:(CDVInvokedUrlCommand*)command;

@end
