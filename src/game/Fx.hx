import hxd.Timer;
import hxsl.RuntimeShader;
import h2d.SpriteBatch;
import h2d.Sprite;
import dn.heaps.HParticle;

class Fx extends GameProcess {
	var pool:ParticlePool;

	public var bg_add:h2d.SpriteBatch;
	public var bg_normal:h2d.SpriteBatch;
	public var main_add:h2d.SpriteBatch;
	public var main_normal:h2d.SpriteBatch;
	public var front_normal:h2d.SpriteBatch;
	public var front_add:h2d.SpriteBatch;

	public function new() {
		super();
		pool = new ParticlePool(Assets.tiles.tile, 2048, Const.FPS);

		bg_add = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(bg_add, Const.DP_FX_BG); // Const.DP_BG
		bg_add.blendMode = Add;
		bg_add.hasRotationScale = true;

		bg_normal = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(bg_normal, Const.DP_FX_BG);
		bg_normal.hasRotationScale = true;

		main_normal = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(main_normal, Const.DP_FX_MAIN);
		main_normal.hasRotationScale = true;

		main_add = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(main_add, Const.DP_FX_MAIN); // Const.DP_FRONT
		main_add.blendMode = Add;
		main_add.hasRotationScale = true;

		/* EXTRA LAYER */

		front_add = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(front_add, Const.DP_FX_FRONT);
		front_add.blendMode = Add;
		front_add.hasRotationScale = true;

		front_normal = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(front_normal, Const.DP_FX_FRONT);
		// front_normal.blendMode = Normal;
		front_normal.hasRotationScale = true;
	}

	override public function onDispose() {
		super.onDispose();

		pool.dispose();
		bg_add.remove();
		bg_normal.remove();
		main_add.remove();
		main_normal.remove();
		front_add.remove();
		front_normal.remove();
	}

	/** Clear all particles **/
	public function clear() {
		pool.clear();
	}

	/** Create a HParticle instance in the BG layer, using ADDITIVE blendmode **/
	public inline function allocBg_add(id, x, y)
		return pool.alloc(bg_add, Assets.tiles.getTileRandom(id), x, y);

	/** Create a HParticle instance in the BG layer, using NORMAL blendmode **/
	public inline function allocBg_normal(id, x, y)
		return pool.alloc(bg_normal, Assets.tiles.getTileRandom(id), x, y);

	/** Create a HParticle instance in the MAIN layer, using ADDITIVE blendmode **/
	public inline function allocMain_add(id, x, y)
		return pool.alloc(main_add, Assets.tiles.getTileRandom(id), x, y);

	/** Create a HParticle instance in the MAIN layer, using NORMAL blendmode **/
	public inline function allocMain_normal(id, x, y)
		return pool.alloc(main_normal, Assets.tiles.getTileRandom(id), x, y);

	/** Create a HParticle instance in the FORGROUND layer, using NORMAL blendmode **/
	public inline function allocFront_normal(id, x, y)
		return pool.alloc(front_normal, Assets.tiles.getTileRandom(id), x, y);

	/** Create a HParticle instance in the FORGROUND layer, using ADD blendmode **/
	public inline function allocFront_add(id, x, y)
		return pool.alloc(front_add, Assets.tiles.getTileRandom(id), x, y);

	public inline function markerEntity(e:Entity, ?c = 0xFF00FF, ?short = false) {
		#if debug
		if (e != null && e.isAlive())
			markerCase(e.cx, e.cy, short ? 0.03 : 3, c);
		#end
	}

	public inline function markerCase(cx:Int, cy:Int, ?sec = 3.0, ?c = 0xFF00FF) {
		#if debug
		var p = allocMain_add(D.tiles.fxCircle15, (cx + 0.5) * Const.GRID, (cy + 0.5) * Const.GRID);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.lifeS = sec;

		var p = allocMain_add(D.tiles.pixel, (cx + 0.5) * Const.GRID, (cy + 0.5) * Const.GRID);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.setScale(2);
		p.lifeS = sec;
		#end
	}

