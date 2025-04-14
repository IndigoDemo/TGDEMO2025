#define PI acos(-1.)
#define TAU (2.0*PI)

uniform float iTime;      
uniform vec2 iResolution; 
uniform sampler2D iChannel0; 
uniform float brightness = 1.0;        
uniform vec3 baseColor = vec3(1.0, 0.8, 0.6); 
uniform float beatSpeed = 4.0;       
varying vec2 fragCoord;
float snd = 0.0;
float iAmplifiedTime = 0.0;
#define TIME        iAmplifiedTime
#define RESOLUTION  iResolution
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

#define VARIANT
#define SNDVARIANT

#define aTime 128.0/60.0*iAmplifiedTime

mat2 g_rot;
float g_scale;


float getBeatValue() {
    return texture2D(iChannel0, vec2(0.5, 0.0)).r;
}

mat2 rotM(float r) {
    float c = cos(r), s = sin(r);
    return mat2(c, s, -s, c);
}


vec3 aces_approx(vec3 v) {
    v = max(v, 0.0);
    float beatBoost = 1.0 + getBeatValue() * 2.0; 
    v *= 0.6 * brightness * beatBoost;
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((v*(a*v+b))/(v*(c*v+d)+e), 0.0, 1.0);
}

vec3 offset(float t) {
    t *= 0.25;
    return 0.2*vec3(sin(TAU*t), sin(0.5*t*TAU), cos(TAU*t));
}

vec3 doffset(float t) {
    const float dt = 0.01;
    return (offset(t+dt)-offset(t-dt))/(2.0*dt);
}


float pmin(float a, float b, float k) {
    float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
    return mix(b, a, h) - k*h*(1.0-h);
}

float pmax(float a, float b, float k) {
    return -pmin(-a, -b, k);
}

vec3 palette(float a) {
    return (1.0+sin(vec3(0.0,1.0,2.0)+a)) * baseColor;
}

float apollonian(vec4 p, float s, float w, out float off) {
    float scale = 1.0;

    for(int i=0; i<6; i++) {
        p = -1.0 + 2.0*fract(0.5*p+0.5);
        float r2 = dot(p,p);
        float k = s/r2;
        p *= k;
        scale *= k;
    }
    
    vec4 sp = p/scale;
    vec4 ap = abs(sp)-w;
    float d = pmax(ap.w, ap.y, w*10.0);
    
#ifdef VARIANT
    off = length(sp.xz);
#else
    d = min(d, pmax(ap.x, ap.z, w*10.0));
    off = length(sp.xy);
#endif

    return d;
}

float df(vec3 p, float w, out float off) {
    vec4 p4 = vec4(p, 0.1);
    p4.yw *= g_rot;
    p4.zw *= transpose(g_rot);
    return apollonian(p4, g_scale, w, off);
}

vec3 glowmarch(vec3 col, vec3 ro, vec3 rd, float tinit) {
    float t = tinit;
    for (int i = 0; i < 60; ++i) {
        vec3 p = ro + rd*t;
        float off;
        float d = df(p, 6.0E-5+t*t*2.0E-3, off);
        
        
        d *= 0.3;
        
       
        float beatBoost = 1.0 + getBeatValue() * 5.0; 
        float glowStrength = 1.0E-9 * beatBoost;
        
        vec3 gcol = glowStrength * (palette((log(off)))+5.0E-2)/max(d*d, 1.0E-8);
        col += gcol*smoothstep(0.5, 0.0, t);
        t += 0.5*max(d, 1.0E-4);
        
        if (t > 0.5) break;
    }
    
    float beatValue = getBeatValue();
    col *= 1.0 + beatValue * 2.0;
    
    return col;
}

vec2 getPlane(vec2 p) {
    return p;
}

vec3 render(vec3 col, vec3 ro, vec3 rd) {
    col = glowmarch(col, ro, rd, 1.0E-2);
    return col;
}

vec3 effect(vec2 p, vec2 pp, vec2 q) {
    float tm = mod(TIME+50.0, 1600.0);
    g_scale = mix(1.85, 1.5, 0.5-0.5*cos(TAU*tm/1600.0));
    g_rot = ROT(tm*TAU/800.0);
    tm *= 0.025;
    vec3 ro = offset(tm);
    vec3 dro = doffset(tm);
    vec3 ww = normalize(dro);
    vec3 uu = normalize(cross(vec3(0.0, 1.0, 0.0), ww));
    vec3 vv = cross(ww, uu);
    vec3 rd = normalize(-p.x*uu + p.y*vv + 2.0*ww);

    vec3 col = vec3(0.0);
    col += 1.0E-1*palette(5.0+0.1*p.y)/max(1.125-q.y+0.1*p.x*p.x, 1.0E-1); 
    col = render(col, ro, rd); 
    col *= smoothstep(1.707, 0.707, length(pp))*(0.1+snd);
    col -= vec3(2.0, 3.0, 1.0)*4.0E-2*(0.25+dot(pp,pp));
    col = aces_approx(col);
    col = sqrt(col);
    return col;
}

vec3 postProcess(vec3 col, vec2 q) {
    col = clamp(col, 0.0, 1.0);
    col = pow(col, vec3(1.0/2.2));
    col = col*0.6+0.4*col*col*(3.0-2.0*col);
    col = mix(col, vec3(dot(col, vec3(0.33))), -0.4);
    col *= 0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.7);
    return col;
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
   
    snd = getBeatValue();
    
   
    float timeScale = 1.0 + snd * beatSpeed; 
    iAmplifiedTime = iTime * timeScale;
    
    vec2 q = screen_coords/iResolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    vec2 pp = p;
    p.x *= iResolution.x/iResolution.y; 
    
    vec3 col = effect(p, pp, q);
    
    return vec4(col, 1.0);
}