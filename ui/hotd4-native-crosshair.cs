// Reads the user's own CellSprite scene, texture crops and DDS. No game data
// is embedded here. Cache format HC01 contains evaluated, original animation.
using System;
using System.IO;
using System.Text;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Windows.Media;
using System.Windows.Media.Imaging;

public static class Hotd4NativeCrosshair
{
    sealed class Reader : BinaryReader {
        public Reader(byte[] b, int p) : base(new MemoryStream(b, false)) { BaseStream.Position=p; }
        public int Count() { int n=ReadUInt16(); if(n>4096) throw new InvalidDataException("CellSprite count out of range."); return n; }
        public string Text() { if(ReadUInt16()!=0x3e53) throw new InvalidDataException("Invalid CellSprite string."); return Encoding.ASCII.GetString(ReadBytes(Count())); }
    }
    sealed class Key { public int Type,Frame; public double Value,In,Out; }
    sealed class Curve { public bool Loop; public Key[] Keys; }
    sealed class Cast { public int Id,Parent; public float X,Y,Sx,Sy,Angle,Ox,Oy; public int[] Face; }
    sealed class Motion { public int Id; public Curve[] Curves; }
    sealed class Bank { public int Duration; public Motion[] Motions; }
    sealed class Scene { public Cast[] Casts; public Bank[] Banks; }
    sealed class Crops { public string Name; public float[][] Rects; }
    sealed class Player { public int Width,Height,Idle,Shot; public byte[] Pixels; public float[][][] Frames; }
    static Player[] players;
    static string loaded;
    static uint U(byte[] b,int p) { return BitConverter.ToUInt32(b,p); }
    static string Tag(byte[] b,int p) { return Encoding.ASCII.GetString(b,p,4); }
    static void Bounds(byte[] b,int p,int n) { if(p<0 || n<0 || p>b.Length-n) throw new InvalidDataException("Truncated crosshair resource."); }
    static Curve ReadCurve(Reader r,int kind) {
        var c=new Curve { Loop=r.ReadByte()!=0, Keys=new Key[r.Count()] };
        for(int i=0;i<c.Keys.Length;i++) c.Keys[i]=new Key { Type=r.ReadByte(),Value=kind==0?(double)r.ReadSingle():kind==1?(double)r.ReadUInt32():r.ReadInt32(),Frame=r.ReadInt32(),In=r.ReadSingle(),Out=r.ReadSingle() };
        return c;
    }
    static Scene ReadScene(byte[] b,int offset) {
        var r=new Reader(b,offset+16); if(r.Count()!=1) throw new InvalidDataException("Unsupported cursor families.");
        var s=new Scene { Casts=new Cast[r.Count()] };
        for(int i=0;i<s.Casts.Length;i++) {
            var c=new Cast { Id=r.ReadInt32(),X=r.ReadSingle(),Y=r.ReadSingle(),Sx=r.ReadSingle(),Sy=r.ReadSingle(),Angle=r.ReadSingle(),Ox=r.ReadSingle(),Oy=r.ReadSingle() };
            int[] v=new int[9]; for(int j=0;j<9;j++) v[j]=r.ReadInt32(); c.Parent=v[5]; s.Casts[i]=c;
        }
        if(r.Count()!=s.Casts.Length) throw new InvalidDataException("Cursor face count mismatch.");
        foreach(var c in s.Casts) {
            int type=r.ReadByte(); r.ReadByte(); int w=r.ReadInt32(),h=r.ReadInt32(),tex=r.ReadInt32(),crop=r.ReadInt32();
            r.ReadInt32(); r.ReadInt32(); for(int j=0;j<5;j++)r.ReadUInt32(); r.ReadInt32(); r.Text();r.Text();
            int n=r.Count(); for(int j=0;j<n;j++){r.ReadUInt16();r.ReadUInt16();}
            c.Face=new int[]{type,w,h,tex,crop};
        }
        s.Banks=new Bank[r.Count()];
        for(int i=0;i<s.Banks.Length;i++) {
            var bank=new Bank { Motions=new Motion[r.Count()], Duration=r.ReadInt32() };
            for(int j=0;j<bank.Motions.Length;j++) {
                var m=new Motion { Id=r.ReadInt32(),Curves=new Curve[15] };
                for(int k=0;k<15;k++)m.Curves[k]=ReadCurve(r,k<5?0:k==5 || (k>=8 && k<12)?1:2);
                bank.Motions[j]=m;
            }
            s.Banks[i]=bank;
        }
        if(s.Banks.Length<2 || s.Banks[0].Duration<1 || s.Banks[0].Duration>120 || s.Banks[1].Duration<1 || s.Banks[1].Duration>120) throw new InvalidDataException("Unsupported cursor timeline.");
        return s;
    }
    static double Eval(Curve c,double frame,double fallback,int component) {
        var keys=c.Keys; if(keys.Length==0)return fallback;
        if(c.Loop && keys[keys.Length-1].Frame>0)frame%=keys[keys.Length-1].Frame;
        int i=0;while(i+1<keys.Length && frame>=keys[i+1].Frame)i++;
        var a=keys[i];double v=a.Value;
        if(component>=0)v=((uint)v>>(component*8))&255;
        if(i+1==keys.Length || frame<=a.Frame)return v;
        var z=keys[i+1];double w=z.Value;if(component>=0)w=((uint)w>>(component*8))&255;
        double t=(frame-a.Frame)/(z.Frame-a.Frame);
        if(a.Type==1)return v+(w-v)*t;
        if(a.Type==2)return v;
        if(a.Type==3) { double d=z.Frame-a.Frame;return (2*t*t*t-3*t*t+1)*v+(t*t*t-2*t*t+t)*a.Out*d+(-2*t*t*t+3*t*t)*w+(t*t*t-t*t)*z.In*d; }
        throw new InvalidDataException("Unsupported cursor interpolation.");
    }
    static float[][] Pose(Scene scene,Crops[] crops,int bankNo,int frame) {
        var bank=scene.Banks[bankNo]; var result=new List<float[]>();var colors=new double[scene.Casts.Length][];
        for(int i=0;i<scene.Casts.Length;i++) {
            var c=scene.Casts[i];Motion m=Array.Find(bank.Motions,x=>x.Id==c.Id);if(m==null)throw new InvalidDataException("Missing cursor motion.");
            var rgba=new double[4];for(int j=0;j<4;j++){rgba[j]=Eval(m.Curves[5],frame,255,j)/255.0;if(c.Parent>=0)rgba[j]*=colors[c.Parent][j];} colors[i]=rgba;
            if(c.Face[0]!=2)continue;
            int parent=c.Parent;float root=1;while(parent>=0){var pc=scene.Casts[parent];var pm=Array.Find(bank.Motions,x=>x.Id==pc.Id);root*=(float)Eval(pm.Curves[3],frame,pc.Sx,-1);parent=pc.Parent;}
            float px=(float)Eval(m.Curves[0],frame,c.X,-1),py=(float)Eval(m.Curves[1],frame,c.Y,-1);
            float sx=(float)Eval(m.Curves[3],frame,c.Sx,-1),sy=(float)Eval(m.Curves[4],frame,c.Sy,-1),angle=(float)Eval(m.Curves[2],frame,c.Angle,-1)*(float)Math.PI/180;
            float[] rect=crops[c.Face[3]].Rects[c.Face[4]];float[] v=new float[17];
            for(int k=0;k<4;k++){float x=((k==1||k==2?c.Face[1]:0)-c.Ox)*sx,y=((k>=2?c.Face[2]:0)-c.Oy)*sy;v[k*2]=(px+x*(float)Math.Cos(angle)-y*(float)Math.Sin(angle))*root;v[k*2+1]=(py+x*(float)Math.Sin(angle)+y*(float)Math.Cos(angle))*root;}
            Array.Copy(rect,0,v,8,4);for(int j=0;j<4;j++)v[12+j]=(float)rgba[j];
            // The duplicate group uses CellSprite's additive blend mode.
            v[16]=c.Parent>=0 && scene.Casts[c.Parent].Parent==0 && c.Parent!=1?1:0;
            result.Add(v);
        }
        if(result.Count!=10)throw new InvalidDataException("Unsupported cursor sprite count.");return result.ToArray();
    }
    static byte[] Decode(byte[] b,out int w,out int h) {
        if(Tag(b,0)!="DDS " || Tag(b,84)!="DXT5") throw new InvalidDataException("Unsupported cursor DDS.");
        w=(int)U(b,16);h=(int)U(b,12);if(w<4||h<4||w>512||h>512)throw new InvalidDataException("Invalid cursor texture size.");
        byte[] pixels=new byte[w*h*4];int p=128;
        for(int y=0;y<h;y+=4)for(int x=0;x<w;x+=4,p+=16) {
            Bounds(b,p,16);int[] alpha=new int[8];alpha[0]=b[p];alpha[1]=b[p+1];int div=alpha[0]>alpha[1]?7:5;
            for(int i=1;i<div;i++)alpha[i+1]=((div-i)*alpha[0]+i*alpha[1])/div;if(div==5){alpha[6]=0;alpha[7]=255;}
            var col=new int[4][];for(int j=0;j<2;j++){int c=BitConverter.ToUInt16(b,p+8+j*2);col[j]=new int[]{((c>>11)*255+15)/31,(((c>>5)&63)*255+31)/63,((c&31)*255+15)/31};}
            col[2]=new int[3];col[3]=new int[3];for(int j=0;j<3;j++){col[2][j]=(2*col[0][j]+col[1][j])/3;col[3][j]=(col[0][j]+2*col[1][j])/3;}
            ulong ab=BitConverter.ToUInt64(b,p)>>16;uint cb=U(b,p+12);
            for(int i=0;i<16;i++){int px=x+i%4,py=y+i/4;if(px>=w||py>=h)continue;int dest=(py*w+px)*4;int c=(int)(cb>>(2*i)&3);for(int j=0;j<3;j++)pixels[dest+j]=(byte)col[c][j];pixels[dest+3]=(byte)alpha[(int)(ab>>(3*i)&7)];}
        }return pixels;
    }
    static Player[] Extract(byte[] b) {
        if(Tag(b,0)!="IZCA")throw new InvalidDataException("Invalid sprite bank.");int dir=(int)U(b,8)+8,table=(int)U(b,dir),count=(int)U(b,dir+4);Bounds(b,table,count*4);
        int[] offsets=new int[count];int cropsOffset=-1;var textures=new Dictionary<string,byte[]>(StringComparer.OrdinalIgnoreCase);
        for(int i=0;i<count;i++){int o=offsets[i]=(int)U(b,table+i*4);Bounds(b,o,16);if(Tag(b,o)=="HCSC")cropsOffset=o+16;}
        if(cropsOffset<0)throw new InvalidDataException("Missing sprite crops.");
        var r=new Reader(b,cropsOffset+16);var crops=new Crops[r.Count()];
        for(int i=0;i<crops.Length;i++){int n=r.Count();r.ReadInt32();var c=new Crops { Name=r.Text().Replace('\\','/'),Rects=new float[n][] };for(int j=0;j<n;j++){r.ReadInt32();c.Rects[j]=new float[]{r.ReadSingle(),r.ReadSingle(),r.ReadSingle(),r.ReadSingle()};}crops[i]=c;}
        for(int start=0;start<b.Length-16;start++)if(b[start]=='D' && b[start+1]=='D' && b[start+2]=='M' && b[start+3]==' ') {
            int names=start+8+(int)U(b,start+4);Bounds(b,names,16);if(Tag(b,names)!="DSFN")continue;
            int size=(int)U(b,names+4),n=BitConverter.ToUInt16(b,names+10),pos=names+16,chunk=names+8+size;
            for(int i=0;i<n;i++){int end=Array.IndexOf(b,(byte)0,pos);if(end<0)throw new InvalidDataException();string name=Encoding.ASCII.GetString(b,pos,end-pos).Replace('\\','/');pos=end+1;Bounds(b,chunk,16);if(Tag(b,chunk)!="DSCK")throw new InvalidDataException();int len=(int)U(b,chunk+8);Bounds(b,chunk+16,len);if(name.IndexOf("nameEntry_pointer_",StringComparison.OrdinalIgnoreCase)>=0){byte[] dds=new byte[len];Array.Copy(b,chunk+16,dds,0,len);textures[Path.GetFileName(name)]=dds;}chunk+=8+(int)U(b,chunk+4);}
            start=chunk-1;
        }
        var scenes=new Scene[2];
        foreach(int o in offsets)if(Tag(b,o)=="HCSA") {
            Scene candidate;try { candidate=ReadScene(b,o+16); } catch(InvalidDataException) { continue; }
            var cursor=Array.Find(candidate.Casts,c=>c.Face[0]==2 && c.Face[3]>=0 && c.Face[3]<crops.Length && crops[c.Face[3]].Name.IndexOf("nameEntry_pointer_",StringComparison.OrdinalIgnoreCase)>=0);
            if(cursor!=null) { string n=crops[cursor.Face[3]].Name;int pl=n.IndexOf("pointer_002",StringComparison.OrdinalIgnoreCase)>=0?1:0;scenes[pl]=candidate; }
        }
        var result=new Player[2];for(int pl=0;pl<2;pl++) {
            var scene=scenes[pl];if(scene==null)throw new InvalidDataException("Original cursor animation not found.");var face=Array.Find(scene.Casts,c=>c.Face[0]==2);string name=Path.GetFileName(crops[face.Face[3]].Name);byte[] dds;
            if(!textures.TryGetValue(name,out dds) && !textures.TryGetValue(name+".dds",out dds))throw new InvalidDataException("Missing original cursor texture: "+name);
            var p=new Player();p.Pixels=Decode(dds,out p.Width,out p.Height);p.Idle=scene.Banks[0].Duration;p.Shot=scene.Banks[1].Duration+1;p.Frames=new float[p.Idle+p.Shot][][];
            for(int i=0;i<p.Frames.Length;i++)p.Frames[i]=Pose(scene,crops,i<p.Idle?0:1,i<p.Idle?i:i-p.Idle);result[pl]=p;
        }return result;
    }
    public static bool Ensure(string app,string dump) {
        string bank=Path.Combine(dump,"fs/test/playerranking.bnk");if(!File.Exists(bank))return false;
        byte[] source=File.ReadAllBytes(bank);if(Encoding.ASCII.GetString(source).IndexOf("nameEntry_pointer_001",StringComparison.OrdinalIgnoreCase)<0)return false;
        string hash;using(var sha=SHA256.Create())hash="HC01-"+BitConverter.ToString(sha.ComputeHash(source));
        string file=Path.Combine(app,"native-crosshair.bin"),stamp=file+".sha256";
        bool rebuild=!File.Exists(file)||!File.Exists(stamp)||File.ReadAllText(stamp)!=hash;
        if(!rebuild) { try { Load(file); } catch(IOException) { rebuild=true; } }
        if(rebuild) {
            players=null;loaded=null;
            var data=Extract(source);string temp=file+"."+Guid.NewGuid().ToString("N")+".tmp";
            try { using(var w=new BinaryWriter(File.Create(temp))){w.Write(Encoding.ASCII.GetBytes("HC01"));foreach(var p in data){w.Write(p.Width);w.Write(p.Height);w.Write(p.Idle);w.Write(p.Shot);w.Write(10);w.Write(p.Pixels);foreach(var f in p.Frames)foreach(var s in f)foreach(float v in s)w.Write(v);}}if(File.Exists(file))File.Replace(temp,file,null);else File.Move(temp,file);File.WriteAllText(stamp,hash); }
            finally { if(File.Exists(temp))File.Delete(temp); }
        }
        Load(file);return true;
    }
    public static bool IsReady(string app) { try { Load(Path.Combine(app,"native-crosshair.bin"));return true; } catch(IOException) { return false; } }
    static void Load(string file) {
        if(loaded==file && players!=null)return;var result=new Player[2];using(var r=new BinaryReader(File.OpenRead(file))){if(Encoding.ASCII.GetString(r.ReadBytes(4))!="HC01")throw new InvalidDataException();for(int i=0;i<2;i++){var p=new Player { Width=r.ReadInt32(),Height=r.ReadInt32(),Idle=r.ReadInt32(),Shot=r.ReadInt32() };if(r.ReadInt32()!=10 || p.Width>512 || p.Height>512 || p.Idle>120 || p.Shot>121)throw new InvalidDataException();p.Pixels=r.ReadBytes(p.Width*p.Height*4);p.Frames=new float[p.Idle+p.Shot][][];for(int j=0;j<p.Frames.Length;j++){p.Frames[j]=new float[10][];for(int k=0;k<10;k++){var s=p.Frames[j][k]=new float[17];for(int n=0;n<17;n++)s[n]=r.ReadSingle();}}result[i]=p;}}players=result;loaded=file;
    }
    public static BitmapSource Preview(string app,int player,int tick,int size,int color) {
        Load(Path.Combine(app,"native-crosshair.bin"));var p=players[player];int f=tick%150;f=f<60?f%p.Idle:f<60+p.Shot?p.Idle+f-60:f%p.Idle;
        const int dim=256;float scale=size/100f*.8f;var dst=new float[dim*dim*4];
        byte[,] colors={{249,38,51},{45,161,255},{64,255,50},{255,225,45},{255,255,255},{40,255,255},{255,60,220},{255,140,30}};
        foreach(var s in p.Frames[f]) {
            double ax=(s[2]-s[0])*scale,ay=(s[3]-s[1])*scale,bx=(s[6]-s[0])*scale,by=(s[7]-s[1])*scale,det=ax*by-ay*bx;if(Math.Abs(det)<.001)continue;
            int loX=dim,loY=dim,hiX=0,hiY=0;for(int k=0;k<4;k++){int x=(int)(128+s[k*2]*scale),y=(int)(128+s[k*2+1]*scale);loX=Math.Min(loX,x);hiX=Math.Max(hiX,x+1);loY=Math.Min(loY,y);hiY=Math.Max(hiY,y+1);}
            for(int y=Math.Max(0,loY);y<Math.Min(dim,hiY);y++)for(int x=Math.Max(0,loX);x<Math.Min(dim,hiX);x++){
                double px=x+.5-128-s[0]*scale,py=y+.5-128-s[1]*scale,u=(px*by-py*bx)/det,v=(ax*py-ay*px)/det;if(u<0||u>=1||v<0||v>=1)continue;
                int tx=Math.Max(0,Math.Min(p.Width-1,(int)((s[8]+(s[10]-s[8])*u)*p.Width))),ty=Math.Max(0,Math.Min(p.Height-1,(int)((s[9]+(s[11]-s[9])*v)*p.Height))),src=(ty*p.Width+tx)*4,d=(y*dim+x)*4;
                float alpha=p.Pixels[src+3]/255f*s[15],keep=s[16]>0?1:1-alpha;
                for(int c=0;c<3;c++){float value=p.Pixels[src+c]/255f;if(color>0)value=Math.Max(p.Pixels[src],Math.Max(p.Pixels[src+1],p.Pixels[src+2]))/255f*colors[color-1,c]/255f;dst[d+c]=Math.Min(1,value*s[12+c]*alpha+dst[d+c]*keep);}dst[d+3]=Math.Min(1,alpha+dst[d+3]*keep);
            }
        }
        var pixels=new byte[dim*dim*4];for(int i=0;i<dim*dim;i++){pixels[i*4]=(byte)(dst[i*4+2]*255);pixels[i*4+1]=(byte)(dst[i*4+1]*255);pixels[i*4+2]=(byte)(dst[i*4]*255);pixels[i*4+3]=(byte)(dst[i*4+3]*255);}
        var image=BitmapSource.Create(dim,dim,96,96,PixelFormats.Pbgra32,null,pixels,dim*4);image.Freeze();return image;
    }
}
