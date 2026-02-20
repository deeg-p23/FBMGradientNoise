#ifndef BLINNPHONG_INCLUDED
#define BLINNPHONG_INCLUDED

void BlinnPhong_float(float3 lightDir, float distance, float3 lightColor, float lightPower, float3 normal, float3 fragPos, float3 in_color, out float4 out_color)
{
    float lambertian = max(dot(lightDir, normal), 0.0);
    float specular = 0.0;

    float3 diffuseColor = in_color;
    float3 ambientColor = in_color / 5.;
    float3 specularColor = float3(1.,1.,1.);
    float shininess = 16.;
    int mode = 1;
    float screenGamma = 2.2;
    
    if (lambertian > 0.0) {

        float3 viewDir = normalize(-fragPos);

        // this is blinn phong
        float3 halfDir = normalize(lightDir + viewDir);
        float specAngle = max(dot(halfDir, normal), 0.0);
        specular = pow(specAngle, shininess);
       
        // this is phong (for comparison)
        if (mode == 2) {
            float3 reflectDir = reflect(-lightDir, normal);
            specAngle = max(dot(reflectDir, viewDir), 0.0);
            // note that the exponent is different here
            specular = pow(specAngle, shininess/4.0);
        }
    }
    float3 colorLinear = ambientColor +
                       diffuseColor * lambertian * lightColor * lightPower / distance +
                       specularColor * specular * lightColor * lightPower / distance;
    // apply gamma correction (assume ambientColor, diffuseColor and specColor
    // have been linearized, i.e. have no gamma correction in them)
    float3 correction = pow(colorLinear, 1. / screenGamma);
    float3 colorGammaCorrected = float3(correction);
    // use the gamma corrected color in the fragment
    out_color = float4(colorGammaCorrected, 1.0);
}

#endif