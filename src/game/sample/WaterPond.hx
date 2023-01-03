package sample;

import GameStats.Achievement;

class WaterPond extends Entity {
	public static var ALL:Array<WaterPond> = [];

	public var actionString:String;
	public var done:Bool = false;
	public var countDown:Int = 10;

	// public var collides:Bool = false;
	var collides(get, never):Bool;
	inline function get_collides()
		return game.player.cx >= cx && game.player.cx <= cx + wid / 16 && game.player.cy >= cy && game.player.cy <= cy + hei / 16;

	var canBreath(get,never):Bool;
	inline function get_canBreath()
		return game.player.cy+game.player.yr<cy+1+0.5;

	public function new(d:Entity_Water) {
		super(0, 0);
		ALL.push(this);
		data = d;
		iid = d.iid;
		// activated = d.f_Activated;
		// done = false;
		// locked = d.f_locked;
		// if(locked && !activated){trace("THIS EXIT IS LOCKED");}
		setPosPixel(d.pixelX, d.pixelY);
		// pivotX = -0.5;
		// pivotY = -0.5;
		spr.set("empty");
		spr.filter = new h2d.filter.Blur(8, 1.5, 3);
		spr.alpha = 0.75;
		game.scroller.under(spr);
		var g = new h2d.Graphics(spr);
		wid = d.width;
		hei = d.height;
		#if debug
		#end
		g.beginFill(0x004E7B, 0.5);
		g.drawRect(0, 0, wid, hei);
	}

	override function fixedUpdate() {
		if (collides) {
			game.player.cd.setMs('wasRecentlyInWater', 100);
			game.player.dx *= 0.5;
			game.player.dy *= 0.9;
			if (game.player.dy > 0) {
				game.player.dy *= 0.9;
			}
		}else{
			countDown=10;
		}
		if(rnd(0,100)<50){
			fx.electricity(rnd(attachX, attachX + wid),rnd(attachY, attachY + hei));
		}
		if (game.player.cd.has('wasRecentlyInWater') && !cd.has("breath") && !canBreath) {
			cd.setMs('breath', 1000);
			countDown--;
			game.player.blink(0xffffff);
			for (a in 0...8) {
				fx.bubbles(game.player.attachX, game.player.attachY - 18, 0x2ed2e1, attachY, 0.25);
			}
			game.player.debug(countDown,countDown <= 3? 0xff0000:0xffffff);
			if (countDown <= 3) {
				game.player.life--;
			}
		}

		if (!cd.has("clignotage") && !canBreath) {
			blink(0xffffff);
			cd.setMs("clignotage", 1500);
		}
		if (!cd.has('waterFx')) {
			cd.setMs('waterFx', 100);
			for (a in 0...Std.int(wid / 32)) {
				fx.bubbles(rnd(attachX, attachX + wid), attachY + hei, 0x2ed2e1, attachY, 0.25);
			}
			for (i in 0...5) {
				for (a in 0...Std.int(wid / 16)) {
					fx.waves(rnd(attachX, attachX + wid), attachY, 0x2ed2e1, attachY, 0.25);
				}
			}
			if (collides && !game.player.cd.has('wasRecentlyInWater')) {
				cd.setMs("splash", 150);
				fx.bloodSpread(game.player.attachX, spr.y, 0xba52bcd9);
			}
		}
	}
}
