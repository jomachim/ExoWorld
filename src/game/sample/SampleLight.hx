package sample;

import h2d.filter.Bloom;

/**
	SamplePlayer is an Entity with some extra functionalities:
	- falls with gravity
	- has basic level collisions
	- controllable (using gamepad or keyboard)
	- some squash animations, because it's cheap and they do the job
**/

class SampleLight extends Entity {
	public static var ALL : Array<SampleLight> = []; 
	public var colors:Array<Int>;
	public var color:Int;
	public var groupa:h2d.filter.Group;
	public var groupb:h2d.filter.Group;
	public var bloom :h2d.filter.Bloom;
	public var glow : h2d.filter.Glow;
	var anims = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.light );
	var isFront(get,never):Bool;
		inline function get_isFront() return data.f_IsFront;
	public function new(light:Entity_Light) {
		super(light.cx,light.cy);
		colors=[for (i in 0...light.f_Color_int.length) light.f_Color_int[i]];
		color=colors[1];
		iid=light.iid;
		//trace(colors);
		// Placeholder display
		data=light;
		activated=light.f_Activated;
		//color=light.f_Color_int;
		var outline=spr.filter = new dn.heaps.filter.PixelOutline(0x330000, 0.4);
		glow = new h2d.filter.Glow( colors[0],0.9,256,1.2,0.5,true);
		bloom=new h2d.filter.Bloom(2,2,64,1,1);
		groupa = new h2d.filter.Group([outline,glow,bloom]);
		groupb = new h2d.filter.Group([outline,glow,bloom]);//,game.disp,bloom
		spr.filter =activated?groupb:groupa;
		spr.set(Assets.light);
		spr.anim.registerStateAnim(anims.idle, 0);
		spr.anim.registerStateAnim(anims.on, 2,()->activated==true);
		
		//spr.anim.registerStateAnim(anims.closed, 2,()->cd.getS("recentlyTeleported")>0);
		//spr.anim.registerStateAnim(anims.closed, 0,2,()->!looted);
		//spr.anim.registerStateAnim(anims.opened, 10,2,()->looted);


		var g = new h2d.Graphics(spr);
		SampleLight.ALL.push(this);
	}


	override function dispose() {
		super.dispose();
		
	}

	override function fixedUpdate(){
		super.fixedUpdate();
		//debug(color,color);
		spr.filter =activated?groupb:groupa;

		if (activated) fx.lumiere(spr.x,spr.y,glow.color,isFront,1);
		if(!cd.has("changeColor"))
			glow.color=colors[M.randRange(0,colors.length-1)];
			cd.setMs("changeColor",M.rand(5000));
		
		
	}

}