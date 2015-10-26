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

// Interface properties
@property (weak) IBOutlet NSWindow *window;

// WebView example properties
@property (strong) IBOutlet WebView *webView;
@property (strong, nonatomic) GIBWebViewBridge *webViewBridge;
@property (strong, nonatomic) NSTask *webViewGoTask;

// WebView example methods
- (IBAction)startWebViewExample:(id)sender;

// WKWebView example properties
@property (strong) IBOutlet NSView *wkWebViewContainer;
@property (strong, nonatomic) WKWebView *wkWebView;
@property (strong, nonatomic) GIBWKWebViewBridge *wkWebViewBridge;
@property (strong, nonatomic) NSTask *wkWebViewGoTask;

// WKWebView example methods
- (IBAction)startWKWebViewExample:(id)sender;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // TODO: Show teardown
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
    // Get a temporary directory in which we can create sockets
    NSString *socketPath =
        [NSTemporaryDirectory() stringByAppendingPathComponent:@"wv.sock"];

    // Compute the path to the server task
    NSString *serverPath = [[NSBundle mainBundle] pathForResource:@"server"
                                                           ofType:nil];

    // Start the Go server that we'll communicate with
    self.webViewGoTask = [NSTask launchedTaskWithLaunchPath:serverPath
                                                  arguments:@[socketPath]];

    // Create the bridge
    self.webViewBridge =
        [[GIBWebViewBridge alloc] initWithWebView:self.webView];

    // HACK: Wait for the server to start up and start listening on the socket
    // path.  In a real application, you'd want to do something a bit more
    // robust, like have the server signal the application.
    // TODO: Fix this
    [NSThread sleepForTimeInterval:1.0];

    // Send the socket path for communication
    [self.webViewBridge sendMessage:socketPath];
}

- (IBAction)startWKWebViewExample:(id)sender {
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
    // Get a temporary directory in which we can create sockets
    NSString *socketPath =
        [NSTemporaryDirectory() stringByAppendingPathComponent:@"wkwv.sock"];

    // Compute the path to the server task
    NSString *serverPath = [[NSBundle mainBundle] pathForResource:@"server"
                                                           ofType:nil];

    // Start the Go server that we'll communicate with
    self.webViewGoTask = [NSTask launchedTaskWithLaunchPath:serverPath
                                                  arguments:@[socketPath]];

    // Create the bridge
    self.wkWebViewBridge =
        [[GIBWKWebViewBridge alloc] initWithWKWebView:self.wkWebView];

    // HACK: Wait for the server to start up and start listening on the socket
    // path.  In a real application, you'd want to do something a bit more
    // robust, like have the server signal the application.
    // TODO: Fix this
    [NSThread sleepForTimeInterval:1.0];

    // Send the socket path for communication
    [self.wkWebViewBridge sendMessage:socketPath];
}

@end
