package sample;

import h2d.filter.Bloom;
import hxd.res.Sound;
/**
	SamplePlayer is an Entity with some extra functionalities:
	- falls with gravity
	- has basic level collisions
	- controllable (using gamepad or keyboard)
	- some squash animations, because it's cheap and they do the job
**/

class Boom extends Entity {
	public static var ALL : Array<SampleLight> = []; 
	public var colors:Array<Int>;
	public var color:Int;
	public var groupa:h2d.filter.Group;
	public var groupb:h2d.filter.Group;
	public var bloom :h2d.filter.Bloom;
	public var glow : h2d.filter.Glow;
	public var booms:Sound=null;
	var anims = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.boom );
	var isFront(get,never):Bool;
		inline function get_isFront() return data.f_IsFront;
	public function new(boom:Entity_Boom) {
		super(boom.cx,boom.cy);
		iid=boom.iid;
		data=boom;
		activated=false;
		spr.set(Assets.boom);
		spr.anim.registerStateAnim(anims.off, 1,1,()->activated==false);
		spr.anim.registerStateAnim(anims.boom, 0,1,()->activated==true);
		var g = new h2d.Graphics(spr);
		if (hxd.res.Sound.supportedFormat(OggVorbis)) {
			booms = hxd.Res.sounds.boom;
		}
		if (hxd.res.Sound.supportedFormat(Mp3)) {
			booms = hxd.Res.sounds.boom;
		}
		
	}


	override function dispose() {
		super.dispose();
		
	}
	
	override function fixedUpdate(){
		super.fixedUpdate();
		if(activated==true && !cd.has("wait")){
			cd.setS('wait',1);
			booms.play(false).volume=0.5;
			if (spr.anim.isPlaying("boom"))
				spr.anim.chain("off");
			if (spr.anim.isPlaying("off"))
				spr.anim.cancelLoop();
				activated=false;
		}
	}

}