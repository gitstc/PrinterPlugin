//
//  ViewController.h
//  Bixolon
//
//  Created by Shnoudi on 6/30/14.
//  Copyright (c) 2014 The Solutions Unit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Cordova/CDVPlugin.h"
#import "BXPrinterController.h"

@interface PrinterPlugin : CDVPlugin <BXPrinterControlDelegate>

@property (nonatomic,strong) BXPrinterController *printerController;
@property (nonatomic,strong) BXPrinter *print_printer;
@property (nonatomic,strong) NSString *PGCallback;
@property (nonatomic,strong) NSString *print_printCB;
@property (nonatomic,strong) NSString *_testCB;

- (void)connectToPrinter:(CDVInvokedUrlCommand*)command;
- (void)disconnectPrinter:(CDVInvokedUrlCommand*)command;
- (void)printImage:(CDVInvokedUrlCommand*)command;
- (void)printPDF:(CDVInvokedUrlCommand*)command;
- (void)test:(CDVInvokedUrlCommand*)command;

@end