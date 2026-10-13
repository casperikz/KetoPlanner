using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Text;
using System.Threading;
using System.Windows.Forms;

namespace KetoPlannerDesktop
{
    static class Program
    {
        private const int DefaultPort = 38281;
        private static HttpListener _listener;
        private static string _baseDir;
        private static volatile bool _running = true;
        private static DateTime _lastHeartbeat = DateTime.UtcNow;
        private static bool _firstRequestReceived = false;

        [STAThread]
        static void Main()
        {
            try
            {
                _baseDir = AppDomain.CurrentDomain.BaseDirectory;
                string htmlPath = Path.Combine(_baseDir, "index.html");
                if (!File.Exists(htmlPath))
                {
                    if (File.Exists(Path.Combine(_baseDir, "resources", "index.html")))
                    {
                        _baseDir = Path.Combine(_baseDir, "resources");
                    }
                }

                int port = DefaultPort;
                _listener = new HttpListener();
                try
                {
                    _listener.Prefixes.Add(string.Format("http://127.0.0.1:{0}/", port));
                    _listener.Start();
                }
                catch
                {
                    // If default port is in use, pick a random high port
                    port = new Random().Next(40000, 55000);
                    _listener = new HttpListener();
                    _listener.Prefixes.Add(string.Format("http://127.0.0.1:{0}/", port));
                    _listener.Start();
                }

                Thread serverThread = new Thread(RunServer);
                serverThread.IsBackground = true;
                serverThread.Start();

                Thread watchdogThread = new Thread(RunWatchdog);
                watchdogThread.IsBackground = true;
                watchdogThread.Start();

                string browserExe = FindBrowser();
                if (string.IsNullOrEmpty(browserExe))
                {
                    MessageBox.Show("Could not locate Microsoft Edge or Google Chrome.\nPlease install Microsoft Edge to run Keto Planner.", "Keto Planner", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                string userDataDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "KetoPlanner", "UserData");
                Directory.CreateDirectory(userDataDir);

                // Note: --app URL must NOT have quotes around it so Chromium parses host and port correctly
                string targetUrl = string.Format("http://127.0.0.1:{0}/index.html", port);
                string args = string.Format("--app={0} --window-size=1280,860 --user-data-dir=\"{1}\" --no-first-run", targetUrl, userDataDir);

                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = browserExe;
                psi.Arguments = args;
                psi.UseShellExecute = false;

                Process p = Process.Start(psi);

                // Keep process alive while watchdog monitors heartbeat
                while (_running)
                {
                    Thread.Sleep(1000);
                }

                try { _listener.Stop(); } catch { }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error starting Keto Planner: " + ex.Message, "Keto Planner", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private static string FindBrowser()
        {
            string[] paths = new string[]
            {
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), @"Microsoft\Edge\Application\msedge.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), @"Microsoft\Edge\Application\msedge.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), @"Google\Chrome\Application\chrome.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), @"Google\Chrome\Application\chrome.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), @"Microsoft\Edge\Application\msedge.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), @"Google\Chrome\Application\chrome.exe")
            };

            foreach (string p in paths)
            {
                if (File.Exists(p)) return p;
            }
            return null;
        }

        private static void RunWatchdog()
        {
            // Initial grace period for browser to launch
            Thread.Sleep(15000);

            while (_running)
            {
                Thread.Sleep(2000);
                if (_firstRequestReceived)
                {
                    // If no requests or heartbeats for 8 seconds, the window was closed
                    if ((DateTime.UtcNow - _lastHeartbeat).TotalSeconds > 8)
                    {
                        _running = false;
                        Environment.Exit(0);
                    }
                }
            }
        }

        private static void RunServer()
        {
            while (_running)
            {
                try
                {
                    HttpListenerContext ctx = _listener.GetContext();
                    ThreadPool.QueueUserWorkItem((state) => HandleRequest(ctx));
                }
                catch
                {
                    if (!_running) break;
                }
            }
        }

        private static void HandleRequest(HttpListenerContext ctx)
        {
            try
            {
                _lastHeartbeat = DateTime.UtcNow;
                _firstRequestReceived = true;

                string rawUrl = ctx.Request.Url.AbsolutePath;
                if (rawUrl == "/ping")
                {
                    ctx.Response.StatusCode = 200;
                    ctx.Response.ContentType = "text/plain";
                    byte[] pong = Encoding.UTF8.GetBytes("pong");
                    ctx.Response.OutputStream.Write(pong, 0, pong.Length);
                    ctx.Response.Close();
                    return;
                }

                if (rawUrl == "/" || string.IsNullOrEmpty(rawUrl)) rawUrl = "/index.html";

                string relPath = rawUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar);
                string filePath = Path.Combine(_baseDir, relPath);

                if (!File.Exists(filePath))
                {
                    ctx.Response.StatusCode = 404;
                    byte[] notFound = Encoding.UTF8.GetBytes("Not Found");
                    ctx.Response.OutputStream.Write(notFound, 0, notFound.Length);
                    ctx.Response.Close();
                    return;
                }

                string ext = Path.GetExtension(filePath).ToLowerInvariant();
                string mime = "application/octet-stream";
                if (ext == ".html" || ext == ".htm") mime = "text/html; charset=utf-8";
                else if (ext == ".js") mime = "application/javascript; charset=utf-8";
                else if (ext == ".css") mime = "text/css; charset=utf-8";
                else if (ext == ".png") mime = "image/png";
                else if (ext == ".jpg" || ext == ".jpeg") mime = "image/jpeg";
                else if (ext == ".svg") mime = "image/svg+xml";
                else if (ext == ".woff2") mime = "font/woff2";
                else if (ext == ".woff") mime = "font/woff";
                else if (ext == ".json") mime = "application/json";

                ctx.Response.ContentType = mime;
                byte[] bytes = File.ReadAllBytes(filePath);
                ctx.Response.ContentLength64 = bytes.Length;
                ctx.Response.OutputStream.Write(bytes, 0, bytes.Length);
                ctx.Response.Close();
            }
            catch
            {
                try { ctx.Response.Abort(); } catch { }
            }
        }
    }
}
