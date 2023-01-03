package sample;

import GameStats.Achievement;

class ExitRect extends Entity {
	public static var ALL:Array<ExitRect> = [];

	public var actionString:String;
	public var done:Bool = false;

	// public var collides:Bool = false;
	var collides(get, never):Bool;

	inline function get_collides()
		return game.player.centerX >= left
			&& game.player.centerX <= right
			&& game.player.centerY >= top
			&& game.player.centerY <= bottom;

	public function new(d:Entity_ExitRect) {
		super(0, 0);
		ALL.push(this);
		data = d;
		iid=d.iid;
		activated = d.f_Activated;
		done = false;
		locked = d.f_locked;
		if(locked && !activated){trace("THIS EXIT IS LOCKED");}
		setPosPixel(d.pixelX, d.pixelY);
		pivotX = -0.5;
		pivotY = -0.5;
		spr.set("empty");
		var g = new h2d.Graphics(spr);
		wid = d.width;
		hei = d.height;
		#if debug
		g.beginFill(0x00ff00, 0.25);
		g.drawRect(0, 0, wid, hei);
		#end
	}

	override function fixedUpdate() {
		if (activated == true && locked==false) {

			if (collides && !game.player.cd.has("changeLevel") && !done) {
				// trace(data.f_Entity_ref.entityIid);
				// trace(data.f_Entity_ref.levelIid);
				game.player.cd.setMs('changeLevel', 500);
				game.player.destination = {
					level: data.f_Entity_ref.levelIid,
					door: data.f_Entity_ref.entityIid,
					offsetX: (game.player.centerX - centerX),
					offsetY: (game.player.centerY - centerY)
				};
				done = true;
				for (lvl in Assets.worldData.levels) {
					if (lvl.iid == game.player.destination.level) {
						hud.notify('téléportinge');
						game.player.jumps = 0;
						game.delayer.addF("changeLevel", () -> game.startLevel(lvl), 1);
					}
				}
			} else if (!collides) {
				done = false;
			}
		}
	}
}
