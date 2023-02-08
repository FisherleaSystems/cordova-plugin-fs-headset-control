# HeadsetControl

Headset control plugin for Cordova.

Detect and control connection to a wired or Bluetooth headset for Android and Apple iOS.

For Android, it works to set up a Bluetooth connection and generates events to indicate the connection status.

For iOS, it mostly justs sets the audio session category and lets iOS manage the Bluetooth connection while it
monitors the status to be able to generate the appropriate events.

# Usage

The plugin creates a **HeadsetControl** global variable that has the following members:

-   _connected_ (boolean) - The connected state of the headset.
-   _onconnect_ (function) - Fired for events related to the pending connection of a device.
-   _onconnected_ (function) - Fired for events related to the completed connection of a device.
-   _onconnecting_ (function) - Fired for events related to the in progress connection of a device.
    May not be called for all devices.
-   _ondisconnect_ (function) - Fired for events related to the pending disconnection of a device.
-   _ondisconnected_ (function) - Fired for events related to the completed disconnection of a device.
-   _ondisconnecting_ (function) - Fired for events related to the in progress disconnection of a device.
    May not be called for all devices.
-   _onerror_ (function) - Fired for errors.
-   _onevent_ (function) - Fired for all events.

# Events

The event callback functions are called with the event as the only parameter.
The event objects have some of the following members defined:

-   _type_ (string) - The event type. One of _connect_, _connecting_, _connected_, _disconnect_, _disconnecting_, _disconnected_.
-   _device_ (string) - The device associated with the event. One of _bluetooth_, _wired_, _mic_.
-   _subType_ (string) - The device sub-type. One of _headset_, _acl_, _sco_.
-   _name_ (string) - The device's name.

# Functions

The following member functions are available on the **HeadsetControl** global object:

-   _connect(duration, success, failure)_
    -   Connect to the headset. Preference is given to Bluetooth devices.
-   _disconnect(success, failure)_
    -   Disconnect from the headset.
-   _getPermissions(success, failure)_
    -   Request the required permissions from the OS.
-   _getStatus(success, failure)_
    -   Get the status of the plugin and the device connection.

# Cordova Installation

To install for use in your Cordova app, first create a file called **.npmrc** at the root level of your Cordova project if it does not already exist. Add the following line to this file to specify to NPM and Cordova which registry to look in to find the package for this plugin:

    @fisherleasystems:registry=https://npm.pkg.github.com

Then, using the command line tools run:

    cordova plugin add @fisherleasystems/cordova-plugin-fs-headset-control

Or, to install directly from the GitHub repository, run the following:

    cordova plugin add https://github.com/FisherleaSystems/HeadsetControl

# Credits

Initially based on the [cordova-plugin-headsetdetection](https://github.com/EddyVerbruggen/HeadsetDetection-PhoneGap-Plugin) plugin.
