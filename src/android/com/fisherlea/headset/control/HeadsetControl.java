package com.fisherlea.headset.control;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaWebView;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothHeadset;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.content.Context;
import android.media.AudioDeviceInfo;
import android.media.AudioManager;
import android.content.ComponentName;
import android.content.Intent;
import android.content.IntentFilter;
import android.speech.RecognizerIntent;
import android.util.Log;
import android.view.KeyEvent;
import android.content.BroadcastReceiver;
import android.bluetooth.BluetoothDevice;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class HeadsetControl extends CordovaPlugin {
    private static final String LOG_TAG = "HeadsetControl";

    private static final String ACTION_DETECT = "detect";
    private static final String ACTION_INIT = "init";

    private boolean scoStarted = false;
    private AudioManager audioManager;
    private BluetoothManager bluetoothManager;
    private BluetoothAdapter bluetoothAdapter;
    private BluetoothHeadset bluetoothHeadset;
    private CallbackContext initCallbackContext;

    protected static CordovaWebView mCachedWebView = null;

    BroadcastReceiver receiver;
    BluetoothProfile.ServiceListener serviceListener;

    public HeadsetControl()
    {
        this.receiver = null;
        this.serviceListener = null;
        this.bluetoothHeadset = null;
    }

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        mCachedWebView = webView;

        audioManager = (AudioManager) cordova.getActivity().getSystemService(Context.AUDIO_SERVICE);
        bluetoothManager = (BluetoothManager) cordova.getActivity().getSystemService(Context.BLUETOOTH_SERVICE);
        bluetoothAdapter = bluetoothManager.getAdapter(); // Jelly Bean (API 17) or older need getDefaultAdapter().

        serviceListener = new BluetoothProfile.ServiceListener() {
            private static final String LOG_TAG = "HeadsetProfileListener";

            public void onServiceConnected(int profile, BluetoothProfile proxy) {
                Log.d(LOG_TAG, "BluetoothProfile.ServiceListener().onServiceConnected(" + profile +")");
                bluetoothHeadset = (BluetoothHeadset) proxy;
                /*
                if(!scoStarted) {
                    audioManager.startBluetoothSco();
                    scoStarted = true;
                    Log.d(LOG_TAG, "startBluetoothSco()");
                }
                */
            };
            public void onServiceDisconnected(int profile) {
                Log.d(LOG_TAG, "BluetoothProfile.ServiceListener().onServiceDisconnected(" + profile +")");
                bluetoothHeadset = null;
                /*
                if(scoStarted) {
                    audioManager.stopBluetoothSco();
                    scoStarted = false;
                    Log.d(LOG_TAG, "stopBluetoothSco()");
                }
                */
            };
        };

        Log.d(LOG_TAG, "Getting Bluetooth Headset profile proxy.");
        if(!bluetoothAdapter.getProfileProxy(mCachedWebView.getContext(), serviceListener, BluetoothProfile.HEADSET)) {
            Log.e(LOG_TAG, "Failed to get HEADSET profile.");
        }

        IntentFilter intentFilter = new IntentFilter();
        intentFilter.addAction(AudioManager.ACTION_HEADSET_PLUG);
        intentFilter.addAction(AudioManager.ACTION_SCO_AUDIO_STATE_UPDATED);
        //intentFilter.addAction(AudioManager.ACTION_SCO_AUDIO_STATE_CHANGED);
        intentFilter.addAction(BluetoothDevice.ACTION_ACL_CONNECTED);
        //intentFilter.addAction(BluetoothDevice.ACTION_ACL_DISCONNECT_REQUESTED);
        intentFilter.addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED);
        intentFilter.addAction(BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED);

        /*
        intentFilter.addAction(Intent.ACTION_VOICE_COMMAND);
        intentFilter.addAction(RecognizerIntent.ACTION_VOICE_SEARCH_HANDS_FREE);
        intentFilter.addAction(Intent.ACTION_CALL_BUTTON);
        intentFilter.addAction(Intent.ACTION_MEDIA_BUTTON);
        intentFilter.addCategory(Intent.CATEGORY_DEFAULT);
*/

        this.receiver = new BroadcastReceiver() {
            private static final String LOG_TAG = "HeadsetDetectReceiver";

            @Override
            public void onReceive(Context context, Intent intent) {
                int state;

                Log.d(LOG_TAG, "action: " + intent.getAction());
                if (intent.getAction().equals(AudioManager.ACTION_HEADSET_PLUG)) {
                    state = intent.getIntExtra("state", -1);
                    switch (state) {
                        case 0:
                            Log.d(LOG_TAG, "Wired headset is unplugged");
                            fireConnectEvent("disconnect", "wired");
                            break;
                        case 1:
                            Log.d(LOG_TAG, "Wired headset is plugged");
                            fireConnectEvent("connect", "wired");
                            break;
                        default:
                            Log.d(LOG_TAG, "I have no idea what the headset state is");
                    }
                } else if (intent.getAction().equals(AudioManager.ACTION_SCO_AUDIO_STATE_UPDATED)) {
                    state = intent.getIntExtra(AudioManager.EXTRA_SCO_AUDIO_STATE, -1);
                    Log.d(LOG_TAG, "state: " + state);
                    switch (state) {
                        case AudioManager.SCO_AUDIO_STATE_DISCONNECTED:
                            Log.d(LOG_TAG, "SCO headset is disconnected");
                            fireConnectEvent("disconnect", "bluetooth", "sco");
                            break;
                        case AudioManager.SCO_AUDIO_STATE_CONNECTED:
                            Log.d(LOG_TAG, "SCO headset is connected");
                            fireConnectEvent("connect", "bluetooth", "sco");
                            break;
                        case AudioManager.SCO_AUDIO_STATE_CONNECTING:
                            Log.d(LOG_TAG, "SCO headset is connecting");
                            fireConnectEvent("connecting", "bluetooth", "sco");
                            break;
                        default:
                            Log.d(LOG_TAG, "I have no idea what the SCO headset state is");
                    }
                } else if (intent.getAction().equals(AudioManager.ACTION_SCO_AUDIO_STATE_CHANGED)) {
                    state = intent.getIntExtra(AudioManager.EXTRA_SCO_AUDIO_STATE, -1);
                    Log.d(LOG_TAG, "state: " + state);
                    switch (state) {
                        case AudioManager.SCO_AUDIO_STATE_DISCONNECTED:
                            Log.d(LOG_TAG, "SCO headset is disconnected");
                            fireConnectEvent("disconnect", "bluetooth", "sco");
                            break;
                        case AudioManager.SCO_AUDIO_STATE_CONNECTED:
                            Log.d(LOG_TAG, "SCO headset is connected");
                            fireConnectEvent("connect", "bluetooth", "sco");
                            break;
                        default:
                            Log.d(LOG_TAG, "I have no idea what the SCO headset state is");
                    }
                } else if (intent.getAction().equals(BluetoothDevice.ACTION_ACL_CONNECTED)) {
                    BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                    Log.d(LOG_TAG, "connect from device: " + device.getName());
                    fireConnectEvent("connect", "bluetooth", "acl");

                    if(!scoStarted) {
                        Log.d(LOG_TAG, "setMode(AudioManager.MODE_IN_COMMUNICATION)");
                        audioManager.setMode(AudioManager.MODE_IN_COMMUNICATION);
                        Log.d(LOG_TAG, "setBluetoothScoOn(true)");
                        audioManager.setBluetoothScoOn(true);
                        //Log.d(LOG_TAG, "startBluetoothSco()");
                        //audioManager.startBluetoothSco();
                        //Log.d(LOG_TAG, "startBluetoothSco() done");
                        scoStarted = true;
                    }

                    if(false && bluetoothHeadset != null) {
                        Log.d(LOG_TAG, "startVoiceRecognition()");
                        bluetoothHeadset.startVoiceRecognition(device);
                    }
                } else if (intent.getAction().equals(BluetoothDevice.ACTION_ACL_DISCONNECTED)) {
                    BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                    Log.d(LOG_TAG, "disconnect from device: " + device.getName());
                    fireConnectEvent("disconnect", "bluetooth", "acl");

                    if(false && bluetoothHeadset != null) {
                        Log.d(LOG_TAG, "stopVoiceRecognition()");
                        bluetoothHeadset.stopVoiceRecognition(device);
                    }

                    if(scoStarted) {
                        audioManager.setMode(AudioManager.MODE_NORMAL);
                        audioManager.setBluetoothScoOn(false);
                        audioManager.stopBluetoothSco();
                        scoStarted = false;
                        Log.d(LOG_TAG, "stopBluetoothSco()");
                    }
                } else if (intent.getAction().equals(BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED)) {
                    BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                    Log.d(LOG_TAG, "headset connect change from device: " + device.getName());
                    state = intent.getIntExtra(BluetoothHeadset.EXTRA_STATE, -1);
                    switch (state) {
                        case BluetoothHeadset.STATE_DISCONNECTED:
                            Log.d(LOG_TAG, "BT headset is disconnected");
                            fireConnectEvent("disconnect", "bluetooth");
                            break;
                        case BluetoothHeadset.STATE_DISCONNECTING:
                            Log.d(LOG_TAG, "BT headset is disconnecting");
                            fireConnectEvent("disconnecting", "bluetooth");
                            break;
                        case BluetoothHeadset.STATE_CONNECTING:
                            Log.d(LOG_TAG, "BT headset is connecting");
                            fireConnectEvent("connecting", "bluetooth");
                            break;
                        case BluetoothHeadset.STATE_CONNECTED:
                            Log.d(LOG_TAG, "BT headset is connected");
                            fireConnectEvent("connect", "bluetooth");
                            Log.d(LOG_TAG, "startBluetoothSco()");
                            audioManager.startBluetoothSco();
                            Log.d(LOG_TAG, "startBluetoothSco() done");
                            break;
                        default:
                            Log.d(LOG_TAG, "I have no idea what the BT headset state is");
                    }
                } else if (intent.getAction().equals(Intent.ACTION_VOICE_COMMAND)) {
                    Log.d(LOG_TAG, "Voice Command");
                }
            }
        };

        Log.d(LOG_TAG, "initialize() adding BroadcastReceiver");
        mCachedWebView.getContext().registerReceiver(this.receiver, intentFilter);
        audioManager.setBluetoothScoOn(true);
    }

    @Override
    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        try {
            if (ACTION_DETECT.equals(action)) {
                callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, isHeadsetEnabled()));
                return true;
            } else if (ACTION_INIT.equals(action)) {
                // Keep the init callback context to allow events to be sent.
                initCallbackContext = callbackContext;

                PluginResult pluginResult = new PluginResult(PluginResult.Status.OK);
                // Keep the callback around for later use.
                pluginResult.setKeepCallback(true);
                callbackContext.sendPluginResult(pluginResult);

                return true;
            } else {
                callbackContext.error(action + " is not a supported function. Did you mean '" + ACTION_DETECT + "'?");
                return false;
            }
        } catch (Exception e) {
            callbackContext.error(e.getMessage());
            return false;
        }
    }

    private boolean isHeadsetEnabled() {
        boolean headset = false;

        AudioDeviceInfo devices[] = audioManager.getDevices(AudioManager.GET_DEVICES_ALL);
        Log.d(LOG_TAG, "Num devices: " + devices.length);
        for(int i = 0; i < devices.length; i++) {
            Log.d(LOG_TAG, " product name: " + devices[i].getProductName() + (devices[i].isSource() ? " (Source)" : " (Sink)"));
            switch(devices[i].getType()) {
                case AudioDeviceInfo.TYPE_BLUETOOTH_SCO:
                    Log.d(LOG_TAG, "         type: SCO");
                    headset = true;
                    break;

                case AudioDeviceInfo.TYPE_BLUETOOTH_A2DP:
                    Log.d(LOG_TAG, "         type: A2DP");
                    headset = true;
                    break;

                case AudioDeviceInfo.TYPE_BUILTIN_EARPIECE:
                    Log.d(LOG_TAG, "         type: Builtin ear-piece");
                    break;

                case AudioDeviceInfo.TYPE_BUILTIN_SPEAKER:
                    Log.d(LOG_TAG, "         type: Builtin speaker");
                    break;

                case AudioDeviceInfo.TYPE_BUILTIN_MIC:
                    Log.d(LOG_TAG, "         type: Builtin MIC");
                    break;

                case AudioDeviceInfo.TYPE_TELEPHONY:
                    Log.d(LOG_TAG, "         type: Telephony");
                    break;

                case AudioDeviceInfo.TYPE_WIRED_HEADSET:
                    Log.d(LOG_TAG, "         type: Wired Headset");
                    headset = true;
                    break;

                case AudioDeviceInfo.TYPE_WIRED_HEADPHONES:
                    Log.d(LOG_TAG, "         type: Wired Headphones");
                    break;

                default:
                    Log.d(LOG_TAG, "         type: " + devices[i].getType());
                    break;
            }
        }

    return headset;
    }

    public void onDestroy() {
        removeHeadsetListener();
    }

    public void onReset() {
        removeHeadsetListener();
    }

    public void onNewIntent(Intent intent) {
        Log.d(LOG_TAG, "action: " + intent.getAction());
    }

    private void removeHeadsetListener() {
        Log.d(LOG_TAG, "removeHeadsetListener");
        if(scoStarted) {
            audioManager.stopBluetoothSco();
            scoStarted = false;
            Log.d(LOG_TAG, "stopBluetoothSco()");
        }
        audioManager.setBluetoothScoOn(false);
        if (this.receiver != null) {
            try {
                mCachedWebView.getContext().unregisterReceiver(this.receiver);
                this.receiver = null;
            } catch (Exception e) {
                Log.e(LOG_TAG, "Error unregistering battery receiver: " + e.getMessage(), e);
            }
        }

        if(this.serviceListener != null && this.bluetoothHeadset != null) {
            bluetoothAdapter.closeProfileProxy(BluetoothProfile.HEADSET, this.bluetoothHeadset);
            this.bluetoothHeadset = null;
        }
    }

    private void fireConnectEvent(String type, String deviceType, String subType) {
        Log.d(LOG_TAG, "fire event: " + type + " - " + deviceType);

        JSONObject event = new JSONObject();
        try {
            event.put("type", type);
            event.put("device", deviceType);

            if(subType != null) {
                event.put("subType", subType);
            }
        } catch (JSONException e) {
            // this will never happen
        }
        PluginResult pr = new PluginResult(PluginResult.Status.OK, event);
        pr.setKeepCallback(true);
        this.initCallbackContext.sendPluginResult(pr); 
    }

    private void fireConnectEvent(String type, String deviceType) {
        fireConnectEvent(type, deviceType, null);
    }
}
