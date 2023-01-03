package sample;

import dn.Delayer;
import h2d.filter.Bloom;

/**
	SamplePlayer is an Entity with some extra functionalities:
	- falls with gravity
	- has basic level collisions
	- controllable (using gamepad or keyboard)
	- some squash animations, because it's cheap and they do the job
**/
class Repeater extends Entity {
	public static var ALL:Array<Repeater> = [];

	public var targets:Array<Dynamic>;
	public var delay:Float = 0;
	
	public var dl:dn.Delayer;

	var anims = dn.heaps.assets.Aseprite.getDict(hxd.Res.atlas.light);
	var isFront(get, never):Bool;

	inline function get_isFront()
		return data.f_IsFront;

	public function new(repeater:Entity_Repeater) {
		super(repeater.cx, repeater.cy);
		iid = repeater.iid;
		data = repeater;
		activated = false;
		delay = repeater.f_delay;
		targets = repeater.f_Entity_ref;

		//dl = new dn.Delayer(Const.FIXED_UPDATE_FPS);
		
		spr.set(Assets.light);
		spr.anim.registerStateAnim(anims.idle, 0);
		spr.anim.registerStateAnim(anims.on, 2, () -> activated == true);

		var g = new h2d.Graphics(spr);
		ALL.push(this);
	}

	override function dispose() {
		super.dispose();
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if (activated == true) {
			//trace("Activation du répéteur");
			activated = false;
			
			for (tar in targets) {
				for (en in Entity.ALL) {
					if (en.iid == tar.entityIid && iid!=en.iid) {
						
						game.delayer.addS('waiting_'+en.iid, () -> {
							//trace("delayed");
							en.activated = !en.activated;
							en.locked=false;
						}, delay);
						//dl.runImmediately('waiting_'+en.iid);
							
						
						
					}
				}
			}
		}
	}
}