	public inline function markerFree(x:Float, y:Float, ?sec = 3.0, ?c = 0xFF00FF) {
		#if debug
		var p = allocMain_add(D.tiles.fxDot, x, y);
		p.setCenterRatio(0.5, 0.5);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.setScale(3);
		p.lifeS = sec;
		#end
	}

	public inline function markerText(cx:Int, cy:Int, txt:String, ?t = 1.0) {
		// #if debug
		var tf = new h2d.Text(Assets.fontPixel, front_normal);
		tf.text = txt;

		var p = allocFront_add(D.tiles.SayLine, (cx + 0.5) * Const.GRID, (cy + 1.5) * Const.GRID);
		p.colorize(0x0080FF);
		p.y -= 16;
		p.alpha = 0.6;
		p.lifeS = t;
		p.fadeOutSpeed = 0.2;
		p.onKill = tf.remove;

		tf.setPosition(p.x - tf.textWidth * 0.5, p.y - tf.textHeight * 1.5);
		// #end
	}

	inline function collides(p:HParticle, offX = 0., offY = 0.) {
		if(level.hasBreakable(Std.int((p.x + offX) / Const.GRID), Std.int((p.y + offY) / Const.GRID))){
			level.breakables.remove(Breaks,Std.int((p.x + offX) / Const.GRID), Std.int((p.y + offY) / Const.GRID));
			new sample.Boom(null,p.x,p.y);
			p.kill();
			return true;
		}
		return level.hasCollision(Std.int((p.x + offX) / Const.GRID), Std.int((p.y + offY) / Const.GRID));
	}

	public inline function flashBangS(c:UInt, a:Float, ?t = 0.1) {
		var e = new h2d.Bitmap(h2d.Tile.fromColor(c, 1, 1, a));
		game.root.add(e, Const.DP_FX_FRONT);
		e.scaleX = game.w();
		e.scaleY = game.h();
		e.blendMode = Add;
		game.tw.createS(e.alpha, 0, t).end(function() {
			e.remove();
		});
	}

	public inline function flashLight(c:UInt, a:Float, ?t = 60) {
		var e = new h2d.Bitmap(h2d.Tile.fromColor(c, 1, 1, a));
		game.root.add(e, Const.DP_FX_FRONT);
		e.scaleX = game.w();
		e.scaleY = game.h();
		e.blendMode = Add;
		game.tw.createS(e.alpha, 0, t).end(function() {
			e.remove();
		});
	}

	/**
		A small sample to demonstrate how basic particles work. This example produces a small explosion of yellow dots that will fall and slowly fade to purple.

		USAGE: fx.dotsExplosionExample(50,50, 0xffcc00)
	**/
	public inline function dotsExplosionExample(x:Float, y:Float, color:UInt) {
		for (i in 0...20) {
			var p = allocMain_add(D.tiles.fxDot, x + rnd(0, 3, true), y + rnd(0, 3, true));
			p.alpha = rnd(0.4, 1);
			p.colorAnimS(color, 0x762087, rnd(0.6, 3)); // fade particle color from given color to some purple
			p.moveAwayFrom(x, y, rnd(1, 3)); // move away from source
			p.colorizeRandomLighter(color, 0.5);
			p.frict = rnd(0.8, 0.9); // friction applied to velocities
			p.gy = rnd(0, 0.02); // gravity Y (added on each frame)
			p.lifeS = rnd(2, 3); // life time in seconds
		}
	}

