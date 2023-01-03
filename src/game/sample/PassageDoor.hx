package sample;

import GameStats.Achievement;

class PassageDoor extends Entity {
	public static var ALL:Array<PassageDoor> = [];

	public var actionString:String;
	public var done:Bool = false;

	// public var collides:Bool = false;
	var collides(get, never):Bool;

	inline function get_collides()
		return game.player.centerX >= left
			&& game.player.centerX <= right
			&& game.player.centerY >= top
			&& game.player.centerY <= bottom;

	public function new(d:Entity_PassageDoor) {
		super(0, 0);
		ALL.push(this);
		data = d;
		iid=d.iid;
		activated = d.f_activated;
		done = false;
		locked = d.f_locked;
		wid = d.width;
		hei = d.height;
		if(locked && !activated){trace("THIS EXIT IS LOCKED");}
		setPosPixel(d.pixelX, d.pixelY-hei);
		pivotX = 0;
		pivotY = 0;
		spr.set(D.tiles.closedDoor);
		var g = new h2d.Graphics(spr);
		
		#if debug
		g.beginFill(0x00ff00, 0.25);
		g.drawRect(0, 0, wid, hei);
		#end
	}

	override function fixedUpdate() {
		var p=game.player;
		if(collides && locked==true){
			blink(0xff0000);
			if(p.cd.has("recentlyPressedAction")){
				locked=false;
				activated=true;
			}
			if(p.right>=left){
				p.xr=0.4;
				p.cx=cx;
				p.dx=0;
			}else if(p.left<=right){
				p.xr=0.6;
				p.cx=cx+1;
				p.dx=0;
			}
		}
		if(locked==true || activated==false){
			spr.set(D.tiles.closedDoor);
		}else{
			spr.set(D.tiles.openedDoor);
		}
	}
}
