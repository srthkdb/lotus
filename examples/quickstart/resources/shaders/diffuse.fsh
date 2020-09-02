#version 450 core

#define MAX_DIR_LIGHTS 10
#define MAX_POINT_LIGHTS 10
#define MAX_SPOT_LIGHTS 10

in vec3 fragPos;
in vec2 texCoords;
in vec3 normal;

struct Material {
    // diffuse == ambient here
    sampler2D texture_diffuse1;
    vec3 diffuseColor;

    sampler2D texture_specular1;
    vec3 specularColor;
    
    float shininess;
};

struct DirectionalLight {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    vec3 direction;
};

struct Spotlight {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    vec3 position;
    vec3 direction;

    float innerCutOff;
    float outerCutOff;
    float constant;
    float linear;
    float quadratic;
};

struct PointLight {
    vec3 position;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    float constant;
    float linear;
    float quadratic;
};

uniform DirectionalLight dirLight[MAX_DIR_LIGHTS];
uniform Spotlight spotlight[MAX_SPOT_LIGHTS];
uniform PointLight pointLight[MAX_POINT_LIGHTS];

uniform int numDirLight;
uniform int numSpotlight;
uniform int numPointLight;

uniform vec3 viewPos;

uniform Material material;
uniform bool readDiffuseTexture;
uniform bool readSpecularTexture;

out vec4 fragColor;

// functions
vec3 calculateDirectionalLight(DirectionalLight light, vec3 normal, vec3 viewDir);
vec3 calculatePointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir);
vec3 calculateSpotLight(Spotlight light, vec3 normal, vec3 fragPos, vec3 viewDir);

vec3 getDiffuseColor();
vec3 getSpecularColor();

void main()
{
    vec3 norm = normalize(normal);
    vec3 viewDir = normalize(fragPos - viewPos);
    vec3 result = vec3(0.0f);

    for (uint i = 0; i < numDirLight; i++) {
        result += calculateDirectionalLight(dirLight[i], norm, viewDir);
    }

    for (uint i = 0; i < numPointLight; i++) {
        result += calculatePointLight(pointLight[i], norm, fragPos, viewDir);
    }

    for (uint i = 0; i < numSpotlight; i++) {
        result += calculateSpotLight(spotlight[i], norm, fragPos, viewDir);
    }

    fragColor = vec4(result, 1.0f);
}

vec3 getDiffuseColor()
{
    if (readDiffuseTexture)
    {
        return vec3(texture(material.texture_diffuse1, texCoords));
    }
    else
    {
        return material.diffuseColor;
    }
}

vec3 getSpecularColor()
{
    if (readSpecularTexture) 
    {
        return vec3(texture(material.texture_specular1, texCoords));
    }
    else 
    {
        return material.specularColor;
    }
}

vec3 calculateDirectionalLight(DirectionalLight light, vec3 normal, vec3 viewDir) {
    vec3 diffuseColor = getDiffuseColor();
    vec3 ambient = light.ambient * diffuseColor;

    // diffuse
    vec3 lightDir = normalize(light.direction);
    float diff = max(dot(normal, -lightDir), 0.0f);
    vec3 diffuse = light.diffuse * diff * diffuseColor;

    // specular
    vec3 reflectDir = reflect(lightDir, normal);
    vec3 halfwayDir = normalize(-lightDir - viewDir);
    float spec = pow(max(dot(normal, halfwayDir), 0.0f), material.shininess);
    vec3 specular = light.specular * spec * getSpecularColor();

    return (ambient + diffuse + specular);
}

vec3 calculatePointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir) {
    float distance = length(light.position - fragPos);
    float linear = light.linear * distance;
    float quadratic = light.quadratic * distance * distance;
    float attenuation = 1.0f / (light.constant + linear + quadratic);

    vec3 diffuseColor = getDiffuseColor();
    vec3 ambient = light.ambient * diffuseColor * attenuation;

    // diffuse lighting calculations
    vec3 lightDir = normalize(fragPos - light.position);
    float diff = max(dot(normal, -lightDir), 0.0f);
    vec3 diffuse = light.diffuse * diff * diffuseColor * attenuation;

    // Specular lighting calculations
    vec3 reflectDir = reflect(lightDir, normal);
    vec3 halfwayDir = normalize(-lightDir - viewDir);
    float spec = pow(max(dot(normal, halfwayDir), 0.0f), material.shininess);
    vec3 specular = light.specular * spec * getSpecularColor() * attenuation;
    return (ambient + diffuse + specular);
}

vec3 calculateSpotLight(Spotlight light, vec3 normal, vec3 fragPos, vec3 viewDir) {
    vec3 lightToFragVec = normalize(fragPos - light.position);
    vec3 lightDir = normalize(light.direction);
    float cos = dot(lightToFragVec, lightDir);
    float diffCos = light.innerCutOff - light.outerCutOff;
    float intensity = clamp((cos - light.outerCutOff) / diffCos, 0.0, 1.0);

    float distance = length(light.position - fragPos);
    float linear = light.linear * distance;
    float quadratic = light.quadratic * distance * distance;
    float attenuation = 1.0f / (light.constant + linear + quadratic);

    vec3 diffuseColor = getDiffuseColor();
    vec3 ambient = light.ambient * diffuseColor * attenuation;

    // diffuse lighting calculations
    float diff = max(dot(normal, -lightToFragVec), 0.0f);
    vec3 diffuse = light.diffuse * diff * diffuseColor * attenuation;

    // Specular lighting calculations
    vec3 reflectDir = reflect(lightToFragVec, normal);
    vec3 halfwayDir = normalize(-lightDir - viewDir);
    float spec = pow(max(dot(normal, halfwayDir), 0.0f), material.shininess);
    vec3 specular = light.specular * spec * getSpecularColor() * attenuation;

    return (ambient + diffuse * intensity + specular * intensity);
}
