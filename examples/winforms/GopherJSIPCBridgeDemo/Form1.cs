using System;
using System.Windows.Forms;
using System.Reflection;
using System.IO;
using System.Diagnostics;

using GopherJSIPCBridge;

namespace GopherJSIPCBridgeDemo
{
    public partial class Form1 : Form
    {
        // WebBrowser example properties
        private WebBrowserBridge _webBrowserBridge;
        private Process _webBrowserServerProcess;

        public Form1()
        {
            InitializeComponent();
        }

        private string pathToResource(string name)
        {
            // Compute executable directory
            string executableDirectory = Path.GetDirectoryName(
                Assembly.GetEntryAssembly().Location
            );

            // Add the resource name
            return Path.Combine(executableDirectory, name);
        }

        private void webBrowserRunButton_Click(object sender, EventArgs e)
        {
            // TODO: Add shutdown of previous run

            // Compute the path to the demo web page
            Uri demoURL = new Uri(pathToResource("client.html"));

            // Start loading the demo web page
            webBrowser.Url = demoURL;
        }

        private void webBrowser_DocumentCompleted(
            object sender,
            WebBrowserDocumentCompletedEventArgs e
        )
        {
            // Compute the IPC path
            string pipeName = "\\\\.\\pipe\\gibdemo";

            // Compute the path to the Go server executable
            string serverPath = pathToResource("server.exe");

            // Start the Go server that we'll communicate with
            var serverStartInfo = new ProcessStartInfo(serverPath, pipeName);
            serverStartInfo.UseShellExecute = false;
            serverStartInfo.CreateNoWindow = true;
            serverStartInfo.RedirectStandardError = true;
            _webBrowserServerProcess = Process.Start(serverStartInfo);

            // Wait for the server to start (it will print a line to stderr)
            _webBrowserServerProcess.StandardError.ReadLine();

            // Create the bridge
            _webBrowserBridge = new WebBrowserBridge(webBrowser, pipeName);
        }
    }
}
