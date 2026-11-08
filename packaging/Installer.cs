using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

internal class SetupWindow : Form {
 private readonly Label message = new Label();
 private readonly Button action = new Button();
 private readonly ProgressBar progress = new ProgressBar();
 private bool completed;
 public SetupWindow() {
  Text = "Instalar Plugin Online";
  ClientSize = new System.Drawing.Size(480, 230);
  FormBorderStyle = FormBorderStyle.FixedDialog; MaximizeBox = false;
  StartPosition = FormStartPosition.CenterScreen;
  var title = new Label(); title.Text = "Plugin Online"; title.Font = new System.Drawing.Font("Segoe UI", 17F, System.Drawing.FontStyle.Bold); title.SetBounds(25, 18, 410, 38);
  message.Text = "Instala el plugin para usar música y video en VirtualDJ. Necesitas conexión a internet."; message.SetBounds(28, 66, 420, 55);
  progress.SetBounds(28, 128, 420, 16); progress.Style = ProgressBarStyle.Marquee; progress.Visible = false;
  action.Text = "Instalar"; action.SetBounds(325, 160, 120, 38); action.Click += async delegate { if (completed) { Close(); return; } await Install(); };
  Controls.AddRange(new Control[] { title, message, progress, action });
 }
 private async Task Install() {
  action.Enabled=false; progress.Visible=true;
  message.Text="Preparando el plugin. Esto puede tardar unos minutos...";
  try {
   await Task.Run(() => Installer.InstallPackage());
   progress.Visible=false; message.Text="¡Listo! Abre VirtualDJ y busca Plugin Online en la lista de música.";
   action.Text="Finalizar"; completed=true;
  } catch (Exception ex) {
   progress.Visible=false; message.Text="No se pudo completar la instalación. " + ex.Message;
   action.Text="Reintentar";
  } finally { action.Enabled=true; }
 }
}

internal static class Installer {
 private static ZipArchive OpenPackage() {
  Stream stream=Assembly.GetExecutingAssembly().GetManifestResourceStream("payload.zip");
  if(stream==null) throw new InvalidOperationException("El paquete está incompleto.");
  return new ZipArchive(stream, ZipArchiveMode.Read);
 }
 private static bool VerifyPackage() {
  using (var zip=OpenPackage()) {
   bool script=false, plugin=false, service=false, version=false, tray=false;
   foreach (ZipArchiveEntry entry in zip.Entries) {
    string name=entry.FullName.Replace('\\','/');
    if(name=="INSTALAR.ps1") script=true;
    if(name=="VERSION") version=true;
    if(name=="backend/app/main.py") service=true;
    if(name=="Plugin Online Bandeja.exe") tray=true;
    if(name=="plugin/online-source/prebuilt/x64/YouTube Plugin Online.dll") plugin=true;
   }
   return script && plugin && service && version && tray;
  }
 }
 public static void InstallPackage() {
  if (Process.GetProcessesByName("virtualdj").Length != 0) throw new InvalidOperationException("Cierra VirtualDJ e inténtalo nuevamente.");
  string temp=Path.Combine(Path.GetTempPath(),"PluginOnline-"+Guid.NewGuid().ToString("N"));
  Directory.CreateDirectory(temp);
  try {
   using(var zip=OpenPackage()) zip.ExtractToDirectory(temp);
   string script=Path.Combine(temp,"INSTALAR.ps1");
   string shell=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), @"WindowsPowerShell\v1.0\powershell.exe");
   var info=new ProcessStartInfo(shell, "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File \""+script+"\"");
   info.UseShellExecute=false; info.CreateNoWindow=true; info.WorkingDirectory=temp;
   info.RedirectStandardOutput=true; info.RedirectStandardError=true;
   string log=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"PluginOnline-instalacion.log");
   var capturedError=new StringBuilder();
   using(var process=new Process()) using(var writer=File.CreateText(log)) {
    process.StartInfo=info;
    process.OutputDataReceived += (s,e) => { if(e.Data!=null) lock(writer) { writer.WriteLine(e.Data); } };
    process.ErrorDataReceived += (s,e) => { if(e.Data!=null) lock(writer) { writer.WriteLine(e.Data); capturedError.AppendLine(e.Data); } };
    process.Start(); process.BeginOutputReadLine(); process.BeginErrorReadLine(); process.WaitForExit();
    if(process.ExitCode!=0) {
     string errors=capturedError.ToString();
     if(errors.Contains("puerto pertenece") || errors.Contains("detener el servicio anterior"))
      throw new InvalidOperationException("No se pudo detener el servicio anterior. No se ha detenido ninguna otra aplicación.");
     if(errors.Contains("VirtualDJ")) throw new InvalidOperationException("Cierra VirtualDJ y vuelve a intentarlo.");
     throw new InvalidOperationException("Comprueba tu conexión y vuelve a intentarlo. Se guardaron los detalles para diagnóstico.");
    }
   }
   string tray=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "YouTube Plugin Online", "Plugin Online Bandeja.exe");
   if (!File.Exists(tray)) throw new InvalidOperationException("No se encontró el icono de notificaciones.");
   Process.Start(new ProcessStartInfo(tray) { WorkingDirectory=Path.GetDirectoryName(tray), WindowStyle=ProcessWindowStyle.Hidden, UseShellExecute=true });
  } finally { try { Directory.Delete(temp,true); } catch {} }
 }
 [STAThread] private static int Main(string[] args) {
  if(args.Length>0 && args[0]=="--verify-only") return VerifyPackage()?0:2;
  Application.EnableVisualStyles(); Application.SetCompatibleTextRenderingDefault(false); Application.Run(new SetupWindow()); return 0;
 }
}
