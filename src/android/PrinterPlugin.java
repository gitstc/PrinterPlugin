package com.tsu.PrinterPlugin;

import android.bluetooth.BluetoothDevice;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.Base64;
import android.util.Log;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;

import com.bixolon.printer.BixolonPrinter;

import java.lang.Exception;
import java.lang.Override;
import java.util.Set;

public class PrinterPlugin extends CordovaPlugin
{
    private BixolonPrinter bxPrinter = null;
    private CallbackContext cb;

    private boolean initialized = false;
    private boolean connected = false;
    private String printerAddress = "";

    private static Context context;
    private static CordovaWebView cWebView;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        context = this.cordova.getActivity().getApplicationContext();

        cWebView = this.webView;

        Log.d("PrinterPlugin","Action: " + action);

        if(action.equals("initializePrinter")) {
            cb = callbackContext;
            initPrinter();
        }
        else if(action.equals("connectToPrinter")) {
            Log.d("PrinterPlugin","Connecting to printer!");
            cb = callbackContext;
            if(!initialized) {
                initPrinter();
            }
            else {
                if(!connected) {
                    connectToPrinter();
                }
                else {
                    cWebView.sendJavascript("javascript:PrinterPlugin.printerConnected('')");
                }
            }
        }
        else if(action.equals("printImage")) {
            Log.d("PrinterPlugin","Printing Image: " + args.getJSONObject(0).getString("content"));
            cb = callbackContext;
            String img = args.getJSONObject(0).getString("content");
            printImage(img);
        }
        else if(action.equals("printString")) {
            Log.d("PrinterPlugin","Printing String: " + args.getString(0));
            cb = callbackContext;
            printString(args.getString(0));
        }

        return true;
    }

    private Handler mHander = new Handler(new Handler.Callback() {
        @Override
        public boolean handleMessage(Message msg) {
            switch(msg.what) {
                case BixolonPrinter.MESSAGE_BLUETOOTH_DEVICE_SET:
                    Log.d("PrinterPlugin","Bluetooth Device Set");
                    if(msg.obj != null) {
                        Set<BluetoothDevice> bluetoothDeviceSet = (Set<BluetoothDevice>) msg.obj;
                        for(BluetoothDevice device : bluetoothDeviceSet)
                            if (device.getName().equals("SPP-R300")) {
                                printerAddress = device.getAddress();
                                connectToPrinter();
                                return true;
                            }
                    }
                    else {
                        cWebView.sendJavascript("javascript:PrinterPlugin.printerNotConnected('')");
                        //cb.error("No Paired Devices Found!");
                        return true;
                    }
                    return true;
                case BixolonPrinter.MESSAGE_STATE_CHANGE:
                    switch (msg.arg1) {
                        case BixolonPrinter.STATE_CONNECTING:
                            Log.d("PrinterPlugin","Connecting");
                            initialized = true;
                            connected = false;
                            break;
                        case BixolonPrinter.STATE_CONNECTED:
                            Log.d("PrinterPlugin","Connected");
                            initialized = true;
                            connected = true;

                            cWebView.sendJavascript("javascript:PrinterPlugin.printerConnected('')");
                            break;
                        case BixolonPrinter.STATE_NONE:
                            Log.d("PrinterPlugin","Disconnected");
                            connected = false;
                            break;
                    }
                    break;
                case BixolonPrinter.MESSAGE_PRINT_COMPLETE:
                    Log.d("PrinterPlugin","Print Complete");
                    bxPrinter.disconnect();
                    initialized = false;
                    connected = false;
                    
                    cb.success("Print Complete");
                    return true;
                case BixolonPrinter.MESSAGE_ERROR_INVALID_ARGUMENT:
                    Log.d("PrinterPlugin","Invalid Argument");

                    cb.error("Invalid Argument");
                    return true;
            }

            return true;
        }
    });

    private void initPrinter(){
        Log.d("PrinterPlugin","Initializing Printer");
        try {
            if(bxPrinter == null) {
                bxPrinter = new BixolonPrinter(context, mHander, null);
            }
            bxPrinter.findBluetoothPrinters();
        }
        catch(Exception ex) {
            cb.error(ex.getMessage());
        }
    }

    private void connectToPrinter(){
        Log.d("PrinterPlugin","Connecting to Printer");
        try {
            bxPrinter.connect(printerAddress);
        }
        catch(Exception ex) {
            cb.error(ex.getMessage());
        }
    }

    private void printImage(String base64Image){
        Log.d("PrinterPlugin","Image: " + base64Image);
        byte[] decodedString = Base64.decode(base64Image, Base64.DEFAULT);
        Bitmap decodedByte = BitmapFactory.decodeByteArray(decodedString, 0, decodedString.length);

        bxPrinter.printBitmap(decodedByte,BixolonPrinter.ALIGNMENT_CENTER,BixolonPrinter.BITMAP_WIDTH_FULL,BixolonPrinter.QR_CODE_ERROR_CORRECTION_LEVEL_H,true);
        bxPrinter.lineFeed(2, false);
    }

    private void printString(String str){
        Log.d("PrinterPlugin","String: " + str);
        if(containsArabic(str)) {
            bxPrinter.setSingleByteFont(BixolonPrinter.CODE_PAGE_1256_ARABIC);
        }
        else {
            bxPrinter.setSingleByteFont(BixolonPrinter.CODE_PAGE_437_USA);
        }
        bxPrinter.printText(str, BixolonPrinter.ALIGNMENT_CENTER, BixolonPrinter.TEXT_ATTRIBUTE_FONT_A, BixolonPrinter.TEXT_SIZE_VERTICAL1, true);
        bxPrinter.lineFeed(1,false);
    }

    private static boolean containsArabic(String s) {
        for (int i = 0; i < s.length();) {
            int c = s.codePointAt(i);
            if (c >= 0x0600 && c <=0x06E0)
                return true;
            i += Character.charCount(c);
        }
        return false;
    }
}