	/**
	 * Smogg
	 * @param x 
	 * @param y 
	 * @param color 
	 * @param dr 
	 */
	public inline function smogg(x:Float, y:Float, ?color:UInt = 0xaaaaaa, ?size:Float = 1) {
		for (i in 0...1) {
			var p = allocMain_normal(D.tiles.fxSmoke0, x + rnd(0, 3, true), y + rnd(0, 3, true));
			p.alpha = rnd(0.01, 0.4);
			p.autoRotate(1);
			// p.colorizeRandomDarker(color,16);
			p.scale = size * rnd(0.5, 2);
			p.scaleMul = 1.0022;
			// p.fadeIn(0.8,0.1);
			p.setFadeS(rnd(0.1, 0.7), 0.2, 1.8);
			p.colorAnimS(color, 0x00525252, 2); // fade particle color from given color to some purple
			// p.moveAwayFrom(x,y, rnd(0.1,2)); // move away from source
			p.frict = rnd(0.85, 0.99); // friction applied to velocities
			p.gy = -0.01; // gravity Y (added on each frame)
			p.lifeS = 2; // life time in seconds
			// game.tw.createS(p.a,0,TLinear,2).end(p.remove);
		}
	}

	public inline function bloodSpread(x:Float, y:Float, ?color:UInt = 0x880000, ?dr:Float = 1) {
		for (i in 0...10) {
			var p = allocMain_add(D.tiles.pixel, x + rnd(-3, 3, true), y + rnd(-3, 3, true));
			p.alpha = rnd(0.4, 1);
			p.autoRotate(0.1);
			p.frictX = 0.9;
			p.frictY = 0.9;
			p.bounceMul = 0.25;
			p.scaleMul = 0.95;
			// p.moveAwayFrom(x,y-32, rnd(1,3));
			p.scale = rnd(0.5, 2);
			p.colorAnimS(color, 0xffffff, rnd(0.6, 3)); // fade particle color from given color to some purple
			p.moveAwayFrom(x, y, rnd(-4, 4, true)); // move away from source
			p.frict = rnd(0.80, 0.99); // friction applied to velocities
			p.gy = 0.022 + rnd(0.012, 0.052); // gravity Y (added on each frame)
			p.lifeS = rnd(1, 2); // life time in seconds
			/*tw.createS(p.a, 0, TLinear, 1).update(() -> if (collides(p)) {
				p.dy *= -1;
			}).end(p.remove);*/
		}
	}

	public inline function spyraleRotation(x:Float, y:Float, ?color:UInt = 0xffffff, ?dr:Float = 1) {
		var p = allocMain_add(D.tiles.fxSpyrale, x + rnd(0, 3, true), y + rnd(0, 3, true));
		p.alpha = 1;
		// p.autoRotate(1.0);
		// p.animSpd = 2.0;
		p.rotation = rnd(-4 * 3.14, 4 * 3.14, true);
		p.lifeS = rnd(5.0, 5.0);
		p.colorAnimS(color, 0x762087, 5);
		// p.fadeIn(1.0, 0.1);
		p.dx = 2.5 * dr;
		p.scale = 0.25;
		
		tw.createS(p.a, 0, TLinear, 5.5).update(() -> {
			//tail(x,y);
			if (collides(p)) {
				p.kill();
			};
			p.rotation += 0.01;
			// trace("rotation");
		}).end(p.kill);
		// game.tw.createS(,p.rotation*8,TLinear,5.5).end(p.remove);
	}

	/**
	 * [Description]Gives Player a trailling tail
	 * @param x 
	 * @param y 
	 * @param color 
	 * @param ang
	 * @param spd 
	 */
	public inline function tail(x:Float, y:Float, ?color:UInt = 0x880000, ?ang:Float = 0, ?spd:Float = 1) {
		for (i in 0...1) {
			var p = allocMain_add(D.tiles.fxBlurryTail, x, y); // .fxStar0
			p.alpha = 0.5;
			p.scaleMul = 0.999;
			p.scale = 0.5 * spd;
			p.rotation = ang;
			p.colorAnimS(color, 0xffff0000, 1.5); // fade particle color from given color to some purple

			p.frict = 0; // friction applied to velocities
			p.gy = 0; // gravity Y (added on each frame)
			p.lifeS = 1.5; // life time in seconds
			tw.createS(p.a, 0, TLinear, 1.5).end(p.kill);
			p.killOnLifeOut = true;
		}
	}

