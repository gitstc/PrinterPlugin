//
//  ViewController.m
//  Bixolon
//
//  Created by Shnoudi on 6/30/14.
//  Copyright (c) 2014 The Solutions Unit. All rights reserved.
//

#import "PrinterPlugin.h"
#import <QuartzCore/QuartzCore.h>

@implementation PrinterPlugin

@synthesize printerController;
@synthesize print_printer;
@synthesize PGCallback;
@synthesize print_printCB;
@synthesize _testCB;

bool initialized = NO;
NSString *con_connectionCB = @"";

- (void)initializePrinter
{
    if(printerController == nil)
    {
        printerController                = [BXPrinterController getInstance];
    
        printerController.delegate       = self;
        printerController.lookupCount    = 5;
        printerController.AutoConnection = BXL_CONNECTIONMODE_NOAUTO;
    }
    [printerController open];
    [printerController lookup];
}

- (void)didLookupPrinters:(BXPrinterController *)controller
{
    NSLog(@"didLookupPrinters");
    @try{
        NSLog(@"con_connectionCB1 : %@",con_connectionCB);
    }
    @catch(NSException *ex){
        NSLog(@"EX1:");
        NSLog(@"EX: %@", ex.description);
    }
   // [printerController selectTarget];
    if(BXL_SUCCESS == [printerController selectTarget])
    {
        NSLog(@"Select Target Success");
        [printerController connect];
    }
    else
    {
        NSLog(@"Select Target Fail");
        CDVPluginResult *res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Could not connect to printer"];
        [self.commandDelegate sendPluginResult:res callbackId:con_connectionCB];      
    }
}

- (void)didNotLookup:(BXPrinterController *)controller withError:(NSError *) error
{
    NSLog(@"printer lookup fail.");
    initialized = NO;
}

- (void)didBeBrokenConnection:(BXPrinterController *)controller withError:(NSError *)error
{
    NSLog(@"printer didBeBrokenConnection.");
    initialized = NO;
}

- (void)didFindPrinter:(BXPrinterController *)controller
               printer:(BXPrinter *)printer
{
    NSLog(@"didFindPrinter");
    
    printerController.target = printer;
}

- (void)willConnect:(BXPrinterController *)controller printer:(BXPrinter *)printer
{
    NSLog(@"Connecting to printer: %@",printer.macAddress);
    initialized = NO;
}

- (void)didConnect:(BXPrinterController *)controller printer:(BXPrinter *)printer
{
    NSLog(@"con_connectionCB2 : %@",con_connectionCB);
    NSLog(@"didConnect");
    CDVPluginResult *res;
    NSLog(@"didConnect1");
    if([con_connectionCB isEqualToString:@""])
    {
        NSLog(@"didConnect error");
        res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Printer Error"];
        [self.commandDelegate sendPluginResult:res callbackId:con_connectionCB];
    }
    else{
         NSLog(@"didConnect success");
        res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Printer Connected"];
        [self.commandDelegate sendPluginResult:res callbackId:con_connectionCB];
    }
    NSLog(@"didConnect2");
    con_connectionCB = @"";
    initialized = YES;
}

- (void)didNotConnect:(BXPrinterController *)controller printer:(BXPrinter *)printer withError:(NSError *)error
{
    NSLog(@"Did Not Connect: %@",error);
    CDVPluginResult *res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Could not connect to printer"];
    [self.commandDelegate sendPluginResult:res callbackId:con_connectionCB];
    con_connectionCB = @"";
    initialized = NO;
}

- (void)didDisconnect:(BXPrinterController *)controller printer:(BXPrinter *)printer
{
    NSLog(@"didDisconnect");
    initialized = NO;
}


- (void)connectToPrinter:(CDVInvokedUrlCommand*)command {
    con_connectionCB = @"";
    con_connectionCB = [NSString stringWithFormat:@"%@",command.callbackId];
    /* NSLog(@"con_connectionCB connect pribnter: %@",con_connectionCB);*/
    if(initialized == NO)
    {
        [self initializePrinter];
    }
    else
    {
        CDVPluginResult *res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Printer Connected"];
        [self.commandDelegate sendPluginResult:res callbackId:con_connectionCB];
        con_connectionCB = @"";
    }
}

