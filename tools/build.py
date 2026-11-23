"""Build HOTD4 Special entirely from the user's verified local arcade dump."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
from build_support import run, build_jobs
EXPECTED = json.loads((ROOT / 'tools/elf-variants.json').read_text())['prepared_sha256']


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def find_dump(path):
    path = path.resolve()
    if path.is_file():
        path = path.parent
    for folder in (path, path / 'hotd4sp', path / 'disk0', path.parent if path.name.lower() == 'elf' else path):
        elf = folder / 'elf/hod4M.elf'
        if elf.is_file() and (folder / 'fs').is_dir():
            if not any(p.is_file() for p in (folder / 'fs').rglob('*')):
                raise ValueError('Incomplete HOTD4 Special dump: fs is empty.')
            if digest(elf) != EXPECTED:
                raise ValueError('Unsupported HOTD4 Special hod4M.elf (SHA-256 ' + digest(elf) + '). Expected ' + EXPECTED)
            return folder
    raise ValueError('Select the extracted HOTD4 Special folder containing elf/hod4M.elf and fs.')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dump', required=True)
    ap.add_argument('--output', required=True)
    ap.add_argument('--toolchain', required=True)
    ap.add_argument('--jobs', type=int, default=0)
    ap.add_argument('--openxr', action='store_true')
    ap.add_argument('--validate-only', action='store_true')
    ap.add_argument('--stage-update', action='store_true')
    a = ap.parse_args()
    a.jobs = build_jobs(a.jobs)
    print(f'Compiler workers: {a.jobs} (use -Jobs N in Setup to override).', flush=True)
    os.environ['PYTHONUNBUFFERED'] = '1'
    dump = find_dump(Path(a.dump))
    print('Verified HOTD4 Special arcade dump:', dump, flush=True)
    if a.validate_only:
        return
    out = Path(a.output).resolve()
    for protected in (dump, ROOT / 'source', ROOT / 'ui', ROOT / 'tools'):
        if out == protected or out in protected.parents or protected in out.parents:
            raise ValueError('Choose an installation directory outside your dump and package sources.')
    tool = Path(a.toolchain).resolve()
    bin = tool / 'mingw64/bin'
    for name in ('gcc.exe', 'cmake.exe', 'ninja.exe', 'python.exe', 'objdump.exe', 'strip.exe'):
        if not (bin / name).is_file():
            raise ValueError('Missing build tool: ' + str(bin / name))
    os.environ['PATH'] = str(bin) + os.pathsep + os.environ.get('PATH', '')
    source = ROOT / 'source'
    gen = source / 'games/hotd4sp/generated'
    gen.mkdir(parents=True, exist_ok=True)
    manifest = json.loads((ROOT / 'package-manifest.json').read_text())
    inputs = [f for f in manifest['files'] if f['path'].startswith(('source/lindberghrecomp/tools/', 'source/lindberghrecomp/pcrecomp/tools/', 'source/games/hotd4sp/names.txt', 'tools/build.py', 'tools/gl-', 'tools/elf-variants.json'))]
    signature = hashlib.sha256((EXPECTED + json.dumps(inputs, sort_keys=True)).encode()).hexdigest()
    marker = gen / 'local-build-signature.txt'
    if not marker.is_file() or marker.read_text() != signature:
        print('Finding functions in the stripped Special ELF. This phase can take several minutes...', flush=True)
        bounds = gen / 'bounds.txt'
        run([bin / 'python.exe', '-m', 'tools', 'bounds', dump / 'elf/hod4M.elf', bounds,
             '--names', source / 'games/hotd4sp/names.txt'], cwd=source / 'lindberghrecomp')
        run([bin / 'python.exe', '-m', 'tools', 'recomp', dump / 'elf/hod4M.elf', gen,
             '--bounds', bounds], cwd=source / 'lindberghrecomp')
        thunk = gen / 'recomp_gl_thunks_windows.c'
        with thunk.open('w', encoding='utf-8') as f:
            run([bin / 'python.exe', source / 'lindberghrecomp/tools/gen_gl_thunks.py',
                 gen / 'recomp_imports.h', bin.parent / 'include/GL/glew.h'], stdout=f)
        text = thunk.read_text()
        text = text.replace('#include "arbprog.h"', '#include "arbprog.h"\n' + (ROOT / 'tools/gl-enhancements.h').read_text())
        for name, body in json.loads((ROOT / 'tools/gl-overrides.json').read_text()).items():
            text, count = re.subn(r'static void th_' + name + r'\(CPU \*c\)\n\{.*?\n\}', lambda _: body, text, count=1, flags=re.S)
            if count != 1:
                raise ValueError('GL wrapper generation changed: ' + name)
        thunk.write_text(text)
        marker.write_text(signature)
    builds = {}
    for name, folder, vr in [('hotd4sp-desktop.exe', 'build', False), ('hotd4sp-vr.exe', 'build-openxr', True)]:
        if vr and not a.openxr:
            continue
        build = ROOT / folder
        run([bin / 'cmake.exe', '-S', source, '-B', build, '-G', 'Ninja', '-DCMAKE_BUILD_TYPE=Release',
             '-DCMAKE_C_FLAGS_RELEASE=', '-DLINDBERGH_GAMES=hotd4sp', '-DLINDBERGH_OPENXR=' + ('ON' if vr else 'OFF'),
             '-DLINDBERGH_RENDERER=OPENGL', '-DCMAKE_C_COMPILER=' + str(bin / 'gcc.exe'),
             '-DCMAKE_MAKE_PROGRAM=' + str(bin / 'ninja.exe'), '-DCMAKE_PREFIX_PATH=' + str(bin.parent)])
        run([bin / 'cmake.exe', '--build', build, '--target', 'hotd4sp', '--parallel', max(1, min(a.jobs, 16))])
        builds[name] = build / 'hotd4sp.exe'
    dlls = {}
    pending = list(builds.values())
    seen = set()
    system = Path(os.environ.get('WINDIR', 'C:/Windows')) / 'System32'
    while pending:
        text = subprocess.check_output([str(bin / 'objdump.exe'), '-p', str(pending.pop())], text=True, errors='replace')
        for name in re.findall(r'DLL Name:\s*(\S+)', text):
            if name.lower() in seen:
                continue
            seen.add(name.lower())
            dependency = bin / name
            if dependency.is_file():
                dlls[name] = dependency
                pending.append(dependency)
            elif not (system / name).is_file() and not name.lower().startswith(('api-ms-', 'ext-ms-')):
                raise ValueError('Unresolved DLL: ' + name)
    app = out / 'HOTD4SP_Recomp'
    app.mkdir(parents=True, exist_ok=True)
    for name, file in builds.items():
        shutil.copy2(file, app / name)
        run([bin / 'strip.exe', app / name])
    for name, file in dlls.items():
        shutil.copy2(file, app / name)
    if not a.stage_update:
        local = out / 'hotd4sp'
        (local / 'elf').mkdir(parents=True, exist_ok=True)
        shutil.copytree(dump / 'fs', local / 'fs', dirs_exist_ok=True)
        shutil.copy2(dump / 'elf/hod4M.elf', local / 'elf/hod4M.elf')
    # Never seed or overwrite cabinet state from the source dump.
    for file in (ROOT / 'ui').rglob('*'):
        if file.is_file():
            if not a.openxr and ('VR OpenXR' in file.name or file.name == 'launch_hotd4sp.ps1'):
                continue
            dest = app / file.relative_to(ROOT / 'ui')
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(file, dest)
    compiler = Path(os.environ.get('SystemRoot', 'C:/Windows')) / 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
    sma = Path(os.environ.get('SystemRoot', 'C:/Windows')) / 'Microsoft.NET/assembly/GAC_MSIL/System.Management.Automation'
    assembly = next(sma.glob('*/System.Management.Automation.dll'))
    run([compiler, '/nologo', '/target:winexe', '/platform:x64', '/reference:System.Windows.Forms.dll',
         '/reference:' + str(assembly).replace('/', '\\'),
         '/out:' + str(app / 'Play HOTD4 Special.exe').replace('/', '\\'),
         str(ROOT / 'ui/Launcher.cs').replace('/', '\\')])
    (out / 'Play HOTD4 Special.cmd').write_text('@echo off\r\nstart "" "%~dp0HOTD4SP_Recomp\\Play HOTD4 Special.exe"\r\n', newline='')
    if not a.stage_update:
        try:
            run(['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', app / 'hotd-game-library.ps1',
                 '-RegisterOnly', '-LibraryRecompDir', app, '-LibraryGame', 'Special'])
        except subprocess.CalledProcessError:
            print('The game was installed, but automatic library registration failed. Use Locate installed game in the Game Library.', flush=True)
    licenses = app / 'licenses'
    licenses.mkdir(exist_ok=True)
    for label, file in [('ports', source / 'LICENSE'), ('lindberghrecomp', source / 'lindberghrecomp/LICENSE'), ('pcrecomp', source / 'lindberghrecomp/pcrecomp/LICENSE')]:
        shutil.copy2(file, licenses / (label + '.txt'))
    for file in (bin.parent / 'share/licenses').glob('*'):
        if file.is_dir():
            shutil.copytree(file, licenses / 'dependencies' / file.name, dirs_exist_ok=True)
    (out / 'local-build.json').write_text(json.dumps({'built_locally': True, 'elf_sha256': EXPECTED,
        'package_manifest_sha256': digest(ROOT / 'package-manifest.json'), 'generator_signature': signature,
        'desktop_sha256': digest(app / 'hotd4sp-desktop.exe'),
        **({'openxr_sha256': digest(app / 'hotd4sp-vr.exe')} if a.openxr else {}),
        'built_utc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}, indent=2))
    print('Build complete. Open: ' + str(app / 'Play HOTD4 Special.exe'), flush=True)


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print('Setup failed: ' + str(e), file=__import__('sys').stderr)
        raise SystemExit(1)
