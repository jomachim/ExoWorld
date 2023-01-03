package sample;

import h2d.Graphics;
import h2d.Anim;
import ase.AnimationDirection;
import h2d.col.Point;
import h2d.filter.Bloom;

/**
	SamplePlayer is an Entity with some extra functionalities:
	- falls with gravity
	- has basic level collisions
	- controllable (using gamepad or keyboard)
	- some squash animations, because it's cheap and they do the job
**/
class SampleChaine extends Entity {
	public static var ALL:Array<SampleChaine> = [];

	public var dirY:Int = -1;
	//public var activated:Bool = true;
	// public var iid:Null<String>;
	public var startY:Int = 0;
	public var endY:Int = 0;
	public var speed:Float = 0;
	public var maxSpeed:Float = 1.6;
	// public var elevator:Null<SampleElevator>;
	public var g:Graphics;
	public var entity:Null<Entity_Elevator>;
	public var childs:Array<HSprite> = [];
	public var chaine_anims = dn.heaps.assets.Aseprite.getDict(hxd.Res.atlas.chaine);
	public var animated:Bool = false;

	var elevator(get, never):Null<SampleElevator>;

	inline function get_elevator()
		return SampleElevator.ALL.filter((e) -> e.iid == entity.iid)[0];

	public function new(ent:Entity_Elevator) {
		entity = ent;
		super(ent.cx, ent.cy);
		ALL.push(this);
		// elevator=SampleElevator.ALL.filter((e)->e.iid==ent.iid)[0];

		iid = ent.iid;
		startY = M.floor(Math.min(ent.f_startPoint.cy, ent.f_endPoint.cy));
		endY = M.floor(Math.max(ent.f_startPoint.cy, ent.f_endPoint.cy));
		setPosCase(ent.cx, startY - 1);

		// Placeholder display

		var outline = spr.filter = new dn.heaps.filter.PixelOutline(0x330000, 0.4);
		var bloom = new h2d.filter.Glow(0xeeffee, 0.5, 4, 0.5, 1, true);
		var group = new h2d.filter.Group([outline, bloom]);
		spr.filter = group;
		spr.set(Assets.chaine);
		
		//spr.anim.registerStateAnim(chaine_anims.stop, 2, 0, () -> elevator.activated == false);
		g = new h2d.Graphics(spr);
		//cd.setMs("anim_chaine", 200);
		var py = startY - 1;
		childs = [];
		while (py < (endY - 1)) {
			py += 1;
			var chaine_spr = new HSprite(spr);
			// var chaine_anims=dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.chaine );
			chaine_spr.set(Assets.chaine);
			chaine_spr.x+=M.frandRange(-0.4,0.4);
			chaine_spr.setScale(0.5);
			// chaine_spr.anim.play('idle',);
			/*chaine_spr.anim.registerStateAnim(chaine_anims.idle, 0,0);*/
			// chaine_spr.anim.registerStateAnim(chaine_anims.idle, 4,30,()->elevator.activated==true && elevator.dirY<0);
			chaine_spr.anim.registerStateAnim(chaine_anims.idle, 2, 60, () -> elevator.activated == true); // chaine_spr.anim.setSpeed(elevator.speed*10);
			chaine_spr.anim.registerStateAnim(chaine_anims.stop, 3, 0, () -> elevator.activated == false);
			chaine_spr.y = py * 8 - (startY - 1) * 8;
			
			// chaine_spr.localToGlobal(new Point(0,startY*16));
			g.addChild(new h2d.Graphics(chaine_spr));
			Game.ME.scroller.under(chaine_spr);
			// spr.addChild(chaine_spr);
			childs.push(chaine_spr);
		}
	}

	override function dispose() {
		super.dispose();
		for(c in childs){
			c.remove();
		}
	}

	override function preUpdate() {
		super.preUpdate();
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if (elevator != null) {
			if (elevator.activated == false)
				animated = false;

			if (elevator.activated == true && animated == false) { // !cd.has('anim_chaine')
				animated = true;
				for (ch in childs) {
					// elevator.activated=false;
					// cd.setMs("anim_chaine", 100);
					
					// if (ch.anim.isPlaying(chaine_anims.idle)) {
					if (elevator.dirY < 0) {
						//ch.anim.play(chaine_anims.idle).setSpeed(60);
						ch.anim.reverse();
					} else {
						//ch.anim.play(chaine_anims.idle).setSpeed(60);
						//ch.anim.reverse();
					}
					// }
				}
			}
		}
	}
}