	public inline function electail(x:Float, y:Float, ?color:UInt = 0x880000, ?ang:Float = 0, ?spd:Float = 1) {
		for (i in 0...1) {
			var p = allocMain_add(D.tiles.fxSignalTail, x, y); // .fxBlurryTail
			p.alpha = 0.8;
			p.scaleMul = 0.999;
			p.scale = 1.0;
			// p.rotation=ang;
			p.colorAnimS(color, 0xffffffff, 1.5); // fade particle color from given color to some purple

			p.frict = 0; // friction applied to velocities
			p.gy = 0; // gravity Y (added on each frame)
			p.lifeS = 1.5; // life time in seconds
			tw.createS(p.a, 0, TLinear, 1.5).end(p.kill);
			p.killOnLifeOut = true;
		}
	}

	/**
	 * [Description] Shines a light
	 * @param x 
	 * @param y 
	 * @param color 
	 * @param size 
	 */
	public inline function lumiere(x:Float, y:Float, ?color:UInt = 0x888800, ?front:Bool = false, ?size:Float = 1) {
		for (i in 0...1) {
			var p;
			if (front == false) {
				p = allocBg_add(D.tiles.fxLightCircle0, x, y);
			} else {
				p = allocFront_add(D.tiles.fxLightCircle0, x, y);
			}

			p.alpha = 0.1; // rnd(0.1,0.5);
			p.colorize(color, 1);
			// p.scaleMul=0.99;
			p.scale = size;
			// p.rotation=ang;
			// p.colorAnimS(color, 0xffffff, 0.1); // fade particle color from given color to some purple
			// p.fadeIn(0.5,1);
			p.killOnLifeOut = true;
			p.frict = 0; // friction applied to velocities
			p.gy = 0; // gravity Y (added on each frame)
			p.lifeS = rnd(0.1, 0.5); // life time in seconds
			// tw.createS(p.a,0,TLinear,0.1).end(p.remove);
		}
	}

	/** rain **/
	public inline function drople(x:Float, y:Float, ?color:UInt = 0x1C929F, ?front:Bool = true, ?size:Float = 0.5) {
		for (i in 0...1) {
			var p;
			if (front == false) {
				p = allocBg_add(D.tiles.fxDirt, x, y);
			} else {
				p = allocMain_add(D.tiles.fxDirt, x, y);
			}

			p.alpha = rnd(0.1, 1);
			p.colorize(color, 1);
			// p.scaleMul=0.99;
			p.scale = size;
			p.rotation = rnd(0, 180);
			// p.colorAnimS(color, 0xffffff, 0.1); // fade particle color from given color to some purple
			// p.fadeIn(0.5,1);
			p.frict = 0; // friction applied to velocities
			var vy = rnd(5, 25);
			p.gy = vy; // gravity Y (added on each frame)
			p.lifeS = 3; // life time in seconds
			p.dx = 0.1;
			p.dy = 0.2;
			p.scaleY = vy;
			p.autoRotate(1);

			/*tw.createS(p.a,0,TLinear,4).update(function(){
				if(collides(p) && p.y>36){p.remove();}
			}).end(p.remove);*/
		}
	}

	// bubbles

	/** bubbles **/
	public inline function bubbles(x:Float, y:Float, ?color:UInt = 0x1C929F, maxY:Float, ?size:Float = 0.5) {
		for (i in 0...1) {
			var p;
			p = allocFront_add(D.tiles.bubble1, x, y);

			var yy = y;
			p.scale = rnd(0.1, 0.30);
			p.alpha = rnd(0.1, 0.5);
			p.colorize(color, 0.5);

			// p.colorAnimS(color, 0xffffff, 0.1); // fade particle color from given color to some purple
			// p.fadeIn(0.5, 2);
			p.frict = 0; // friction applied to velocities
			var vy = rnd(0.25, 0.65);
			p.gy = -vy; // gravity Y (added on each frame)
			// p.lifeS = 1.5; // life time in seconds
			p.dx = rnd(0.05, -0.05, true);
			p.dy = -0.2;
			p.gx = p.dx;
			tw.createS(p.a, 0, TLinear, 3).update(function() {
				if (p.y < maxY) {
					// trace("adios amigos, so looong");
					p.kill();
				}
			}).end(p.kill);
		}
	}

