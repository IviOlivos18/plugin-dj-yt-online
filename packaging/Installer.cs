using System;
using System.IO;
using System.IO.Compression;
using System.Diagnostics;
using System.Reflection;
class Installer {
 static int Main(string[] args) {
  string work = Path.Combine(Path.GetTempPath(), "YouTubePluginOnline-" + Guid.NewGuid().ToString("N"));
  try {
   Directory.CreateDirectory(work);
   using (Stream s = Assembly.GetExecutingAssembly().GetManifestResourceStream("payload.zip"))
   using (ZipArchive z = new ZipArchive(s, ZipArchiveMode.Read)) {
    if (args.Length > 0 && args[0] == "--verify-only") {
     bool hasScript = false, hasPlugin = false;
     foreach (ZipArchiveEntry entry in z.Entries) {
      string name = entry.FullName.Replace('\\', '/');
      if (name == "INSTALAR.ps1") hasScript = true;
      if (name == "plugin/online-source/prebuilt/x64/YouTube Plugin Online.dll") hasPlugin = true;
     }
     if (!hasScript || !hasPlugin) return 2;
     Console.WriteLine("Installer package OK; entries: " + z.Entries.Count); return 0;
    }
    z.ExtractToDirectory(work);
   }
   string script=Path.Combine(work,"INSTALAR.bat");
   var p=Process.Start(new ProcessStartInfo("cmd.exe", "/c \"\""+script+"\"\"") {UseShellExecute=false, WorkingDirectory=work});
   p.WaitForExit(); return p.ExitCode;
  } catch (Exception ex) { Console.Error.WriteLine("No se pudo iniciar el instalador: " + ex.Message); Console.ReadLine(); return 1; }
  finally { try {Directory.Delete(work,true);} catch {} }
 }
}
