#ifndef SIMPLEXNOISE_INCLUDED
#define SIMPLEXNOISE_INCLUDED

#define TAU 6.283185307179586

float3 GetGradient(float3 p, float o, float s) {
    float3 a = frac(p.xyz * float3(123.34, 234.34, 345.65));
    a += dot(a, a + 34.45);
    p = frac(float3(a.x * a.y, a.y * a.z, a.z * a.x));
    float angle = p.x * TAU * o + p.x * TAU * s;
    return float3(cos(angle)*sin(angle),sin(angle)*sin(angle),cos(angle));
}

float3 RGB2HSL(float3 rgb) {
  float vmax = max(max(rgb.x,rgb.y),rgb.z);
  float vmin = min(min(rgb.x,rgb.y),rgb.z);

  float v = (vmax + vmin) / 2.;
  float3 hsl = float3(v,v,v);
  if (vmax == vmin) return float3(0.,0.,v);

  float d = vmax-vmin;
  hsl.y = hsl.z > .5 ? d / (2.-vmax-vmin) : d / (vmax+vmin);
  if (vmax == rgb.x) hsl.x = (rgb.y - rgb.z) / d + (rgb.y < rgb.z ? 6. : 0.);
  if (vmax == rgb.y) hsl.x = (rgb.z - rgb.x) / d + 2.;
  if (vmax == rgb.z) hsl.x = (rgb.x - rgb.y) / d + 4.;
  hsl.x /= 6.;

  return hsl;
}

float H2RGB(float3 hue) {
    if (hue.z < 0.) hue.z += 1.;
    if (hue.z > 1.) hue.z -= 1.;
    if (hue.z < 1./6.) return hue.x + (hue.y - hue.x) * 6. * hue.z;
    if (hue.z < .5) return hue.y;
    if (hue.z < 2./3.) return hue.x + (hue.y - hue.x) * (2./3. - hue.z) * 6.;
    return hue.x;
}

float3 HSL2RGB(float3 hsl) {
    float3 rgb = float3(0.,0.,0.);
    
    if (hsl.y == 0.) {
        rgb = float3(hsl.z,hsl.z,hsl.z);
    } else {
        float q = hsl.z < 0.5 ? hsl.z * (1. + hsl.y) : hsl.z + hsl.y - hsl.z * hsl.y;
        float p = 2. * hsl.z - q;
        float3 r = float3(p, q, hsl.x + 1./3.);
        float3 g = float3(p,q,hsl.x);
        float3 b = float3(p,q,hsl.x-1./3.);
        rgb = float3(H2RGB(r),H2RGB(g),H2RGB(b));
    }
    return rgb;
}

float LinearColor(float a, float b, float t)
{
    return a * (1. - t) + b * t;
}

float3 ColorInterpolate(float3 a, float3 b, float t)
{
    float3 ca = RGB2HSL(a);
    float3 cb = RGB2HSL(b);
    float3 c;

    c.x = LinearColor(ca.x, cb.x, t);
    c.y = LinearColor(ca.y, cb.y, t);
    c.z = LinearColor(ca.z, cb.z, t);

    return HSL2RGB(c);
}

float Dot3(float3 g, float3 f)
{
    return g.x*f.x + g.y*f.y + g.z*f.z;
}

float Contribute(float t, float3 g, float x, float y, float z)
{
    t *= t;
    return t*t*Dot3(g, float3(x,y,z));
}

int FastFloor(float x)
{
    return (x>0.) ? int(x) : int(x-1.);
}

float EvaluateNoise(float3 uvw, float offset, float speed)
{
    int mode = 1;
    
    switch (mode)
    {
        case 0: // PERLIN NOISE
            return 0.;
        case 1: // SIMPLEX NOISE
            // transform points to simplex space via skewing
            float skew = (uvw.x+uvw.y+uvw.z)/3.;
            int i = FastFloor(uvw.x+skew);
            int j = FastFloor(uvw.y+skew);
            int k = FastFloor(uvw.z+skew);
            float3 ijk = float3(float(i),float(j),float(k));
        
            // get first simplex corner distances via unskewing
            float unskew = (ijk.x+ijk.y+ijk.z)/6.;
            float x0 = uvw.x-(ijk.x-unskew);
            float y0 = uvw.y-(ijk.y-unskew);
            float z0 = uvw.z-(ijk.z-unskew);
        
            // determine other corner indices
            int i1,j1,k1,i2,j2,k2;
            if (x0>=y0)
            {
                if (y0>=z0) { i1=1; j1=0; k1=0; i2=1; j2=1; k2=0; }
                else if (x0>=z0) { i1=1; j1=0; k1=0; i2=1; j2=0; k2=1; }
                else { i1=0; j1=0; k1=1; i2=1; j2=0; k2=1; }
            }
            else
            {
                if (y0<z0) { i1=0; j1=0; k1=1; i2=0; j2=1; k2=1; }
                else if (x0<z0) { i1=0; j1=1; k1=0; i2=0; j2=1; k2=1; }
                else { i1=0; j1=1; k1=0; i2=1; j2=1; k2=0; }
            }
            float3 ijk1 = float3(float(i1),float(j1),float(k1));
            float3 ijk2 = float3(float(i2),float(j2),float(k2));
        
            // determine other corner distances
            float x1 = x0-ijk1.x+(1./6.);
            float y1 = y0-ijk1.y+(1./6.);
            float z1 = z0-ijk1.z+(1./6.);
            float x2 = x0-ijk2.x+(1./3.);
            float y2 = y0-ijk2.y+(1./3.);
            float z2 = z0-ijk2.z+(1./3.);
            float x3 = x0-.5;
            float y3 = y0-.5;
            float z3 = z0-.5;
        
            // get gradients per simplex corner
            float3 g0 = GetGradient(ijk, offset, speed);
            float3 g1 = GetGradient(ijk+ijk1, offset, speed);
            float3 g2 = GetGradient(ijk+ijk2, offset, speed);
            float3 g3 = GetGradient(ijk+float3(1.,1.,1.), offset, speed);
        
            // determine contributions from each corner to point
            float t0 = .6-x0*x0-y0*y0-z0*z0;
            float c0 = (t0 < 0.) ? 0. : Contribute(t0,g0,x0,y0,z0);
            float t1 = .6-x1*x1-y1*y1-z1*z1;
            float c1 = (t1 < 0.) ? 0. : Contribute(t1,g1,x1,y1,z1);
            float t2 = .6-x2*x2-y2*y2-z2*z2;
            float c2 = (t2 < 0.) ? 0. : Contribute(t2,g2,x2,y2,z2);
            float t3 = .6-x3*x3-y3*y3-z3*z3;
            float c3 = (t3 < 0.) ? 0. : Contribute(t3,g3,x3,y3,z3);
            
            return 32. * (c0+c1+c2+c3);
        default:
            return 0.;
    }
}

void GenerateNoise_float
    (float3 uvw,
    float octaves, float frequency, float amplitude, float persistence, float lacunarity,
    float offset, float speed, float value, float sharpness,
    out float n)
{
    n = 0.;
    for (int i = 0 ; i < octaves ; i++)
    {
        uvw *= frequency;
        n += amplitude*EvaluateNoise(uvw, offset, speed);
        amplitude *= persistence;
        frequency *= lacunarity;
    }
    n = value+value*n/sharpness;
}

#endif