	/** waves **/
	public inline function waves(x:Float, y:Float, ?color:UInt = 0x1C929F, maxY:Float, ?size:Float = 0.5) {
		for (i in 0...1) {
			var p;
			var r = irnd(0, 2);
			if (r == 0) {
				p = allocFront_add(D.tiles.wave0, x, y);
			} else if (r == 1) {
				p = allocFront_add(D.tiles.wave1, x, y);
			} else {
				p = allocFront_add(D.tiles.wave2, x, y);
			}
			p.y += 4 + Math.sin(Timer.frameCount * 0.1 + p.x / 180 * 3.1416 * 6) * 2;
			var yy = y;
			p.scale = 0.5; // rnd(0.5, 1);
			p.alpha = rnd(0.2, 0.9);
			p.colorize(color, rnd(0.2, 0.9));

			// p.colorAnimS(color, 0xffffff, 0.1); // fade particle color from given color to some purple
			p.fadeIn(0.1, 2);
			p.frict = 0; // friction applied to velocities
			var vy = rnd(0.1, 0.25);
			p.gy = 0; // gravity Y (added on each frame)
			p.lifeS = 0.15; // life time in seconds
			p.dx = 0;
			p.dy = 0;
			p.gx = 0;
			/*tw.createS(p.a,0,TLinear,4).update(function(){
				if(p.y<maxY-4){p.remove();}
			}).end(p.remove);*/
		}
	}

	// snow
	public inline function snow(x:Float, y:Float, ?color:UInt = 0xD1F1F4, ?front:Bool = true, ?size:Float = 0.5) {
		for (i in 0...1) {
			var p;
			if (front == false) {
				p = allocBg_add(D.tiles.fxFlake0, x, y);
			} else {
				p = allocMain_add(D.tiles.fxFlake1, x, y);
			}

			p.alpha = rnd(0.1, 1);
			p.colorize(color, 1);
			// p.scaleMul=0.99;
			p.scale = rnd(0.1, 0.4);
			p.rotation = rnd(0, 180);
			// p.colorAnimS(color, 0xffffff, 0.1); // fade particle color from given color to some purple
			// p.fadeIn(0.5,1);
			p.frict = 0; // friction applied to velocities
			var vy = rnd(0.5, 2);
			p.gy = vy; // gravity Y (added on each frame)
			var vx = rnd(-2, 2, true);
			p.lifeS = 3; // life time in seconds
			p.dx = vx;
			p.gx = vx;
			p.dy = 0.2;
			// p.scaleY = vy;
			p.autoRotate(vy);

			/*tw.createS(p.a,0,TLinear,4).update(function(){
				if(collides(p) && p.y>36){p.remove();}
			}).end(p.remove);*/
		}
	}

	// electricity
	public inline function electricity(x:Float, y:Float, ?color:UInt = 0x03AFFF, ?front:Bool = true, ?size:Float = 0.5) {
		for (i in 0...1) {
			var p;
			if (front == false) {
				p = allocBg_add(D.tiles.fxBigElectricity, x, y);
			} else {
				p = allocMain_add(D.tiles.fxBigElectricity, x, y);
			}
			p.scale=0.5;//rnd(0.1,2);
			//p.scaleX=rnd(1,4);
			p.lifeS = 0.15;
			p.rotation = irnd(0, 4)*90/180*Math.PI;
			p.setFadeS(rnd(0.01,0.99),0.05,0.1);
		}
	}

	override function update() {
		super.update();
		pool.update(game.tmod);
	}
}
