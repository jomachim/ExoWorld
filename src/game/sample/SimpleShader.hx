package sample;

import h3d.Engine;

// --- Filter -------------------------------------------------------------------------------
class SimpleShader extends h2d.filter.Shader<InternalShader> {
	
	public function new(m:Float=1.25) {
		super(new InternalShader());
		shader.pxscale = new hxsl.Types.Vec(1.0/1280.0, 1.0/720.0);
		shader.multiplier = m; //channel decay amount default 1.25
	}
	
}
// --- Shader -------------------------------------------------------------------------------
private class InternalShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture : Sampler2D;
		@param var pxscale : Vec2;
		@param var multiplier : Float;
		
		function fragment() {
			var uv=input.uv;
			var centerX=uv.x-0.5;
			var centerY=uv.y-0.5;
			var dist=sqrt(centerX*centerX+centerY*centerY)*0.5;
			var ang=atan(centerY,centerX)*180/3.1415;
			pixelColor.r = texture.get(vec2(uv.x+pxscale.x*multiplier*dist*cos(ang/180*3.1415)*4,uv.y+pxscale.y*multiplier*dist*sin(ang/180*3.1415)*4)).r;
			pixelColor.g = texture.get(uv).g;
			pixelColor.b = texture.get(vec2(uv.x-pxscale.x*multiplier*dist*cos(ang/180*3.1415)*4,uv.y+pxscale.y*multiplier*dist*sin(ang/180*3.1415)*4)).b;
			pixelColor.rgb-= 0.0025/vec3(0.0025/dist,0.0025/dist,0.0025/dist);
		}
	};
}
