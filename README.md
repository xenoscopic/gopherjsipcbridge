# GopherJSIPCBridge

A framework to allow GopherJS code (or really any JavaScript-based language)
running in various JavaScript contexts to create and accept IPC connections
(Unix domain sockets and Windows named pipes).

The purpose of this project is to allow for the creation of mobile or desktop
applications using web technologies for their user interface with a more
powerful backend engine that might be shared across platforms.  Existing
solutions are either underpowered (Cordova et al.) or massive in size because
they distribute an entire Chromium browser (NW.js, Electron, et al.).  The
proliferation of high-performance web view components and all platforms,
combined with JavaScript bridge APIs, opens up exiting possibilities for more
nimble and high-performance applications.


## Status

The current implementation supports the following platforms/components:

- OS X
    - WebView
    - WKWebView
    - JSContext
- iOS
    - WKWebView
    - JSContext
- Windows
    - System.Windows.Forms.WebBrowser

In my benchmarking, roundtrip IPC time across the JavaScript -> host -> IPC
bridge is ~10 ms, which is plenty fast for long-running asynchronous operations
or fast synchronous operations.  There's a lot of efficiency lost vs pure Go
IPC, but there's probably still some low hanging optimization to be done on the
GopherJS side of the bridge.  JavaScript is just *such* a terrible language.

Current development entails polishing and optimizing the GopherJS side of
things.  I may also remove the GopherJS dependency entirely, although this is
not a priority because the size penalty is not huge for desktop or mobile and
Go is *so* much better to write in than JavaScript.

If Go's shared or static library support picks up on all platforms, I may also
just write a unified host IPC bridge interface (currently the POSIX one is
written in C++ and the Windows one is written in C#).

I'm also happy to accept contributions for Android or Linux support, or other
Windows web view components.  WinRT in particular would be nice, though the
sandboxing restrictions may put the whammy on any IPC.


## Building

You'll first need to clone the library into your `GOPATH`.  Probably best to do
this manually, because the POSIX IPC implementation uses
[asio](http://think-async.com/), including it as a Git submodule that you'll
need to init/update.

If you check out the code to your `GOPATH`, you should be able to build and run
the demo applications for OS X and Windows present in the "examples" directory.
These examples also show how to use the library.  The API is in now way stable
and will almost certainly change as time goes on.
