# SpeechSynthesisPlugin

Headset control plugin for Cordova.

Detect and control connection to a wired or Bluetooth headset for Android and Apple iOS

# Installation

## Cordova

To install for use in your Cordova app, first create a file called **.npmrc** at the root level of your Cordova project if it does not already exist. Add the following line to this file to specify to NPM and Cordova which registry to look in to find the package for this plugin:

    @fisherleasystems:registry=https://npm.pkg.github.com

Then, using the command line tools run:

    cordova plugin add @fisherleasystems/cordova-plugin-fs-headset-control

Or, to install directly from the GitHub repository, run the following:

    cordova plugin add https://github.com/FisherleaSystems/HeadsetControl

# Credits

Initially based on the [cordova-plugin-headsetdetection](https://github.com/EddyVerbruggen/HeadsetDetection-PhoneGap-Plugin) plugin.
