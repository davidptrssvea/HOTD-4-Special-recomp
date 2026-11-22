using System;
using System.IO;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Threading;
using System.Windows.Forms;
internal static class Launcher {
 [STAThread] private static void Main(string[] args) {
  try {
   string root=AppDomain.CurrentDomain.BaseDirectory;
   bool vr=Array.Exists(args,arg=>arg.Equals("--vr",StringComparison.OrdinalIgnoreCase));
   string script=Path.Combine(root,vr?"launch_hotd4sp.ps1":"hotd4sp-launcher.ps1");
   if(!File.Exists(script))throw new FileNotFoundException("Missing HOTD4 Special launcher script.",script);
   var initial=InitialSessionState.CreateDefault();
   initial.ExecutionPolicy=Microsoft.PowerShell.ExecutionPolicy.Bypass;
   using(var runspace=RunspaceFactory.CreateRunspace(initial)) {
    runspace.ApartmentState=ApartmentState.STA;
    runspace.ThreadOptions=PSThreadOptions.UseCurrentThread;
    runspace.Open();
    using(var imports=PowerShell.Create()) {
     imports.Runspace=runspace;
     string modules=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),"WindowsPowerShell\\v1.0\\Modules");
     imports.AddCommand("Import-Module").AddArgument(Path.Combine(modules,"Microsoft.PowerShell.Utility\\Microsoft.PowerShell.Utility.psd1"));imports.Invoke();imports.Commands.Clear();
     imports.AddCommand("Import-Module").AddArgument(Path.Combine(modules,"Microsoft.PowerShell.Management\\Microsoft.PowerShell.Management.psd1"));imports.Invoke();
    }
    using(var ps=PowerShell.Create()) {
     ps.Runspace=runspace;ps.AddCommand(script);if(vr)ps.AddParameter("Mode","VR");
     foreach(string arg in args) {
      if(arg.Equals("--settings",StringComparison.OrdinalIgnoreCase))ps.AddParameter("InitialPage","OptionsPage");
      else if(arg.Equals("--log",StringComparison.OrdinalIgnoreCase))ps.AddParameter("LogFrames");
     }
     ps.Invoke();
     if(ps.HadErrors)throw new Exception(ps.Streams.Error[0].ToString());
    }
   }
  }catch(Exception e){MessageBox.Show(e.GetBaseException().Message,"HOTD4 Special",MessageBoxButtons.OK,MessageBoxIcon.Error);}
 }
}
