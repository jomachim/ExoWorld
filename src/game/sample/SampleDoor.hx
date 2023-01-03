package sample;

import h2d.filter.Bloom;

/**
	SamplePlayer is an Entity with some extra functionalities:
	- falls with gravity
	- has basic level collisions
	- controllable (using gamepad or keyboard)
	- some squash animations, because it's cheap and they do the job
**/

class SampleDoor extends Entity {
	public static var ALL : Array<SampleDoor> = [];
	var anims = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.door );
	//spublic var locked:Bool=false;
	public var requierements:Array<assets.Enum_Loots_lol>=[];
	var opened(get,never):Bool;
		inline function get_opened() return spr.anim.getAnimId()==anims.opened && locked==false;

	public function new(door) {
		super(5,5);
		data=door;
		iid=door.iid;
		// Placeholder display
		locked=door.f_locked;
		var outline=spr.filter = new dn.heaps.filter.PixelOutline(0x330000, 0.4);
		var bloom = new h2d.filter.Glow(0xeeffee,0.5,4,0.5,1,true);
		var group = new h2d.filter.Group([outline,bloom]);
		spr.filter = group;
		spr.set(Assets.door);
		
		
		//spr.anim.registerStateAnim(anims.closed, 2,()->cd.getS("recentlyTeleported")>0);
		spr.anim.registerStateAnim(anims.closed, 0);



		var g = new h2d.Graphics(spr);
		ALL.push(this);
	}


	override function dispose() {
		super.dispose();
		
	}

	override function fixedUpdate(){
		if(locked==true && game.gameStats.has(data.iid+"activated")){
			locked=false;
		}
		/*if(game.player!=null)
			if(locked==false && !game.player.ownItem(requierements)){
				locked=true;
			}*/
	}

}