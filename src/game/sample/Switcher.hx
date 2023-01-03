package sample;

import dn.Delayer;
import GameStats.Achievement;
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
class Switcher extends Entity {
	public static var ALL:Array<Switcher> = [];

	var anims = dn.heaps.assets.Aseprite.getDict(hxd.Res.atlas.computer);
	var goodRessource:Sound = null;
	var wrongRessource:Sound = null;
	var doorResource:Sound = null;
	var ready(get, never):Bool;

	inline function get_ready()
		return spr.anim.getAnimId() == anims.idle;

	public function new(ent:Entity_Switcher) {
		if (hxd.res.Sound.supportedFormat(OggVorbis)) {
			goodRessource = hxd.Res.sounds.good;
			wrongRessource = hxd.Res.sounds.wrong;
			doorResource = hxd.Res.sounds.sfx_door;
		}
		if (hxd.res.Sound.supportedFormat(Mp3)) {
			goodRessource = hxd.Res.sounds.good;
			wrongRessource = hxd.Res.sounds.wrong;
			doorResource = hxd.Res.sounds.sfx_door;
		}
		super(ent.cx, ent.cy);
		setPosCase(ent.cx, ent.cy);
		// Placeholder display

		data = ent;
		iid = ent.iid;
		var outline = spr.filter = new dn.heaps.filter.PixelOutline(0x330000, 0.4);
		var bloom = new h2d.filter.Glow(0xeeffee, 0.5, 4, 0.5, 1, true);
		var group = new h2d.filter.Group([outline, bloom]);
		spr.filter = group;
		spr.set(D.tiles.switcher);

		// spr.anim.registerStateAnim(anims.closed, 2,()->cd.getS("recentlyTeleported")>0);
		// spr.anim.registerStateAnim(anims.idle, 0);
		// spr.anim.registerStateAnim(anims.idle2, 1, () -> distCase(game.player) <= 2);

		var g = new h2d.Graphics(spr);
	}

	override function dispose() {
		super.dispose();
	}

	override function preUpdate() {
		super.preUpdate();
	}

	override function fixedUpdate() {
		super.fixedUpdate();
		// debug(data.f_Entity_ref.entityIid);
		if (!cd.has("canard")) {
			fx.markerText(cx, cy - 2, "Press ACTION", 2.0);
			cd.setS("canard", 5.0);
		};

		if (distCase(game.player) <= 2 && game.player.cd.has('recentlyPressedAction')) {
			for (ent in Entity.ALL) {
				if (ent.iid == data.f_Entity_ref.entityIid && iid != ent.iid) {
					game.delayer.addS('waiting_'+ent.iid, () -> {
						//trace("delayed");
						ent.activated = true;
						ent.locked=false;
						doorResource.play().volume = 1.0;
						game.camera.trackEntity(game.player,false,0.5);
						game.camera.centerOnTarget();
					}, 1);
					game.camera.trackEntity(ent,false,0.5);
					game.camera.centerOnTarget();					
					goodRessource.play().volume = 0.25;
					
				}
			}
		}
	}
}
