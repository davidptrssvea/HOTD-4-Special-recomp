"""Render a menu image from the locally built game and user's own dump."""
import hashlib,json,os,struct,subprocess,tempfile
from pathlib import Path

def ppm_to_bmp(ppm,bmp):
 with ppm.open('rb') as f:
  if f.readline().strip()!=b'P6':raise ValueError('Invalid render capture')
  w,h=map(int,f.readline().split())
  if (w,h)!=(1920,1080) or f.readline().strip()!=b'255':raise ValueError('Unexpected render dimensions')
  rgb=f.read()
 if len(rgb)!=w*h*3 or len(set(rgb[::97]))<48:raise ValueError('Empty or incomplete render capture')
 stride=(w*3+3)&~3;size=54+stride*h
 with bmp.open('wb') as f:
  f.write(struct.pack('<2sIHHI',b'BM',size,0,0,54));f.write(struct.pack('<IiiHHIIiiII',40,w,h,1,24,0,stride*h,2835,2835,0,0))
  for y in range(h-1,-1,-1):
   row=bytearray(rgb[y*w*3:(y+1)*w*3]);row[0::3],row[2::3]=row[2::3],row[0::3];f.write(row);f.write(bytes(stride-w*3))

def generate(app,dump,frame=4000):
 app=Path(app).resolve();dump=Path(dump).resolve();dest=app/'hotd4sp-menu.jpg'
 if dest.exists() and dest.stat().st_size>1024:
  print('Keeping existing menu background.',flush=True);return
 print('Rendering menu background from your local dump (approximately one minute)...',flush=True)
 log='';flags=getattr(subprocess,'CREATE_NO_WINDOW',0)
 with tempfile.TemporaryDirectory(prefix='hotd4-menu-') as td:
  temp=Path(td);image=bytearray((dump/'elf/hod4M.elf').read_bytes())
  if hashlib.sha256(image).hexdigest()!='b84c70d9940d5f5fa7d287fd8c6b050444fdcbc2fd742d3afc74a1099bbec5fe':raise ValueError('Unsupported ELF for menu render')
  elf=temp/'render.elf';elf.write_bytes(image)
  (temp/'lindbergh.ini').write_text('width = 1920\nheight = 1080\nfullscreen = 0\nmuted = 1\nvolume = 0\nmouse_grab = 0\nraw_mouse = 0\ncrosshair = 0\naa = 4\naf = 16\n')
  (temp/'input-profile.txt').write_text('0');(temp/'sinden-profile.txt').write_text('0')
  script=temp/'inputs.txt';script.write_text(f'0 {frame+5} -1 -1 0 0\n300 300 -1 -1 0 1\n360 380 -1 -1 1 1\n700 701 -1 -1 1 0\n')
  env={k:v for k,v in os.environ.items() if not k.upper().startswith(('HOTD4','LINDBERGH_','TEA_'))}
  env.update(HOTD4SP_MENU='1',HOTD4SP_RENDER_SIZE='1920x1080',LINDBERGH_AUTOSTART='12',LINDBERGH_GOD='1',LINDBERGH_CROSSHAIR='0',PATH=str(app)+os.pathsep+os.environ.get('PATH',''),TEA_DIR=str(dump),LINDBERGH_GAME_CWD=str(dump/'elf'),HOTD4_SETTINGS_DIR=str(temp),HOTD4_PAUSE_MENU='0',LINDBERGH_HIDDEN='1',ALSOFT_DRIVERS='null',LINDBERGH_FULLSCREEN='0',LINDBERGH_WINDOW='1920x1080',LINDBERGH_GL_THREAD='0',LINDBERGH_DIPSW='e0',LINDBERGH_HOTD4_PACE_CUTSCENES='1',LINDBERGH_NVRAM=str(temp/'cabinet.bin'),LINDBERGH_SCRIPT=str(script),LINDBERGH_SHOT=str(temp/'frame.ppm'),LINDBERGH_SHOT_FRAME=str(frame),LINDBERGH_EXIT_AFTER=str(frame+1))
  try:
   result=subprocess.run([str(app/'hotd4sp-desktop.exe'),str(elf)],cwd=temp,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180,creationflags=flags)
   log=result.stdout.decode('utf-8','replace');(app/'menu-background.log').write_text(log,encoding='utf-8')
   if result.returncode:raise RuntimeError('Local renderer exited with code '+str(result.returncode))
   if '[shot] frame '+str(frame) not in log:raise RuntimeError('Menu scene was not reached')
   ppm_to_bmp(temp/'frame.ppm',temp/'frame.bmp')
   # Windows' built-in image codec; no Pillow/FFmpeg or extra downloads needed.
   convert=temp/'convert.ps1';convert.write_text('''param([string]$Source,[string]$Destination)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$image=[Drawing.Image]::FromFile($Source)
$codec=[Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
$parameters=[Drawing.Imaging.EncoderParameters]::new(1)
$parameters.Param[0]=[Drawing.Imaging.EncoderParameter]::new([Drawing.Imaging.Encoder]::Quality,[long]92)
try {$image.Save($Destination,$codec,$parameters)} finally {$parameters.Dispose();$image.Dispose()}
''',encoding='utf-8-sig')
   output=temp/'background.jpg';powershell=Path(env.get('WINDIR','C:/Windows'))/'System32/WindowsPowerShell/v1.0/powershell.exe'
   subprocess.run([str(powershell),'-NoProfile','-ExecutionPolicy','Bypass','-File',str(convert),str(temp/'frame.bmp'),str(output)],check=True,creationflags=flags,timeout=30)
   if output.stat().st_size<10000:raise ValueError('Menu image encoding failed')
   staged=app/'hotd4-menu.pending';staged.write_bytes(output.read_bytes());staged.replace(dest)
   (app/'menu-background-source.json').write_text(json.dumps({'generated_locally':True,'method':'local-game-render','scene':'opening-gameplay','frame':frame,'resolution':[1920,1080],'source_elf_sha256':hashlib.sha256((dump/'elf/hod4M.elf').read_bytes()).hexdigest(),'image_sha256':hashlib.sha256(dest.read_bytes()).hexdigest()},indent=2),encoding='utf-8')
   print('Created local menu background: '+str(dest),flush=True)
  except subprocess.TimeoutExpired as e:
   (app/'menu-background.log').write_text('Local menu render timed out.\n'+str(e),encoding='utf-8');raise RuntimeError('Menu rendering timed out; install remains playable') from e
  except Exception as e:
   (app/'menu-background.log').write_text(log+'\nMenu background generation failed: '+str(e),encoding='utf-8');raise
if __name__=='__main__':
 import argparse
 ap=argparse.ArgumentParser();ap.add_argument('--app',required=True);ap.add_argument('--dump',required=True);ap.add_argument('--frame',type=int,default=4000);a=ap.parse_args()
 try:generate(a.app,a.dump,a.frame)
 except Exception as e:print('Menu background generation failed: '+str(e),file=__import__('sys').stderr);raise SystemExit(1)
