package sample;

import sample.SampleTutorial.Tutorial;
import GameStats.Achievement;
import h2d.filter.Bloom;

/**
	SamplePlayer is an Entity with some extra functionalities:
	- falls with gravity
	- has basic level collisions
	- controllable (using gamepad or keyboard)
	- some squash animations, because it's cheap and they do the job
**/
class RigidBody extends Entity {
	public static var ALL:Array<RigidBody> = [];

	var anims = dn.heaps.assets.Aseprite.getDict(hxd.Res.atlas.rigids);

	// public var locked:Bool = false;
	public var requierements:Array<Dynamic> = [];
	public var loots:Array<Dynamic> = [];
	public var looted:Bool = false;
	public var hold:Bool = false;
	public var enemyType:String;

	var collides(get, never):Bool;

	inline function get_collides() {
		return (game.player.right >= left && game.player.left <= right && game.player.bottom >= top && game.player.top <= bottom);
	}

	var onGround(get, never):Bool;

	inline function get_onGround() {
		// if(collides && game.player.attachY>=attachY+16) return true;
		return game.level.hasCollision(cx, cy+1);
	}

	public function new(rb:Entity_RigidBody) {
		super(rb.cx, rb.cy);
		wid = 32;
		hei = 28;
		if (game.gameStats.has('savePos_' + rb.iid)) {
			cx = game.gameStats.get('savePos_' + rb.iid).data.posX;
			cy = game.gameStats.get('savePos_' + rb.iid).data.posY;
		}
		// Placeholder display

		data = rb;

		// trace(ch.iid);
		var outline = spr.filter = new dn.heaps.filter.PixelOutline(0x330000, 0.4);
		var bloom = new h2d.filter.Glow(0xeeffee, 0.5, 4, 0.5, 1, true);
		var group = new h2d.filter.Group([outline, bloom]);
		spr.filter = group;
		spr.set(Assets.rigids);

		spr.anim.registerStateAnim(anims.fuse, 0, 1, () -> data.f_RigidBodyType == Fuse);
		spr.anim.registerStateAnim(anims.sphere, 0, 1, () -> data.f_RigidBodyType == Sphere);
		spr.anim.registerStateAnim(anims.box, 0, 1, () -> data.f_RigidBodyType == Box);

		var g = new h2d.Graphics(spr);
		sample.SampleRigidBody.RigidBody.ALL.push(this);
	}

	override function dispose() {
		super.dispose();
	}

	override function frameUpdate() {
		super.frameUpdate();
		
		if (game.player.right >= left && game.player.left <= right) {
			if (game.player.bottom >= top && game.player.top <= bottom) {
				if (game.player.attachX < attachX && game.player.dx > 0) {
					game.player.cd.setMs('pushingRBody', 100);
					game.player.dx*=0.9;
					dx = game.player.dx;
					game.player.spr.x = left - 32;
				} else if (game.player.attachX > attachX && game.player.dx < 0) {
					game.player.cd.setMs('pushingRBody', 100);
					game.player.dx*=0.9;
					dx = game.player.dx;
					game.player.spr.x = right + 32;
				}
				if (game.player.dy >= 0 && game.player.spr.y >= attachY - hei) {
					game.player.spr.y = attachY - hei;
					game.player.onPosManuallyChangedY();
					// game.player.yr=1.0;
					game.player.dy = 0.0;
					if(onGround) game.player.cd.setMs('recentlyOnRBody', 100);
				}
			}
		}
	}

	override function fixedUpdate() {
		super.fixedUpdate();
		// debug(data.f_Entity_ref.entityIid,0xff0000);
		
		if (distCase(game.player) <= 2 && !cd.has('holding')) {
			if (game.player.cd.has("isHoldingAction")) {
				cd.setS('holding', 2);
			}
		}

		if (!onGround && !cd.has('holding')) {
			dy += 0.4;
			spr.y += dy;
			game.gameStats.unregisterState('savePos_' + data.iid);
		} else if (!game.gameStats.has('savePos_' + data.iid)) {
			var pos = {
				posX: cx,
				posY: cy - 1
			}
			var achPos = new Achievement("savePos_" + data.iid, "savePos", () -> onGround, () -> {
				// trace("saved position");
			}, pos);
			game.gameStats.registerState(achPos);
		}

		if (cd.has('holding')) {
			// trace('hold my beer');
			dy = 0;
			dx = 0;
			cx = game.player.cx;
			cy = game.player.cy;
			xr = game.player.xr;
			yr = game.player.yr - 1;
		} else if (!cd.has("clignotage")) {
			blink(0x25fd04);
			cd.setMs("clignotage", 1500);
		}

		var target = data.f_Entity_ref == null ? null : Entity.ALL.filter((ent) -> {
			return ent.iid == data.f_Entity_ref.entityIid;
		})[0];
		if (target == null) {
			trace('nothing else matters');
		} else {
			if (distCase(target) <= 1) {
				// trace('activation');
				target.activated = true;
				if (Std.string(data.f_Achievements) != null && !game.gameStats.has(Std.string(data.f_Achievements))) {
					var fach = new Achievement(Std.string(data.f_Achievements), 'done', () -> return true, () -> {
						trace('requierement achieved :' + Std.string(data.f_Achievements));
						hud.notify(Std.string(data.f_Achievements) + " accompli.");
					});
					game.gameStats.registerState(fach);
				};
			} else {
				target.activated = false;
			}
		}
	}
	override function postUpdate(){
		super.postUpdate();
		if (onGround == true) {
			dy = 0;
			yr = 1;
		}
		if (level.hasCollision(cx + 1, cy) && xr >= 0.9) {
			xr = 0.9;
			dx = 0;
		}
		if (level.hasCollision(cx - 1, cy) && xr <= 0.1) {
			xr = 0.1;
			dx = 0;
		}
	}
}
