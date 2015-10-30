//
//  AppDelegate.m
//  GopherJSIPCBridgeDemo
//
//  Created by Jacob Howard on 10/21/15.
//  Copyright © 2015 Jacob Howard. All rights reserved.
//

#import "AppDelegate.h"

// GopherJSIPCBridge imports
#import "GIBWKWebViewBridge.h"
#import "GIBWebViewBridge.h"


@interface AppDelegate ()

// Common properties
@property (weak) IBOutlet NSWindow *window;

// Common methods
- (NSTask *)startServerTask:(NSString *)socketPath;

// WebView example properties
@property (strong) IBOutlet WebView *webView;
@property (strong, nonatomic) GIBWebViewBridge *webViewBridge;
@property (strong, nonatomic) NSTask *webViewGoServer;

// WebView example methods
- (IBAction)startWebViewExample:(id)sender;

// WKWebView example properties
@property (strong) IBOutlet NSView *wkWebViewContainer;
@property (strong, nonatomic) WKWebView *wkWebView;
@property (strong, nonatomic) GIBWKWebViewBridge *wkWebViewBridge;
@property (strong, nonatomic) NSTask *wkWebViewGoServer;

// WKWebView example methods
- (IBAction)startWKWebViewExample:(id)sender;

// Raw Go example properties
@property (strong) IBOutlet NSTextView *rawGoClientOutput;
@property (strong, nonatomic) NSTask *rawGoClient;
@property (strong, nonatomic) NSTask *rawGoServer;

// Raw go example methods
- (IBAction)startRawGoExample:(id)sender;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    
}

- (NSTask *)startServerTask:(NSString *)socketPath {
    // Create the task
    NSTask *result = [[NSTask alloc] init];

    // Set the target
    result.launchPath = [[NSBundle mainBundle] pathForResource:@"server"
                                                        ofType:nil];

    // Set arguments
    result.arguments = @[socketPath];

    // Redirect stderr so we can monitor for initialization
    NSPipe *standardError = [NSPipe pipe];
    result.standardError = standardError;

    // Start the task
    [result launch];

    // Wait for it to print to stderr, indicating that it is ready
    [standardError.fileHandleForReading availableData];

    // Close our end of stderr, we don't care
    [standardError.fileHandleForReading closeFile];

    // All done
    return result;
}

- (IBAction)startWebViewExample:(id)sender {
    // Set ourselves as the frame load delegate
    self.webView.frameLoadDelegate = self;

    // Compute the path to the client
    NSURL *uiURL = [[NSBundle mainBundle] URLForResource:@"client"
                                           withExtension:@"html"];

    // Load the client
    [self.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:uiURL]];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    // TODO: Add shutdown of previous run

    // Compute the IPC socket path
    NSString *socketPath =
        [NSTemporaryDirectory() stringByAppendingPathComponent:@"wv.sock"];

    // Start the Go server that we'll communicate with
    self.webViewGoServer = [self startServerTask:socketPath];

    // Create the bridge
    self.webViewBridge = [[GIBWebViewBridge alloc] initWithWebView:self.webView
                                             initializationMessage:socketPath];
}

- (IBAction)startWKWebViewExample:(id)sender {
    // TODO: Add shutdown of previous run

    // Create the WKWebView (has to be done in code, can't be done with NIB)
    NSRect frame = self.wkWebViewContainer.frame;
    frame.origin = NSMakePoint(0, 0);
    self.wkWebView = [[WKWebView alloc] initWithFrame:frame];

    // Add the WKWebView to the interface
    [self.wkWebViewContainer addSubview:self.wkWebView];

    // Set ourselves as the navigation delegate
    self.wkWebView.navigationDelegate = self;

    // Compute the path to the client
    NSURL *uiURL = [[NSBundle mainBundle] URLForResource:@"client"
                                           withExtension:@"html"];

    // Load the client
    [self.wkWebView loadRequest:[NSURLRequest requestWithURL:uiURL]];
}

- (void)webView:(WKWebView *)webView
didFinishNavigation:(WKNavigation *)navigation {
    // Compute the IPC socket path
    NSString *socketPath =
        [NSTemporaryDirectory() stringByAppendingPathComponent:@"wkwv.sock"];

    // Start the Go server that we'll communicate with
    self.webViewGoServer = [self startServerTask:socketPath];

    // Create the bridge
    self.wkWebViewBridge =
        [[GIBWKWebViewBridge alloc] initWithWKWebView:self.wkWebView
                                initializationMessage:socketPath];
}

- (IBAction)startRawGoExample:(id)sender {
    // TODO: Add shutdown of previous run

    // Compute the IPC socket path
    NSString *socketPath =
        [NSTemporaryDirectory() stringByAppendingPathComponent:@"go.sock"];

    // Start the Go server that we'll communicate with
    self.rawGoServer = [self startServerTask:socketPath];

    // Compute the path to the server task
    NSString *clientPath = [[NSBundle mainBundle] pathForResource:@"client"
                                                           ofType:nil];

    // Start the Go client.  We'll redirect it's output to the UI.
    self.rawGoClient = [[NSTask alloc] init];
    self.rawGoClient.launchPath = clientPath;
    self.rawGoClient.arguments = @[socketPath];
    NSPipe *outputPipe = [NSPipe pipe];
    self.rawGoClient.standardOutput = outputPipe;
    outputPipe.fileHandleForReading.readabilityHandler =
        ^(NSFileHandle *handle) {
            NSString *output =
                [[NSString alloc] initWithData:[handle availableData]
                                      encoding:NSUTF8StringEncoding];
            NSAttributedString* attributedOutput =
                [[NSAttributedString alloc] initWithString:output];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self.rawGoClientOutput textStorage]
                 appendAttributedString:attributedOutput];
            });
        };
    self.rawGoClient.terminationHandler = ^(NSTask *task) {
        // Close the output file handle - if you don't the CPU goes nuts!  Of
        // course, it shouldn't, it should just leak a file descriptor, but
        // Cocoa is tempermental, and starts firing on kqueue events like
        // there's no tomorrow:
        // http://stackoverflow.com/a/13748843
        [outputPipe.fileHandleForReading closeFile];
    };
    [self.rawGoClient launch];
}

@end
