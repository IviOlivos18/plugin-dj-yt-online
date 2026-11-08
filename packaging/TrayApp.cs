using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Text;
using System.Windows.Forms;
using System.Web.Script.Serialization;
using System.Collections.Generic;

internal class TrayApp : ApplicationContext {
 private NotifyIcon icon;
 private Timer timer;
 private bool seen, pending, ready;
 private ToolStripMenuItem status, install;
 private const string Address = "http://127.0.0.1:8766";
 public TrayApp() {
  var menu = new ContextMenuStrip();
  status = new ToolStripMenuItem("Esperando VirtualDJ") { Enabled = false };
  install = new ToolStripMenuItem("Ver actualización descargada") { Enabled = false };
  install.Click += delegate {
   string folder=Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"data","updates");
   if (Directory.Exists(folder)) Process.Start("explorer.exe", folder);
  };
  menu.Items.Add(status); menu.Items.Add(install);
  menu.Items.Add("Salir", null, delegate { icon.Visible=false; ExitThread(); });
  icon = new NotifyIcon { Text="Plugin Online", Icon=System.Drawing.SystemIcons.Application, Visible=true, ContextMenuStrip=menu };
  timer = new Timer { Interval=3000 }; timer.Tick += Tick; timer.Start();
 }
 private void Tick(object sender, EventArgs e) {
  bool open=Process.GetProcessesByName("virtualdj").Length>0;
  if (!open) { seen=false; pending=false; ready=false; status.Text="Esperando VirtualDJ"; install.Enabled=false; return; }
  if (!seen) { seen=true; pending=true; status.Text="Esperando servicio"; }
  try {
   if (pending) {
    using (var c=new WebClient()) { c.UploadString(Address+"/api/update/virtualdj-open", "POST", ""); }
    pending=false;
   }
   using (var c=new WebClient()) {
    var data=new JavaScriptSerializer().Deserialize<Dictionary<string,object>>(c.DownloadString(Address+"/api/update/state"));
    string value=Convert.ToString(data["status"]);
    if (value=="ready") {
     status.Text="Actualización descargada"; install.Enabled=true;
     if (!ready) { ready=true; icon.ShowBalloonTip(5000,"Nueva actualización", "Haz clic en el icono para ver la actualización descargada.", ToolTipIcon.Info); }
    } else if (value=="checking" || value=="downloading") { status.Text="Buscando actualización"; }
    else if (value=="current") { status.Text="Sin actualizaciones"; }
    else if (value=="unavailable") { status.Text="No se pudo comprobar"; }
   }
  } catch { if (!pending) status.Text="Servicio no disponible"; else status.Text="Esperando servicio"; }
 }
 [STAThread] private static void Main() { Application.EnableVisualStyles(); Application.Run(new TrayApp()); }
}
