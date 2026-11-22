import hashlib,json,os,pathlib,subprocess,urllib.request,urllib.error,zipfile,traceback
ROOT=pathlib.Path(__file__).resolve().parents[1]
REPO=os.environ.get('GITHUB_REPOSITORY','davidptrssvea/HOTD-4-Special-recomp')
TAG=os.environ.get('GITHUB_REF_NAME','v1.0.0')
TOKEN=os.environ.get('GH_TOKEN','')
def api(method,path,data=None,content_type='application/json'):
    body=json.dumps(data).encode() if isinstance(data,dict) else data
    req=urllib.request.Request('https://api.github.com'+path,data=body,method=method,headers={'Authorization':'Bearer '+TOKEN,'Accept':'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28','Content-Type':content_type})
    with urllib.request.urlopen(req,timeout=120) as r:
        raw=r.read();return json.loads(raw) if raw else None
def package():
    manifest=json.loads((ROOT/'package-manifest.json').read_text(encoding='utf-8'))
    names=sorted([v['path'] for v in manifest['files']]+['package-manifest.json'])
    for item in manifest['files']:
        path=pathlib.PurePosixPath(item['path'])
        assert not path.is_absolute() and '..' not in path.parts
        data=(ROOT/path).read_bytes()
        assert hashlib.sha256(data).hexdigest()==item['sha256'],str(path)
        assert not set(path.parts)&{'generated','build','cache','.git'}
        assert path.suffix.lower() not in {'.exe','.dll','.obj','.o','.elf','.iso','.bin','.jpg','.sfd','.adx','.wav','.mp3','.dds','.zip','.gz','.gzp','.pyc'}
        assert not data.startswith((b'MZ',b'\x7fELF'))
    out=ROOT.parent/('HOTD4SP-Local-Builder-'+TAG+'.zip')
    with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for name in names:
            info=zipfile.ZipInfo('HOTD4SP-Local-Builder/'+name,(2026,11,17,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;info.external_attr=0o100644<<16
            z.writestr(info,(ROOT/name).read_bytes(),compresslevel=9)
    downloads = [out]
    sums = ROOT.parent / 'SHA256SUMS.txt'
    sums.write_bytes(''.join(
        f'{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}\n'
        for path in downloads
    ).encode('ascii'))
    return out, sums, *downloads[1:]

def git(*args,input=None):return subprocess.check_output(['git',*args],input=input).decode().strip()
def status_write(status):
    branch='refs/heads/release-status'
    parent=[]
    if subprocess.run(['git','fetch','--depth=1','origin',branch],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode==0:parent=['-p',git('rev-parse','FETCH_HEAD')]
    blob=git('hash-object','-w','--stdin',input=(json.dumps(status,indent=2)+'\n').encode())
    tree=git('mktree',input=('100644 blob '+blob+'\trelease-status.json\n').encode())
    commit=git('-c','user.name=github-actions[bot]','-c','user.email=41898282+github-actions[bot]@users.noreply.github.com','commit-tree',tree,*parent,input=('Release '+TAG+' verification\n').encode())
    subprocess.run(['git','push','origin',commit+':'+branch],check=True)

def main():
    paths = package()
    if '--package-only' in __import__('sys').argv:
        print(paths[0], hashlib.sha256(paths[0].read_bytes()).hexdigest())
        return
    prerelease = '-' in TAG.split('+', 1)[0]
    status={'tag':TAG,'commit':os.environ['GITHUB_SHA'],'run_url':'https://github.com/'+REPO+'/actions/runs/'+os.environ['GITHUB_RUN_ID']}
    try:
        repo=api('GET','/repos/'+REPO)
        status['private']=repo['private']
        try:release=api('GET','/repos/'+REPO+'/releases/tags/'+TAG)
        except urllib.error.HTTPError as e:
            if e.code!=404:raise
            release=api('POST','/repos/'+REPO+'/releases',{'tag_name':TAG,'name':'HOTD4 Special Local Builder '+TAG,'draft':True,'prerelease':prerelease,'body':(ROOT/'RELEASE-NOTES.md').read_text(encoding='utf-8')})
        assert release['draft'],'Refusing to replace an already published release'
        for old in release['assets']:api('DELETE','/repos/'+REPO+'/releases/assets/'+str(old['id']))
        assets=[]
        for path in paths:
            url=release['upload_url'].split('{')[0]+'?name='+path.name
            req=urllib.request.Request(url,data=path.read_bytes(),method='POST',headers={'Authorization':'Bearer '+TOKEN,'Accept':'application/vnd.github+json','Content-Type':'application/octet-stream'})
            with urllib.request.urlopen(req,timeout=180) as r:asset=json.load(r)
            expected=hashlib.sha256(path.read_bytes()).hexdigest()
            assert asset['state']=='uploaded' and asset['size']==path.stat().st_size
            assert asset.get('digest')=='sha256:'+expected,'Uploaded asset digest mismatch'
            assets.append({'name':path.name,'sha256':expected,'size':asset['size'],'url':asset['browser_download_url']})
        release=api('PATCH','/repos/'+REPO+'/releases/'+str(release['id']),{'draft':False,'prerelease':prerelease})
        verify=api('GET','/repos/'+REPO+'/releases/tags/'+TAG)
        assert not verify['draft'] and {asset['name'] for asset in verify['assets']} == {path.name for path in paths}
        assert verify['prerelease'] is prerelease, 'GitHub release type does not match the version tag'
        status.update(success=True,release_url=verify['html_url'],assets=assets,prerelease=prerelease,
                      private=api('GET','/repos/'+REPO)['private'])
    except Exception as e:
        status.update(success=False,error=str(e));status_write(status);raise
    status_write(status);print(json.dumps(status,indent=2))
if __name__=='__main__':main()
