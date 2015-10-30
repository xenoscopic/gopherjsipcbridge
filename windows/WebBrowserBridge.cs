using System;
using System.Security.Permissions;
using System.Windows.Forms;

namespace GopherJSIPCBridge
{
    [PermissionSet(SecurityAction.Demand, Name = "FullTrust")]
    [System.Runtime.InteropServices.ComVisible(true)]
    public class WebBrowserBridge
    {
        // The connection manager
        private IPCConnectionManager _connectionManager;

        // The underlying web browser
        private WebBrowser _browser;

        // Constructor
        public WebBrowserBridge(
            WebBrowser browser,
            string initializationMessage
        )
        {
            // Create connection manager
            _connectionManager = new IPCConnectionManager();

            // Store the browser
            _browser = browser;

            // Set ourselves as the object for scripting
            _browser.ObjectForScripting = this;

            // Create the bridge
            _browser.Document.InvokeScript(
                "_GIBWebBrowserBridgeInitialize",
                new object[] { initializationMessage }
            );
        }

        public delegate void invokeScriptDelegate(
            string name,
            object[] arguments
        );

        private void invokeScript(string name, object[] arguments)
        {
            _browser.Document.InvokeScript(name, arguments);
        }

        private void invokeOnMainThread(string name, object[] arguments)
        {
            _browser.Invoke(
                new invokeScriptDelegate(invokeScript),
                new object[] { name, arguments }
            );
        }

        // Method for asynchronously connecting
        public void Connect(string endpoint, int sequence)
        {
            // Forward the request to the connection manager with an appropriate
            // continuation
            _connectionManager.ConnectAsync(endpoint).ContinueWith(
                (task) =>
                {
                    // Extract the result
                    var result = task.Result;

                    // Do the response invocation on the main thread
                    invokeOnMainThread(
                        "_GIBWebBrowserBridgeRespondConnect",
                        new object[] { sequence, result.Item1, result.Item2 }
                    );
                }
            );
        }

        // Method for asynchronously reading from a connection
        public void ConnectionRead(int connectionId, int length, int sequence)
        {
            // Create a read buffer
            byte[] buffer = new byte[length];

            // Forward the request to the connection manager with an appropriate
            // continuation
            _connectionManager.ConnectionReadAsync(
                connectionId,
                buffer
            ).ContinueWith(
                (task) =>
                {
                    // Extract the result
                    var result = task.Result;

                    // Base64-encode the data
                    string data64 = Convert.ToBase64String(
                        buffer,
                        0,
                        result.Item1
                    );

                    // Do the response invocation on the main thread
                    invokeOnMainThread(
                        "_GIBWebBrowserBridgeRespondConnectionRead",
                        new object[] { sequence, data64, result.Item2 }
                    );
                }
            );
        }

        // Method for asynchronously writing to a connection
        public void ConnectionWrite(
            int connectionId,
            string data64,
            int sequence
        )
        {
            // Decode the data
            byte[] buffer = Convert.FromBase64String(data64);

            // Forward the request to the connection manager with an appropriate
            // continuation
            _connectionManager.ConnectionWriteAsync(
                connectionId,
                buffer
            ).ContinueWith(
                (task) =>
                {
                    // Extract the result
                    var result = task.Result;

                    // Do the response invocation on the main thread
                    invokeOnMainThread(
                        "_GIBWebBrowserBridgeRespondConnectionWrite",
                        new object[] { sequence, result.Item1, result.Item2 }
                    );
                }
            );
        }

        // Method for closing a connection
        public void ConnectionClose(int connectionId, int sequence)
        {
            // Use the connection manager to close the request and then forward
            // the result back across the bridge.  We don't need to use the
            // invoke machinery since we're already on the main thread, but we
            // use the method to keep code uniform.
            invokeOnMainThread(
                "_GIBWebBrowserBridgeRespondConnectionClose",
                new object[] {
                    sequence,
                    _connectionManager.ConnectionClose(connectionId)
                }
            );
        }

        // Method for starting a listener
        public void Listen(string endpoint, int sequence)
        {
            // Use the connection manager to listen and then forward the result
            // back across the bridge.  We don't need to use the invoke
            // machinery since we're already on the main thread, but we use the
            // method to keep code uniform.
            Tuple<Int32, string> result = _connectionManager.Listen(endpoint);
            invokeOnMainThread(
                "_GIBWebBrowserBridgeRespondListen",
                new object[] {
                    sequence,
                    result.Item1,
                    result.Item2
                }
            );
        }

        // Method for asynchronously accepting from a listener
        public void ListenerAccept(int listenerId, int sequence)
        {
            // Forward the request to the connection manager with an appropriate
            // continuation
            _connectionManager.ListenerAcceptAsync(listenerId).ContinueWith(
                (task) =>
                {
                    // Extract the result
                    var result = task.Result;

                    // Do the response invocation on the main thread
                    invokeOnMainThread(
                        "_GIBWebBrowserBridgeRespondListenerAccept",
                        new object[] { sequence, result.Item1, result.Item2 }
                    );
                }
            );
        }

        // Method for asynchronously closing a listener
        public void ListenerClose(int listenerId, int sequence)
        {
            // Use the connection manager to close the listener and then forward
            // the result back across the bridge.  We don't need to use the
            // invoke machinery since we're already on the main thread, but we
            // use the method to keep code uniform.
            invokeOnMainThread(
                "_GIBWebBrowserBridgeRespondListenerClose",
                new object[] {
                    sequence,
                    _connectionManager.ConnectionClose(listenerId)
                }
            );
        }
    }
}
