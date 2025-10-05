shader_type spatial;

uniform sampler2D albedo;
uniform vec3 velocity; // our velocity
uniform float stretchAmt = 0.1f;
uniform float shrinkAmt = 0.2f;
uniform float minVelocity = 5.0f;

void vertex() {
	// going to assume the model is centered around <0,0,0> for simplicities sake, can make it a
	//  uniform later if we want to set it manually
	float velMag = length(velocity);
	float shrinkLerp = clamp( smoothstep( 0.0f, 1.0f, velMag / minVelocity ), 0.0f, 1.0f );
	
	vec3 diff = VERTEX;
	float diffDot = max(0.0, -dot(velocity / velMag, normalize(diff)));
	VERTEX += ( -velocity * diffDot * stretchAmt ) - ( VERTEX * diffDot * shrinkAmt * shrinkLerp );
}

void fragment() {
	ALBEDO = texture(albedo, UV).rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
