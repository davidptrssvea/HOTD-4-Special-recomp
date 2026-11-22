# Enumerate mouse-class Raw Input devices; stable device paths are the saved IDs.
if (-not ('Hotd4RawDevices' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class Hotd4RawDevices {
    [StructLayout(LayoutKind.Sequential)] struct Device { public IntPtr Handle; public uint Type; }
    [DllImport("user32.dll")] static extern uint GetRawInputDeviceList([Out] Device[] devices, ref uint count, uint size);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern uint GetRawInputDeviceInfo(IntPtr device, uint command, StringBuilder data, ref uint size);
    public static string[] Paths() {
        uint count=0, size=(uint)Marshal.SizeOf(typeof(Device));
        if(GetRawInputDeviceList(null,ref count,size)==uint.MaxValue) throw new System.ComponentModel.Win32Exception();
        var devices=new Device[count];
        uint got=GetRawInputDeviceList(devices,ref count,size);
        if(got==uint.MaxValue) throw new System.ComponentModel.Win32Exception();
        var paths=new List<string>();
        for(int i=0;i<got;i++) if(devices[i].Type==0) {
            uint chars=0; GetRawInputDeviceInfo(devices[i].Handle,0x20000007,null,ref chars);
            if(chars==0)continue;
            var path=new StringBuilder((int)chars+1);chars++;
            if(GetRawInputDeviceInfo(devices[i].Handle,0x20000007,path,ref chars)!=uint.MaxValue)paths.Add(path.ToString());
        }
        return paths.ToArray();
    }
}
'@
}
function Get-Hotd4RawDevices {
    $index=0
    foreach($path in [Hotd4RawDevices]::Paths()) {
        $index++
        $parts=$path -split '#'
        $description='Mouse / Lightgun'
        if($parts.Length -ge 3) {
            $key='Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\'+($parts[0] -replace '^\\\?\?\\','' -replace '^\\\\\?\\','')+'\'+$parts[1]+'\'+$parts[2]
            $value=Get-ItemProperty -LiteralPath $key -Name DeviceDesc -ErrorAction SilentlyContinue
            if($value.DeviceDesc){$description=($value.DeviceDesc -split ';')[-1]}
        }
        [pscustomobject]@{ Path=$path; Name="Device $index - $description" }
    }
}
