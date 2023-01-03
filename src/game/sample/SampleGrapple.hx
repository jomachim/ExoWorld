package sample;

import hxd.res.Sound;
import ui.Hud;
import h2d.filter.Bloom;

/**
	SamplePlayer is an Entity with some extra functionalities:
	- falls with gravity
	- has basic level collisions
	- controllable (using gamepad or keyboard)
	- some squash animations, because it's cheap and they do the job
**/
class SampleGrapple extends Entity {
	public static var ALL : Array<SampleGrapple> = [];
	var anims = dn.heaps.assets.Aseprite.getDict(hxd.Res.atlas.lazer);
	var goodRessource:Sound = null;
	var wrongRessource:Sound = null;
	var ready(get, never):Bool;
	public var ang:Float=45.0;
	inline function get_ready()
		return spr.anim.getAnimId() == anims.idle;

	public function new(ent:Entity,angle:Float) {
		
		super(ent.cx, ent.cy);
		setPosCase(ent.cx, ent.cy);
		// Placeholder display
		ang=angle;
		data = ent;
		var outline = spr.filter = new dn.heaps.filter.PixelOutline(0x330000, 0.4);
		var bloom = new h2d.filter.Glow(0xeeffee, 0.5, 4, 0.5, 1, true);
		var group = new h2d.filter.Group([outline, bloom]);
		spr.filter = group;
		spr.set(Assets.lazer);

		// spr.anim.registerStateAnim(anims.closed, 2,()->cd.getS("recentlyTeleported")>0);
		spr.anim.registerStateAnim(anims.idle, 0);
		spr.anim.registerStateAnim(anims.idle, 1, () -> distCase(game.player) <= 2);

		var g = new h2d.Graphics(spr);
		g.lineTo(spr.x+200*Math.cos(ang/180*Math.PI),spr.y+200*Math.sin(ang/180*Math.PI));
		trace("hello grapple");
	}

	override function dispose() {
		super.dispose();
	}

	override function preUpdate() {
		super.preUpdate();
	}

	override function fixedUpdate() {
		super.fixedUpdate();
		
	}
}
