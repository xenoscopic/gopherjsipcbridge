namespace GopherJSIPCBridgeDemo
{
    partial class Form1
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.webBrowser = new System.Windows.Forms.WebBrowser();
            this.webBrowserLabel = new System.Windows.Forms.Label();
            this.webBrowserRunButton = new System.Windows.Forms.Button();
            this.SuspendLayout();
            // 
            // webBrowser
            // 
            this.webBrowser.Location = new System.Drawing.Point(12, 38);
            this.webBrowser.MinimumSize = new System.Drawing.Size(20, 20);
            this.webBrowser.Name = "webBrowser";
            this.webBrowser.Size = new System.Drawing.Size(500, 375);
            this.webBrowser.TabIndex = 0;
            this.webBrowser.DocumentCompleted += new System.Windows.Forms.WebBrowserDocumentCompletedEventHandler(this.webBrowser_DocumentCompleted);
            // 
            // webBrowserLabel
            // 
            this.webBrowserLabel.AutoSize = true;
            this.webBrowserLabel.Location = new System.Drawing.Point(13, 13);
            this.webBrowserLabel.Name = "webBrowserLabel";
            this.webBrowserLabel.Size = new System.Drawing.Size(183, 13);
            this.webBrowserLabel.TabIndex = 1;
            this.webBrowserLabel.Text = "System.Windows.Forms.WebBrowser";
            // 
            // webBrowserRunButton
            // 
            this.webBrowserRunButton.Location = new System.Drawing.Point(202, 8);
            this.webBrowserRunButton.Name = "webBrowserRunButton";
            this.webBrowserRunButton.Size = new System.Drawing.Size(75, 23);
            this.webBrowserRunButton.TabIndex = 2;
            this.webBrowserRunButton.Text = "Run";
            this.webBrowserRunButton.UseVisualStyleBackColor = true;
            this.webBrowserRunButton.Click += new System.EventHandler(this.webBrowserRunButton_Click);
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(524, 425);
            this.Controls.Add(this.webBrowserRunButton);
            this.Controls.Add(this.webBrowserLabel);
            this.Controls.Add(this.webBrowser);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.MaximizeBox = false;
            this.Name = "Form1";
            this.Text = "GopherJS IPC Bridge Demo";
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.WebBrowser webBrowser;
        private System.Windows.Forms.Label webBrowserLabel;
        private System.Windows.Forms.Button webBrowserRunButton;
    }
}

