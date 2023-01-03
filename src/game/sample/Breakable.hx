package sample;
import hxd.res.Sound;
import GameStats.Achievement;

class Breakable extends Entity {
	public static var ALL:Array<Breakable> = [];

	public var actionString:String;
	public var done:Bool = false;
	public var booms:Sound=null;
	// public var collides:Bool = false;
	var collides(get, never):Bool;

	inline function get_collides()
		return game.player.centerX >= left
			&& game.player.centerX <= right
			&& game.player.centerY >= top
			&& game.player.centerY <= bottom;

	public function new(d:Entity_Breakable) {
		super(0, 0);
		ALL.push(this);
		data = d;
		iid = d.iid;
		// activated = d.f_activated;
		done = false;
		locked = true;
		wid = d.width;
		hei = d.height;
		if (hxd.res.Sound.supportedFormat(OggVorbis)) {
			booms = hxd.Res.sounds.boom;
		}
		if (hxd.res.Sound.supportedFormat(Mp3)) {
			booms = hxd.Res.sounds.boom;
		}
		// if(locked && !activated){trace("THIS EXIT IS LOCKED");}
		setPosPixel(d.pixelX, d.pixelY);
		pivotX = 0;
		pivotY = 0;
		spr.set(D.tiles.breakable);
		spr.filter = new h2d.filter.Group([new dn.heaps.filter.PixelOutline(0x330000, 0.8)]);
		var g = new h2d.Graphics(spr);
		level.breakables.set(Breaks, d.cx, d.cy);
		#if debug
		g.beginFill(0x00ff00, 0.25);
		g.drawRect(0, 0, wid, hei);
		#end
	}

	override function fixedUpdate() {
		if (level.breakables.has(Breaks, cx, cy)) {
			if (!cd.has('blinc')){
				cd.setMs('blinc',2500);
				blink(0x4E4E0E);}
			spr.set(D.tiles.breakable);
		} else {
			booms.play().volume=1;
			spr.set('empty');
			done = true;
			dispose();
		}
	}
}
