param([string]$InstalledApp,[string]$PreviewDir)
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$special=Test-Path (Join-Path $repo 'ui/hotd4sp-startmenu.ps1')
$edition=if($special){'Special'}else{'Normal'}
$base=Join-Path ([IO.Path]::GetTempPath()) ('HOTD-keyboard-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($base)
$env:LOCALAPPDATA=Join-Path $base 'local';[void][IO.Directory]::CreateDirectory($env:LOCALAPPDATA)
$uiSource=if($InstalledApp){$InstalledApp}else{Join-Path $repo 'ui'}
foreach($p in Get-ChildItem -LiteralPath $uiSource -File | Where-Object {$_.Extension -in '.ps1','.cs','.xaml' -or $_.Name -in 'hotd-update-version.txt','lindbergh.ini'}){Copy-Item -LiteralPath $p.FullName -Destination $base}
. (Join-Path $base 'hotd4-controls.ps1')
function Assert($condition,[string]$message){if(!$condition){throw $message}}
function Click($b){$b.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))}
$legacy=Join-Path $base 'legacy';[void][IO.Directory]::CreateDirectory($legacy)
[IO.File]::WriteAllText((Join-Path $legacy 'controls-profile.txt'),"HOTD4-CONTROLS-1`ncoin1 57`nservice 115`n")
$data=Read-Hotd4Controls $legacy
Assert ($data.Values.Count -eq 33 -and $data.Values.coin1 -eq 57 -and $data.Values.service -eq 115 -and $data.Values.kb2_down -eq 115) 'Legacy bindings were not preserved with keyboard defaults'
Write-Hotd4Controls $legacy $data.Values
$data.Values.kb1_up=$data.Values.kb2_up
$failed=$false;try{Write-Hotd4Controls $legacy $data.Values}catch{$failed=$true}
Assert $failed 'Overlapping player directions should be rejected'
Add-Type -AssemblyName PresentationFramework
$name=if($special){'hotd4sp-startmenu.ps1'}else{'hotd4-startmenu.ps1'}
$path=Join-Path $base $name;$source=[IO.File]::ReadAllText($path);$source=$source.Replace('[void] $window.ShowDialog()','& $script:Inspect $window $controls $showPage')
[IO.File]::WriteAllText($path,$source,[Text.UTF8Encoding]::new($true));. $path
function Preview($w,[string]$name){
 if(!$PreviewDir){return};[void][IO.Directory]::CreateDirectory($PreviewDir);$w.UpdateLayout();$v=$w.Content
 $b=[Windows.Media.Imaging.RenderTargetBitmap]::new([int]$v.ActualWidth,[int]$v.ActualHeight,96,96,[Windows.Media.PixelFormats]::Pbgra32);$b.Render($v)
 $e=[Windows.Media.Imaging.PngBitmapEncoder]::new();$e.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($b));$f=[IO.File]::Create((Join-Path $PreviewDir ($edition+'-'+$name+'.png')));try{$e.Save($f)}finally{$f.Dispose()}
}
$script:pass=0
$script:Inspect={
 param($w,$ui,$show)
 $w.Topmost=$false;$w.ShowActivated=$false;$w.Left=-20000;$w.Top=-20000;$w.Width=1280;$w.Height=720;$w.Show();$w.UpdateLayout()
 if($script:pass -eq 0){
  & $show 'InputPage';$w.UpdateLayout()
  $choice=@($ui.InputMode.Items | Where-Object Tag -eq '5');Assert ($choice.Count -eq 1) 'Keyboard mode missing'
  $ui.InputMode.SelectedItem=$choice[0];$w.UpdateLayout()
  Assert ($ui.KeyboardHelp.Visibility -eq 'Visible' -and !$ui.Gun1.IsEnabled -and !$ui.SoloPlayer.IsEnabled) 'Keyboard help or device state is incorrect'
  Preview $w 'input'
  Click $ui.SaveInput
  Assert ([IO.File]::ReadAllText((Join-Path $base 'input-profile.txt')).Trim() -eq '5') 'Keyboard mode was not saved'
  Click $ui.BindingsOpen;$w.UpdateLayout()
  $buttons=@{};foreach($group in $ui.BindingsList.Children | Where-Object {$_ -is [Windows.Controls.Primitives.UniformGrid]}){foreach($grid in $group.Children){foreach($b in $grid.Children | Where-Object {$_ -is [Windows.Controls.Button]}){$buttons[[int]$b.Tag]=$b}}}
  Assert ($buttons.Count -eq 33) 'Some bindings are missing from the menu'
  foreach($pair in @(@(16,[Windows.Input.Key]::I),@(24,[Windows.Input.Key]::K))){
   $b=$buttons[$pair[0]];$b.BringIntoView();$w.UpdateLayout();Click $b
   $e=[Windows.Input.KeyEventArgs]::new([Windows.Input.Keyboard]::PrimaryDevice,[Windows.PresentationSource]::FromVisual($w),1,$pair[1]);$e.RoutedEvent=[Windows.UIElement]::PreviewKeyDownEvent;$w.RaiseEvent($e)
   Assert ($ui.BindingsStatus.Text -eq 'Binding changed. Save to apply.') ('Remapping failed: '+$ui.BindingsStatus.Text)
  }
  Preview $w 'bindings'
  Click $ui.SaveBindings
  & $show 'MainPage';Preview $w 'main'
  $saved=Read-Hotd4Controls $base;Assert ($saved.Values.kb1_up -eq 105 -and $saved.Values.kb2_up -eq 107) 'Independent keyboard keys did not save'
  Assert ($ui.ControlSummaryList.Rows -eq 10 -and $ui.ControlSummaryList.Children.Count -eq 20) 'Keyboard start-menu control summary is incorrect'
 }else{
  & $show 'InputPage';$w.UpdateLayout();Assert ([string]$ui.InputMode.SelectedItem.Tag -eq '5') 'Keyboard mode did not reload'
  Click $ui.BindingsOpen;$w.UpdateLayout();$saved=Read-Hotd4Controls $base
  Assert ($saved.Values.kb1_up -eq 105 -and $saved.Values.kb2_up -eq 107) 'Keyboard remaps did not reload'
 }
 $w.Close()
}
for($i=0;$i -lt 2;$i++){$script:pass=$i;if($special){Show-Hotd4SPStartMenu $base 1280 720}else{Show-Hotd4StartMenu $base 1280 720}}
"PASS $edition keyboard mode, all 33 controls, WPF remap/reopen, legacy profiles, conflicts and active summary"
