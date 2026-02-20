Shader "Unlit/SimplexNoise"
{
    Properties
    {
        _Scale ("Scale", Float) = 1.
        _Speed ("Speed", Float) = 1.
        _Offset ("Offset", Float) = 3.
        _Mode ("Noise Mode", Integer) = 1
        _Value ("Noise Value", Float) = .5
        _Sharpness ("Noise Sharpness", Float) = 1.
        _Octaves ("fBM Octaves", Integer) = 1.
        _Amplitude ("fBM Amplitude", Float) = 1.
        _Frequency ("fBM Frequency", Float) = 1.
        _Persistence ("fBM Persistence", Float) = .05
        _Lacunarity ("fBM Lacunarity", Float) = 2000.
        _FrontColor ("Front Face Color", Color) = (0.8,0.,0.,1.)
        _BackColor ("Back Face Color", Color) = (0.2,0.,0.,1.)
        _CullingFalse ("Split Colors by Front/Back Faces", Integer) = 1
        _OpacityIsNoise ("Set Opacity to Noise", Integer) = 1
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" }
        Cull False
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma multi_compile _ CULL_FRONT
            
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            #define TAU 6.283185307179586

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            float _Scale;
            float _Speed;
            float _Offset;
            int _Mode;
            int _CullingFalse;
            
            float _Value;
            float _Sharpness;
            
            int _Octaves;
            float _Amplitude;
            float _Frequency;
            float _Persistence;
            float _Lacunarity;

            float4 _FrontColor;
            float4 _BackColor;

            int _OpacityIsNoise;
            
            // helper: pseudo-random gradient generator
            float3 grad(float3 p) {
                float3 a = frac(p.xyz * float3(123.34, 234.34, 345.65));
                a += dot(a, a + 34.45);
                p = frac(float3(a.x * a.y, a.y * a.z, a.z * a.x));
                float angle = p.x * TAU * _Offset + p.x * TAU * _Time * _Speed;
                return float3(cos(angle)*sin(angle),sin(angle)*sin(angle),cos(angle));
            }

            float3 rgb2hsl(float3 rgb) {
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
            
            float h2rgb(float3 hue) {
                if (hue.z < 0.) hue.z += 1.;
                if (hue.z > 1.) hue.z -= 1.;
                if (hue.z < 1./6.) return hue.x + (hue.y - hue.x) * 6. * hue.z;
                if (hue.z < .5) return hue.y;
                if (hue.z < 2./3.) return hue.x + (hue.y - hue.x) * (2./3. - hue.z) * 6.;
                return hue.x;
            }

            float3 hsl2rgb(float3 hsl) {
                float3 rgb = float3(0.,0.,0.);
                
                if (hsl.y == 0.) {
                    rgb = float3(hsl.z,hsl.z,hsl.z);
                } else {
                    float q = hsl.z < 0.5 ? hsl.z * (1. + hsl.y) : hsl.z + hsl.y - hsl.z * hsl.y;
                    float p = 2. * hsl.z - q;
                    float3 r = float3(p, q, hsl.x + 1./3.);
                    float3 g = float3(p,q,hsl.x);
                    float3 b = float3(p,q,hsl.x-1./3.);
                    rgb = float3(h2rgb(r),h2rgb(g),h2rgb(b));
                }
                return rgb;
            }

            float linear_color(float a, float b, float t)
            {
                return a * (1. - t) + b * t;
            }
            
            float3 color_interp(float3 a, float3 b, float t)
            {
                float3 ca = rgb2hsl(a);
                float3 cb = rgb2hsl(b);
                float3 c;

                c.x = linear_color(ca.x, cb.x, t);
                c.y = linear_color(ca.y, cb.y, t);
                c.z = linear_color(ca.z, cb.z, t);

                return hsl2rgb(c);
            }
            
            float dot3(float3 g, float3 f)
            {
                return g.x*f.x + g.y*f.y + g.z*f.z;
            }
            
            float contrib(float t, float3 g, float x, float y, float z)
            {
                t *= t;
                return t*t*dot3(g, float3(x,y,z));
            }
            
            int fastfloor(float x)
            {
                return (x>0.) ? int(x) : int(x-1.);
            }
            
            float evaluate_noise(float3 uvw)
            {
                switch (_Mode)
                {
                    case 0: // PERLIN NOISE
                        return 0.;
                    case 1: // SIMPLEX NOISE
                        // transform points to simplex space via skewing
                        float skew = (uvw.x+uvw.y+uvw.z)/3.;
                        int i = fastfloor(uvw.x+skew);
                        int j = fastfloor(uvw.y+skew);
                        int k = fastfloor(uvw.z+skew);
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
                        float3 g0 = grad(ijk);
                        float3 g1 = grad(ijk+ijk1);
                        float3 g2 = grad(ijk+ijk2);
                        float3 g3 = grad(ijk+float3(1.,1.,1.));
                    
                        // determine contributions from each corner to point
                        float t0 = .6-x0*x0-y0*y0-z0*z0;
                        float c0 = (t0 < 0.) ? 0. : contrib(t0,g0,x0,y0,z0);
                        float t1 = .6-x1*x1-y1*y1-z1*z1;
                        float c1 = (t1 < 0.) ? 0. : contrib(t1,g1,x1,y1,z1);
                        float t2 = .6-x2*x2-y2*y2-z2*z2;
                        float c2 = (t2 < 0.) ? 0. : contrib(t2,g2,x2,y2,z2);
                        float t3 = .6-x3*x3-y3*y3-z3*z3;
                        float c3 = (t3 < 0.) ? 0. : contrib(t3,g3,x3,y3,z3);
                        
                        return 32. * (c0+c1+c2+c3);
                    default:
                        return 0.;
                }

            }
            
            float generate_noise(float3 uvw)
            {
                float n = 0.;

                for (int i = 0 ; i < _Octaves ; i++)
                {
                    uvw *= _Frequency;
                    n += _Amplitude*evaluate_noise(uvw);
                    _Amplitude *= _Persistence;
                    _Frequency *= _Lacunarity;
                }
                    
                return _Value+_Value*n/_Sharpness;;
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                // o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 uvw = i.worldPos * _Scale;
                float3 col = float3(0.,0.,0.);
                
                // generate fBM noise
                float n = generate_noise(uvw);
                // n = (n < 0.5) ? n : 0.;  // splotches on opacity-based noise?

                
                // n = _Value+_Value*n/_Sharpness;
                n = min(n,1.);
                n = max(n,0.);


                n = (n > 0.25) ? n : 0.;
                n = (n < 0.75) ? n : 1.;
                
                float3 objectPos = unity_ObjectToWorld._m03_m13_m23;


                if (_OpacityIsNoise)
                {
                    float objectDiff = length(i.worldPos-_WorldSpaceCameraPos);
                    float fragDiff = length(objectPos-_WorldSpaceCameraPos);
                
                    if (_CullingFalse)
                    {
                        col = (fragDiff>objectDiff) ? _FrontColor.xyz : _BackColor.xyz;
                    }
                    else
                    {
                        col = _FrontColor.xyz;
                    }
                    
                    return float4(col,n);
                }
                else
                {
                    col = color_interp(_BackColor.xyz, _FrontColor.xyz, n);
                    return float4(col,1.);
                }
            }

            ENDHLSL
        }
    }
}
