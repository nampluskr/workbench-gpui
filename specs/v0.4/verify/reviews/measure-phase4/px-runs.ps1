#Requires -Version 7
# P4-E V3 helper: list horizontal bands (rows with any pixel differing from the region's top-left colour by > Thr) in a PNG region.
# Usage: px-runs.ps1 -Png f.png -X0 -X1 -Y0 -Y1 [-Thr 6]   -> "y=a..b h=n x=minx..maxx" per band
param([string]$Png,[int]$X0,[int]$X1,[int]$Y0,[int]$Y1,[int]$Thr=6)
Add-Type -TypeDefinition @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Collections.Generic;
public static class PxRuns {
  public static string[] Run(string png,int x0,int x1,int y0,int y1,int thr){
    var bmp=new Bitmap(png); var d=bmp.LockBits(new Rectangle(0,0,bmp.Width,bmp.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
    var buf=new byte[d.Stride*bmp.Height]; System.Runtime.InteropServices.Marshal.Copy(d.Scan0,buf,0,buf.Length); bmp.UnlockBits(d);
    Func<int,int,int[]> px=(x,y)=>{int o=y*d.Stride+x*4;return new int[]{buf[o+2],buf[o+1],buf[o]};};
    var bg=px(x0,y0); var res=new List<string>(); res.Add("bg="+bg[0]+","+bg[1]+","+bg[2]);
    bool inb=false; int s=0,mn=0,mx=0;
    for(int y=y0;y<=y1+1;y++){
      int minx=99999,maxx=-1; bool hit=false;
      if(y<=y1) for(int x=x0;x<=x1;x++){var p=px(x,y); if(Math.Abs(p[0]-bg[0])+Math.Abs(p[1]-bg[1])+Math.Abs(p[2]-bg[2])>thr){hit=true; if(x<minx)minx=x; if(x>maxx)maxx=x;}}
      if(hit&&!inb){inb=true;s=y;mn=minx;mx=maxx;} else if(hit){if(minx<mn)mn=minx;if(maxx>mx)mx=maxx;}
      else if(!hit&&inb){inb=false;res.Add("y="+s+".."+(y-1)+" h="+(y-s)+" x="+mn+".."+mx);}
    }
    return res.ToArray();
  }
}
'@ -ReferencedAssemblies System.Drawing.Common,System.Drawing.Primitives,System.Collections,System.Runtime.InteropServices,netstandard
[PxRuns]::Run($Png,$X0,$X1,$Y0,$Y1,$Thr)
