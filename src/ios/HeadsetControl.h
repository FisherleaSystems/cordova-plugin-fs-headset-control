/*! ********************************************************************
 *
 * Copyright (c) 2018-2022, Fisherlea Systems
 *
 * Licensed under the MIT license. See the LICENSE file in the root
 * directory for more details.
 *
 ***********************************************************************/

#import <AVFoundation/AVFoundation.h>
#import <Cordova/CDV.h>

@interface HeadsetControl : CDVPlugin

@property(nonatomic, readwrite) BOOL scoConnected;
@property(nonatomic, readwrite) BOOL a2dpConnected;
@property(nonatomic, readwrite) BOOL isConnected;
@property(nonatomic, strong) AVAudioSessionPortDescription *currentDevice;
@property(nonatomic, strong) AVAudioSession *audioSession;
@property(nonatomic, strong) CDVInvokedUrlCommand *command;
@property(nonatomic, strong) CDVPluginResult *pluginResult;

- (void)getStatus:(CDVInvokedUrlCommand *)command;
- (void)init:(CDVInvokedUrlCommand *)command;
- (void)connect:(CDVInvokedUrlCommand *)command;
- (void)disconnect:(CDVInvokedUrlCommand *)command;

@end