- (void)disconnectPrinter:(CDVInvokedUrlCommand *)command {
    con_connectionCB = command.callbackId;
    CDVPluginResult *res;
    @try{
        [printerController disconnect];
        res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Printer Disconnected"];
        [self.commandDelegate sendPluginResult:res callbackId:con_connectionCB];
        con_connectionCB = @"";
    }
    @catch(NSException *ex){
        res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[ex description]];
        [self.commandDelegate sendPluginResult:res callbackId:con_connectionCB];
        con_connectionCB = @"";
    }
}

- (void)printString:(CDVInvokedUrlCommand *)command {
    print_printCB = command.callbackId;
    
    CDVPluginResult *res;
    
    @try{
        long printResult = [printerController printText:[NSString stringWithFormat:@"%@",[command argumentAtIndex:0]]];
        
        NSLog(@"Print Result: %@",[NSString stringWithFormat:@"%ld",printResult]);
        
        if(printResult == BXL_SUCCESS){
            res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Printed Successfully!"];
            [self.commandDelegate sendPluginResult:res callbackId:print_printCB];
        }
        else{
            res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"%ld",printResult]];
            [self.commandDelegate sendPluginResult:res callbackId:print_printCB];
        }
        print_printCB = nil;
    }
    @catch(NSException *ex){
        res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"Print Error!\nError: %@",ex.description]];
        [self.commandDelegate sendPluginResult:res callbackId:print_printCB];
        print_printCB = nil;
    }
}

- (void)printImage:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *res;
    
    @try{
        NSString *VoucherCode = [[command.arguments objectAtIndex:0] objectForKey:@"voucherCode"];

        NSString *base64 = [[command.arguments objectAtIndex:0] objectForKey:@"content"];
        NSData *imageData = [self dataFromBase64EncodedString:base64];
        UIImage *image = [UIImage imageWithData:imageData];
        
        //save base 64 and image in case of voucher
       /* if (!([VoucherCode isEqualToString: @""]))
        {
            //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *path= [paths lastObject];

            path= [path stringByAppendingFormat:[NSString stringWithFormat:@"/%@.jpg",VoucherCode]];
            NSError *writeError = nil;

            [imageData writeToFile:path options:NSDataWritingAtomic error:&writeError];
            if(writeError != nil)
            {

            }
        }*/

        //int nLevel = [[[command.arguments objectAtIndex:0] objectForKey:@"resolution"] intValue];
        int nLevel = 50;
        
        long printResult = [printerController printBitmapWithImage:image width:BXL_WIDTH_NONE level:nLevel];
        
        if(printResult == BXL_SUCCESS){
            res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Print Success"];
        }
        else{
            res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Print Error"];
        }
        [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
    }
    @catch(NSException *ex){
        res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"Print Error!\nError: %@",ex.description]];
        [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
    }
    
}

-(NSData *)dataFromBase64EncodedString:(NSString *)string{
    if (string.length > 0) {
        //the iPhone has base 64 decoding built in but not obviously. The trick is to
        //create a data url that's base 64 encoded and ask an NSData to load it.
        NSString *data64URLString = string;
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:data64URLString]];
        return data;
    }
    return nil;
}


- (void)printPDF:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *res;
    
    NSLog(@"PDF");
    
    @try{
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Bixolon" ofType:@"pdf"];
        NSLog(@"path: %@",path);
        printerController.imageDitheringWithIgnoreWhite = YES;
        long printResult = 0;
        
        //Get number of pages
        NSURL *pdfURL = [NSURL fileURLWithPath:path];
        CGPDFDocumentRef document = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
        size_t pageCount = CGPDFDocumentGetNumberOfPages(document);
        NSLog(@"Pages : %ld", pageCount);
        
        for(int i=0; i<pageCount; i++){
            printResult = [printerController printPDF:path pageNumber:i width:-1 level:1050];
        }
        
        NSLog(@"printResult: %ld",printResult);
        if(printResult == BXL_SUCCESS){
            res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Print Success"];
        }
        else{
            res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"Print Error %ld", printResult]];
        }
        [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
    }
    @catch(NSException *ex){
        res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"Print Error!\nError: %@",ex.description]];
        [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
    }
    
}

- (void)test:(CDVInvokedUrlCommand*)command
{
    _testCB=command.callbackId;
    [self testabc];
}

- (void)testabc
{
   CDVPluginResult *res;
   res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"test Success"];
   [self.commandDelegate sendPluginResult:res callbackId:_testCB];
}

@end