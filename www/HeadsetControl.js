var exec = require('cordova/exec');

function HeadsetControl() {
    this.onevent = null;
    this.onconnecting = null;
    this.onconnect = null;
    this.ondisconnecting = null;
    this.ondisconnect = null;
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
                console.warn("HeadsetControl - Unknown event: " + event.type);
                break;
        }
    }, function(error) {
        if(typeof that.onerror === "function") {
            that.onerror(error);
        }
    }, "HeadsetControl", "init", []);
};

HeadsetControl.prototype.detect = function (success, failure) {
    exec(success, failure, "HeadsetControl", "detect", []);
};

module.exports = HeadsetControl;
