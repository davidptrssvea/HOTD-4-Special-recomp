param([string]$InstalledApp,[string]$PreviewDir)
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$base=Join-Path ([IO.Path]::GetTempPath()) ('HOTD-display-'+[guid]::NewGuid().ToString('N'))
$edition=if(Test-Path (Join-Path $repo 'ui/hotdex-startmenu.ps1')){'EX'}elseif(Test-Path (Join-Path $repo 'ui/hotd4sp-startmenu.ps1')){'Special'}else{'Normal'}
$env:LOCALAPPDATA=Join-Path $base 'ui-profile'
[void][IO.Directory]::CreateDirectory($env:LOCALAPPDATA)
Add-Type -AssemblyName PresentationFramework
function Click($b){$b.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))}
foreach($edition in @($edition)){
 $root=$repo
 $fixture=Join-Path $base ('ui-'+$edition)
 [void][IO.Directory]::CreateDirectory($fixture)
 if($edition -ne 'EX'){
  . (Join-Path $root 'ui/hotd4-display.ps1')
  foreach($case in @(@(640,480,'4:3',640,480),@(800,600,'4:3',800,600),@(1280,960,'4:3',1280,960),@(1920,1080,'4:3',1440,1080),@(3840,2160,'4:3',2880,2160),@(3840,2160,'16:9',3840,2160))){
   $size=Get-Hotd4RenderSize $case[0] $case[1] $case[2]
   if($size[0] -ne $case[3] -or $size[1] -ne $case[4]){throw "Incorrect render size: $case"}
  }
  $failed=$false;try{Get-Hotd4RenderSize 640 360 '4:3' | Out-Null}catch{$failed=$true}
  if(!$failed){throw 'Too small 4:3 output should be rejected'}
 }
 $uiSource=if($InstalledApp){$InstalledApp}else{Join-Path $root 'ui'}
 foreach($required in Get-ChildItem -LiteralPath (Join-Path $root 'ui') -File | Where-Object { $_.Extension -in '.ps1','.cs','.xaml' -or $_.Name -eq 'hotd-update-version.txt' }){
  if(!(Test-Path -LiteralPath (Join-Path $uiSource $required.Name) -PathType Leaf)){throw "Incomplete launcher installation: $($required.Name) is missing from $uiSource"}
 }
 foreach($p in Get-ChildItem -LiteralPath $uiSource -File){Copy-Item -LiteralPath $p.FullName -Destination $fixture -Force}
 foreach($name in 'arcade-free-play.txt','arcade-mute-credit-sounds.txt'){
  [IO.File]::Delete((Join-Path $fixture $name))
 }
 $ini=Join-Path $fixture 'lindbergh.ini'
 if(!(Test-Path -LiteralPath $ini)){[IO.File]::WriteAllText($ini,"width = 1280"+[Environment]::NewLine+"height = 720"+[Environment]::NewLine+"fullscreen = 0"+[Environment]::NewLine)}
 $pref=Join-Path $fixture 'vsync-profile.txt'
 if(Test-Path -LiteralPath $pref){Remove-Item -LiteralPath $pref}
 $aspectPref=Join-Path $fixture 'aspect-ratio.txt'
 if(Test-Path -LiteralPath $aspectPref){Remove-Item -LiteralPath $aspectPref}
 if($edition -ne 'EX'){
  $name=if($edition -eq 'Normal'){'hotd4-startmenu.ps1'}else{'hotd4sp-startmenu.ps1'}
  $path=Join-Path $fixture $name;$source=[IO.File]::ReadAllText($path)
  $source=$source.Replace('[void] $window.ShowDialog()','& $script:Inspect $window $controls $showPage')
  [IO.File]::WriteAllText($path,$source,[Text.UTF8Encoding]::new($true))
  . $path
 }
 $script:Expected='0';$script:Choose='1'
 $script:Inspect={
  param($w,$ui,$show)
  $w.Topmost=$false;$w.ShowActivated=$false;$w.Left=-20000;$w.Top=-20000;$w.Width=1280;$w.Height=720
  $w.Show();$w.UpdateLayout()
  if($edition -eq 'EX'){Click $ui.Options;Click $ui.ArcadeOpen}
  else{& $show 'OptionsPage';Click $ui.GameplayOpen}
  $w.UpdateLayout()
  if(!$ui.FreePlay.IsVisible -or !$ui.MuteCreditSounds.IsVisible){throw "$edition arcade options are missing"}
  foreach($name in 'FreePlay','MuteCreditSounds'){
   if([int][bool]$ui[$name].IsChecked -ne [int]$script:Expected){throw "$edition $name did not load $script:Expected"}
   $ui[$name].IsChecked=$script:Choose -eq '1'
  }
  if($edition -eq 'EX'){Click $ui.ArcadeBack;Click $ui.Save}
  else{Click $ui.SaveGameplay}
  foreach($name in 'arcade-free-play.txt','arcade-mute-credit-sounds.txt'){
   if([IO.File]::ReadAllText((Join-Path $fixture $name)) -ne $script:Choose){throw "$edition did not save $name"}
  }

  & $show $(if($edition -eq 'EX'){'GraphicsPage'}else{'OptionsPage'})
  $w.UpdateLayout()
  if(!$w.FindName('Updates')){
   $updates=@($ui.MainPage.Children | Where-Object { $_.Name -eq 'Updates' })
   if($updates.Count -ne 1){throw "$edition updater did not initialize"}
  }
  if([string]$ui.VSync.SelectedItem.Tag -ne $script:Expected){throw "$edition V-sync did not load $script:Expected"}
  if($edition -ne 'EX'){
   if(!$ui.OptionsPage.IsAncestorOf($ui.Aspect) -or $ui.InputPage.IsAncestorOf($ui.Aspect) -or !$ui.Aspect.IsVisible){throw "$edition Aspect Ratio is not visible on Settings"}
   $expectedAspect=if($script:Expected -eq '0'){'16:9'}else{'4:3'}
   if([string]$ui.Aspect.SelectedItem.Tag -ne $expectedAspect){throw "$edition aspect did not reload $expectedAspect"}
   # Back discards an unsaved aspect selection.
   $ui.Aspect.SelectedIndex=if($script:Choose -eq '1'){1}else{0}
   Click $ui.OptionsBack
   & $show 'OptionsPage';$w.UpdateLayout()
   if([string]$ui.Aspect.SelectedItem.Tag -ne $expectedAspect){throw "$edition Back did not discard unsaved aspect"}
   $ui.Aspect.SelectedIndex=if($script:Choose -eq '1'){1}else{0}
   if($edition -eq 'Special' -and $ui.Framing.IsEnabled -eq ($script:Choose -eq '1')){throw 'Special framing should be disabled for 4:3'}
   $point=$ui.SaveOptions.TranslatePoint([Windows.Point]::new(0,0),$w.Content)
   if($point.Y -lt 0 -or $point.Y+$ui.SaveOptions.ActualHeight -gt 720){throw "$edition Settings Save is clipped"}
   if($PreviewDir -and $script:Choose -eq '1'){
    [void][IO.Directory]::CreateDirectory($PreviewDir)
    $bitmap=[Windows.Media.Imaging.RenderTargetBitmap]::new(1280,720,96,96,[Windows.Media.PixelFormats]::Pbgra32)
    $bitmap.Render($w.Content)
    $encoder=[Windows.Media.Imaging.PngBitmapEncoder]::new();$encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
    $stream=[IO.File]::Create((Join-Path $PreviewDir ($edition+'-settings.png')))
    try{$encoder.Save($stream)}finally{$stream.Dispose()}
   }
   Click $ui.SaveOptions
   if([IO.File]::ReadAllText($aspectPref).Trim() -ne $(if($script:Choose -eq '1'){'4:3'}else{'16:9'})){throw "$edition Settings did not save aspect"}
   & $show 'InputPage';$w.UpdateLayout()
  }
  foreach($item in $ui.VSync.Items){if([string]$item.Tag -eq $script:Choose){$ui.VSync.SelectedItem=$item}}
  $ui.VSync.BringIntoView();$w.UpdateLayout()
  $b=if($edition -eq 'EX'){$ui.GraphicsBack}else{$ui.SaveInput}
  $pt=$b.TranslatePoint([Windows.Point]::new(0,0),$w.Content)
  if($pt.Y -lt 0 -or $pt.Y+$b.ActualHeight -gt 720){throw "$edition bottom action is clipped"}
  if($edition -eq 'EX'){Click $ui.GraphicsBack;Click $ui.Save}else{Click $ui.SaveInput}
  if([IO.File]::ReadAllText($pref).Trim() -ne $script:Choose){throw "$edition V-sync did not save $script:Choose"}
  if($edition -ne 'EX' -and [IO.File]::ReadAllText($aspectPref).Trim() -ne $(if($script:Choose -eq '1'){'4:3'}else{'16:9'})){throw "$edition aspect did not save"}
  $w.Close()
 }
 for($pass=0;$pass -lt 2;$pass++){
  if($edition -eq 'EX'){
   . (Join-Path $fixture 'hotdex-startmenu.ps1')
   Show-HotdexStartMenu -RecompDir $fixture -Inspect {param($w,$ui,$show) & $script:Inspect $w $ui $show}
  }elseif($edition -eq 'Normal'){Show-Hotd4StartMenu $fixture 1280 720}
  else{Show-Hotd4SPStartMenu $fixture 1280 720}
  $script:Expected='1';$script:Choose='0'
 }
 "PASS $edition real WPF: V-sync Off/On persistence, aspect persistence where supported, reachable controls"
}
