/*! ********************************************************************
 *
 * Copyright (c) 2018-2020, Fisherlea Systems
 *
 * This software contains proprietary information that is the property
 * of Fisherlea Systems. All Rights Reserved.
 *
 ***********************************************************************/

var exec = require('cordova/exec');

/** 
 * Cordova plugin for control of Bluetooth headsets.
 *
 * @class Cordova plugin for control of Bluetooth headsets.
 */
function HeadsetControl() {
    /** Connected state of the headset.
     * @type boolean
     * @default false;
     */
    this.connected = false;

    /** Fired for all events.
     * @type function
     */
    this.onevent = null;

    /** Fired for events related to the in process connection of a device.
     *  May not be called for all devices.
     * @type function
     */
    this.onconnecting = null;

    /** Fired for events related to the pending connection of a device.
     * @type function
     */
    this.onconnect = null;

    /** Fired for events related to the in process disconnection of a device.
     *  May not be called for all devices.
     * @type function
     */
    this.ondisconnecting = null;

    /** Fired for events related to the pending disconnection of a device.
     * @type function
     */
    this.ondisconnect = null;

    /** Fired for events related to the completed connection of a device.
     * @type function
     */
    this.onconnected = null;

    /** Fired for events related to the completed disconnection of a device.
     * @type function
     */
    this.ondisconnected = null;

    /** Fired for errors.
     * @type function
     */
    this.onerror = null;

    /** Connect timer.
     * @private
     */
    this._connectTimer = null;

    this._init();
}

/**
 * Initialize the plugin.
 * @private
 */
HeadsetControl.prototype._init = function () {
    var that = this;

    exec(function(event) {
        if (typeof event !== "object" || event.type == "init") {
            return;
        }

        if (typeof that.onevent === "function") {
            that.onevent(event);
        }

        switch (event.type) {
            case "connected":
                if ((event.device == "mic") ||
		    (event.device == "wired") ||
                    (event.device == "bluetooth" && event.subType == "sco")) {
                    that.connected = true;
                }

                if (typeof that.onconnected === "function") {
                    that.onconnected(event);
                }
                break;

            case "disconnected":
                that.connected = false;

                if(typeof that.ondisconnected === "function") {
                    that.ondisconnected(event);
                }
                break;

            case "connecting":
                if(typeof that.onconnecting === "function") {
                    that.onconnecting(event);
                }
                break;

            case "connect":
                if(typeof that.onconnect === "function") {
                    that.onconnect(event);
                }
                break;

            case "disconnecting":
                if(typeof that.ondisconnecting === "function") {
                    that.ondisconnecting(event);
                }
                break;

            case "disconnect":
                if (that._connectTimer) {
                    clearTimeout(that._connectTimer);
                    that._connectTimer = null;
                }

                if (typeof that.ondisconnect === "function") {
                    that.ondisconnect(event);
                }
                break;

            default:
                if (event.type) {
                    console.warn("HeadsetControl - Unknown event: " + event.type);
                }
                break;
        }
    }, function(error) {
        if(typeof that.onerror === "function") {
            that.onerror(error);
        }
    }, "HeadsetControl", "init", []);
};

/**
 * Connect to the headset. Preference is given to Bluetooth devices.
 * @param {number} [duration=0] The amount of time that the connection should be maintained, in seconds.
 *      A value of 0 indicates that the connection should be maintained until an explicit {@link #disconnect} call is made.
 * @param {function} [success] The success callback.
 * @param {function} [failure] The failure callback.
 */
HeadsetControl.prototype.connect = function (duration, success, failure) {
    var that = this;

    if (this._connectTimer) {
        clearTimeout(this._connectTimer);
    }

    if (duration) {
        this._connectTimer = setTimeout(function () {
            that.disconnect();
            that._connectTimer = null;
        }, duration * 1000);
    }

    exec(success, failure, "HeadsetControl", "connect", []);
};

/**
 * Get the status of the plugin and the device connection.
 * @param {function} [success] The success callback. The status object is passed in as the first parameter.
 * @param {function} [failure] The failure callback.
 */
HeadsetControl.prototype.getStatus = function (success, failure) {
    exec(success, failure, "HeadsetControl", "getStatus", []);
};

/**
 * Disconnect from the headset.
 * @param {function} [success] The success callback.
 * @param {function} [failure] The failure callback.
 */
HeadsetControl.prototype.disconnect = function (success, failure) {
    if (this._connectTimer) {
        clearTimeout(this._connectTimer);
        this._connectTimer = null;
    }

    exec(success, failure, "HeadsetControl", "disconnect", []);
};

module.exports = new HeadsetControl();
