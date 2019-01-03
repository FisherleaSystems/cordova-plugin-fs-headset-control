var exec = require('cordova/exec');

function HeadsetControl() {
    /** Fired for all events. */
    this.onevent = null;

    /** Fired for events related to connecting/disconnecting of devices. */
    this.onconnecting = null;
    this.onconnect = null;
    this.ondisconnecting = null;
    this.ondisconnect = null;

    /** Fired as a response to connect/disconnect calls. */
    this.onconnected = null;
    this.ondisconnected = null;

    /** Fired for errors. */
    this.onerror = null;

    this._init();
}

HeadsetControl.prototype._init = function () {
    var that = this;

    exec(function(event) {
        if (typeof that.onevent === "function") {
            that.onevent(event);
        }
        switch (event.type) {
            case "connected":
                if(typeof that.onconnected === "function") {
                    that.onconnected(event);
                }
                break;

            case "disconnected":
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
                if(typeof that.ondisconnect === "function") {
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

HeadsetControl.prototype.connect = function (success, failure) {
    exec(success, failure, "HeadsetControl", "connect", []);
};

HeadsetControl.prototype.detect = function (success, failure) {
    exec(success, failure, "HeadsetControl", "detect", []);
};

HeadsetControl.prototype.disconnect = function (success, failure) {
    exec(success, failure, "HeadsetControl", "disconnect", []);
};

module.exports = new HeadsetControl();
