package sample;

import h2d.Graphics;
import ldtk.Point;
import haxe.DynamicAccess;
import dn.Delayer;
import h2d.filter.Bloom;

/**
	SamplePlayer is an Entity with some extra functionalities:
	- falls with gravity
	- has basic level collisions
	- controllable (using gamepad or keyboard)
	- some squash animations, because it's cheap and they do the job
**/
class Signal extends Entity {
	public static var ALL:Array<Signal> = [];

	var anims = dn.heaps.assets.Aseprite.getDict(hxd.Res.atlas.signal);
	var walkSpeed = 0.;

	var delayer = new dn.Delayer(Const.FPS);
	// This is TRUE if the player is not falling
	var onGround(get, never):Bool;
	var pointIndex:Int = 0;

	public var way:Graphics = null;
	public var color:Int = 0;

	inline function get_onGround()
		return !destroyed && dy == 0 && yr == 1 && (level.hasCollision(cx, cy + 1) || level.hasOneWay(cx, cy + 1));

	public var path:Array<Null<ldtk.Point>> = [];
	public var cur_point:Point = null;

	public function new(ent:Entity_Signal) {
		super(5, 5);
		color = ent.f_Color_int;
		// Start point using level entity "PlayerStart"
		var start = level.data.l_Entities.all_PlayerStart[0];
		if (start != null)
			setPosCase(start.cx, start.cy);

		setPosCase(ent.cx, ent.cy);
		setPosPixel(ent.cx + 8.0, ent.cy + 8.0);
		set_pivotX(-0.5);
		set_pivotY(-0.5);
		path = ent.f_Point;
		pointIndex = 0;
		cur_point = path[pointIndex];

		// Misc inits
		frictX = 1;
		frictY = 1;
		// sprScaleX=M.frand()*0.25 + 0.25;
		// sprScaleY=sprScaleX;
		xr = 0.5;
		yr = 0.5;
		dir = 0;

		if (way != null) {
			way.remove();
		}
		// Placeholder display

		var outline = new dn.heaps.filter.PixelOutline(0x330000, 0.8);
		var bloom = new h2d.filter.Glow(0xfd477b, 0.8, 16, 1.5, 1, true);
		var group = new h2d.filter.Group([outline, bloom]);
		spr.filter = group;
		spr.set(Assets.signal);

		spr.anim.registerStateAnim(anims.idle, 0);
		var g = new h2d.Graphics(spr);
		// g.bevel=0.25;
		// g.beginFill(0x00ff00);
		// g.drawRect(-12*0.5,-24,12,24);
	}

	override function dispose() {
		super.dispose();
		way.remove();
	}

	/** X collisions **/
	override function onPreStepX() {
		super.onPreStepX();
	}

	/** Y collisions **/
	override function onPreStepY() {
		super.onPreStepY();
	}

	/**
		Control inputs are checked at the beginning of the frame.
		VERY IMPORTANT NOTE: because game physics only occur during the `fixedUpdate` (at a constant 30 FPS), no physics increment should ever happen here! What this means is that you can SET a physics value (eg. see the Jump below), but not make any calculation that happens over multiple frames (eg. increment X speed when walking).
	**/
	override function preUpdate() {
		super.preUpdate();
	}

	override function fixedUpdate() {
		super.fixedUpdate();
		fx.electail(spr.x + 8.0, spr.y + 8.0, color, getMoveAng() * 180 / Math.PI, M.fabs(1.2));
		if (game.player.cx == cx && game.player.cy == cy && !game.player.cd.has("invincible")) {
			game.player.bdx = dir * 0.1;
			game.player.life--;
			game.player.cd.setMs("invincible", 800);
		}
		// way.remove();
		if (way == null)
			way = new Graphics(game.scroller);
		way.filter = new h2d.filter.Glow(color, 0.5, 16, 1.5, 1, true);
		game.scroller.over(way);
		way.clear();
		// way.beginFill(0xf,0.0);
		if (path.length > 0) {
			way.lineStyle(2, color, 0.25);
			way.moveTo(path[0].cx * 16 + 8, path[0].cy * 16 + 8);
			for (i in 0...path.length) {
				way.lineTo(path[i].cx * 16 + 8, path[i].cy * 16 + 8);
			}
			// way.endFill();

			if (cx != cur_point.cx) {
				if (cur_point.cx - cx > 0) {
					dx = 0.2;
				} else if (cur_point.cx - cx < 0) {
					dx = -0.2;
				}
			} else if (cx == cur_point.cx) {
				xr = 0;
			};

			if (cy != cur_point.cy) {
				if (cur_point.cy - cy > 0) {
					dy = 0.2;
				} else if (cur_point.cy - cy < 0) {
					dy = -0.2;
				}
			} else if (cy == cur_point.cy) {
				if (dy > 0)
					yr = 0;
				if (dy < 0 && yr < 0.2)
					yr = 0;
			};
			if (cx == cur_point.cx && cy == cur_point.cy && xr == 0 && yr == 0) {
				if (pointIndex < path.length - 1) {
					cur_point = path[pointIndex++];
				} else {
					path.reverse();
					pointIndex = 0;
					cur_point = path[pointIndex];
				}
			}
		}
	}
}
