package sample;

import GameStats.Achievement;
import haxe.io.Bytes;
import haxe.Json;
import dn.Delayer;
import aseprite.Utils;
#if hl
import hl.UI;
#end
import h2d.filter.Group;
import h3d.Vector;
import hxd.res.Sound;
import Array;

/**
	SamplePlayer is an Entity with some extra functionalities:
	- falls with gravity
	- has basic level collisions
	- controllable (using gamepad or keyboard)
	- some squash animations, because it's cheap and they do the job
**/
class SamplePlayer extends Entity {
	var ca:ControllerAccess<GameAction>;
	var anims = dn.heaps.assets.Aseprite.getDict(hxd.Res.atlas.hero);
	var walkSpeed = 0.;

	public var grapple:SampleGrapple = null;
	public var shadeNorm:Null<NormalShader>;
	public var start:Entity_PlayerStart = null;
	public var puppetMaster:Null<Dynamic>;
	public var avatar:HSprite;
	public var destination = {
		level: null,
		door: null,
		offsetX: 0.0,
		offsetY: 0.0
	};
	public var lastGroundedPos = {cx: 0, cy: 0, level: game.currentLevel};
	public var money = 0;
	public var maxJumps = 1;
	public var jumps = 0;
	public var g:h2d.Graphics;
	public var inventory:Array<Dynamic> = [];
	public var gravity:Float = 0.05;

	public function ownItem(it) {
		return inventory.contains(it);
	}

	var outOfScreen(get, never):Bool;

	inline function get_outOfScreen()
		return !camera.isOnScreen(cx * Const.GRID, cy * Const.GRID, 32);

	var pushing(get, never):Bool;

	inline function get_pushing() {
		if (cd.has('pushingRBody'))
			return true;
		return (onGround && (cd.has("recentMove") && !crotched))
			&& (dir > 0 && ((level.hasCollision(cx + 1, cy) || level.hasCollision(cx + 1, cy - 1)) && xr > 0.7))
			|| (((level.hasCollision(cx - 1, cy) || level.hasCollision(cx - 1, cy - 1)) && xr < 0.3));
	}

	var isHoldingAction(get, never):Bool;

	inline function get_isHoldingAction()
		return ca.isHeld(Action, 0.6);

	var ladding(get, never):Bool;

	inline function get_ladding()
		return (level.hasLadder(cx, cy - 1) && (ca.isDown(MoveUp) || ca.isDown(MoveDown)));

	var landing(get, never):Bool;

	inline function get_landing()
		return dy >= 0 && (yr > 0.9 && level.hasOneWay(cx, cy + 1));

	public var crotched(get, never):Bool;

	inline function get_crotched()
		return ca.isDown(MoveDown) || stuck;

	var stuck(get, never):Bool;

	inline function get_stuck()
		return level.hasCollision(cx, cy - 1) && (level.hasCollision(cx, cy + 1));

	var onBreakable(get, never):Bool;

	inline function get_onBreakable() {
		return level.hasBreakable(cx, cy + 1);
	}

	// This is TRUE if the player is not falling
	var onGround(get, never):Bool;

	inline function get_onGround() {
		if (cd.has('recentlyOnRBody')) {
			return true;
		}
		return (cd.has("recentlyOnElevator") && puppetMaster != null)
			|| (!destroyed
				&& dy == 0
				&& yr == 1
				&& (level.hasCollision(cx, cy + 1) || level.hasOneWay(cx, cy + 1) || level.hasBreakable(cx, cy + 1)));
	}

	var onLedge(get, never):Bool;

	inline function get_onLedge() {
		return (dy >= 0 && (!onGround && !crotched) && (ca.isDown(MoveUp) || ca.isDown(Jump)))
			&& ((dir < 0 && (level.hasCollTypes(cx - 1, cy - 1, [1, 3]) && !level.hasCollTypes(cx - 1, cy - 2, [1, 3])))
				|| (dir > 0 && (level.hasCollTypes(cx + 1, cy - 1, [1, 3]) && !level.hasCollTypes(cx + 1, cy - 2, [1, 3]))));
	}

	var onEdge(get, never):Bool;

	inline function get_onEdge() {
		/*var ret = onGround && (
				(!level.hasCollTypes(cx + 1, cy + 1, [0, 1, 2, 3, 4, 5, 6]) && xr > 0.7)
					|| (!level.hasCollTypes(cx - 1, cy + 1, [0, 1, 2, 3, 4, 5, 6]) && xr < 0.3));
			// && (cd.has("recentlyOnGround") || onLedge)
			trace(ret);
			return ret; */
		return (onGround && !cd.has("recentlyOnElevator"))
			&& ((!level.hasCollision(cx + 1, cy + 1) && xr > 0.7) || (!level.hasCollision(cx - 1, cy + 1) && xr < 0.3));
	}

	public var jumpResource:Sound = null;
	public var wrongResource:Sound = null;
	public var fallResource:Sound = null;
	public var goodResource:Sound = null;
	public var upgradeResource:Sound = null;
	public var doorResource:Sound = null;
	public var giftResource:Sound = null;

	public function new() {
		super(0, 0);
		maxLife = 4;
		life = maxLife;
		#if hl
		if (hxd.res.Sound.supportedFormat(OggVorbis)) {
			jumpResource = hxd.Res.sounds.jump;
			wrongResource = hxd.Res.sounds.wrong;
			fallResource = hxd.Res.sounds.fall;
			goodResource = hxd.Res.sounds.good;
			doorResource = hxd.Res.sounds.sfx_door;
			upgradeResource = hxd.Res.sounds.sfx_upgrade;
			giftResource = hxd.Res.sounds.gift;
		}
		if (hxd.res.Sound.supportedFormat(Mp3)) {
			jumpResource = hxd.Res.sounds.jump;
			wrongResource = hxd.Res.sounds.wrong;
			fallResource = hxd.Res.sounds.fall;
			goodResource = hxd.Res.sounds.good;
			doorResource = hxd.Res.sounds.sfx_door;
			upgradeResource = hxd.Res.sounds.sfx_upgrade;
			giftResource = hxd.Res.sounds.gift;
		}
		#end
		// Start point using level entity "PlayerStart"
		start = level.data.l_Entities.all_PlayerStart[0];
		if (start != null) {
			setPosCase(start.cx, start.cy);
		} else {}

		// Misc inits
		frictX = 0.72;
		frictY = 0.9876;

		// Camera tracks this
		camera.trackEntity(this, false, 2);
		camera.clampToLevelBounds = true; // false;

		// camera.zoomTo(2.5);

		// Init controller
		ca = App.ME.controller.createAccess();
		ca.lockCondition = Game.isGameControllerLocked;

		// Placeholder display
		spr.set(Assets.hero);
		/*shadeNorm = new NormalShader();
			shadeNorm.texture = spr.tile.getTexture();
			shadeNorm.normal = spr.tile.getTexture();
			shadeNorm.mp = new Vector(0, 0, 0);
			Game.ME.root.getScene().filter=(shadeNorm); */
		spr.filter = new h2d.filter.Group([new dn.heaps.filter.PixelOutline(0x330000, 0.4)]);

		/*spr.anim.registerStateAnim(anims.cineFall, 99, ()->cd.has("cineFalling") && !onGround );
			spr.anim.registerStateAnim(anims.deathJump, 99, ()->life<=0 && !onGround );
			spr.anim.registerStateAnim(anims.deathLand, 99, ()->life<=0 && onGround);
			spr.anim.registerStateAnim(anims.kickCharge, 8, ()->isChargingAction("kickDoor") );
			spr.anim.registerStateAnim(anims.climbMove, 8, ()->climbing && climbSpeed!=0 );
			spr.anim.registerStateAnim(anims.climbIdle, 8, ()->climbing && climbSpeed==0 );
			spr.anim.registerStateAnim(anims.jumpUp, 7, ()->!onGround && dy<0.1 );

			spr.anim.registerStateAnim(anims.run, 5, 1.3, ()->onGround && M.fabs(dxTotal)>0.05 );
			spr.anim.registerStateAnim(anims.shootUp, 3, ()->isWatering() && verticalAiming<0 );
			spr.anim.registerStateAnim(anims.shootDown, 3, ()->isWatering() && verticalAiming>0 );
			spr.anim.registerStateAnim(anims.shoot, 3, ()->isWatering() && verticalAiming==0 );
			spr.anim.registerStateAnim(anims.shootCharge, 2, ()->isChargingAction("water") );
			spr.anim.registerStateAnim(anims.idleCrouch, 1, ()->!cd.has("recentMove")); */

		spr.anim.registerStateAnim(anims.jump, 6, () -> !onGround);
		spr.anim.registerStateAnim(anims.idle, 0);
		spr.anim.registerStateAnim(anims.walk, 3, () -> cd.has("recentMove")); // M.fabs(dxTotal)>0
		spr.anim.registerStateAnim(anims.croutched, 8, () -> (crotched || stuck));
		spr.anim.registerStateAnim(anims.idleCroutched, 7, () -> crotched && !cd.has("recentMove"));
		spr.anim.registerStateAnim(anims.falling, 9, () -> !onGround && dy > 0.2 && !ladding);
		spr.anim.registerStateAnim(anims.wallPush, 5, () -> pushing);
		spr.anim.registerStateAnim(anims.ledged, 10, () -> onLedge);
		spr.anim.registerStateAnim(anims.ladding, 11, () -> ladding);
		spr.anim.registerStateAnim(anims.attack, 12, () -> cd.has("attacking"));
		spr.anim.registerStateAnim(anims.death, 56, () -> life <= 0 && cd.has("dying"));
		spr.anim.registerStateAnim(anims.dead, 55, () -> life <= 0);
		spr.anim.registerStateAnim(anims.roulade, 57, () -> onGround && cd.has("roulade"));
		spr.anim.registerStateAnim(anims.edging, 59, () -> onEdge && !onLedge); // && onGround

		g = new h2d.Graphics(spr);
		// g.bevel = 0.25;
		// g.beginFill(0x00ff00);
		// g.drawRect(-12*0.5,-24,12,24);
		cd.setS("transitionOut", 1);

		lastGroundedPos.cx = cx;
		lastGroundedPos.cy = cy;
		lastGroundedPos.level = game.currentLevel;
		// spr.scale(0.5);
	}

	override function dispose() {
		super.dispose();
		ca.dispose(); // don't forget to dispose controller accesses
	}

	/** X collisions **/
	override function onPreStepX() {
		super.onPreStepX();

		if (onLedge) {
			if (xr > 0.6) {
				xr = 0.6;
				if (cd.getS("wasLedged") < 0.8) {
					dy = -0.85;
					dx = 0.25;
				}
			} else if (xr < 0.4) {
				if (cd.getS("wasLedged") < 0.8) {
					dy = -0.85;
					dx = -0.25;
				}
				xr = 0.4;
			}
		} else {
			cd.setS("wasLedged", 1.5);
		}

		// Right collision
		if (xr > 0.8 && level.hasCollision(cx + 1, cy)) {
			xr = 0.8;
			if (yr < 0.15 && (onGround && !level.hasCollision(cx + 1, cy - 1))) {
				cy--;
				yr = 1;
			}
		}
		if (xr > 0.8 && level.hasCollision(cx + 1, cy - 1)) {
			if (!crotched && !cd.has("roulade"))
				xr = 0.8;
		}
		// Left collision
		if (xr < 0.2 && level.hasCollision(cx - 1, cy)) {
			xr = 0.2;
			if (yr < 0.15 && (onGround && !level.hasCollision(cx - 1, cy - 1))) {
				cy--;
				yr = 1;
			}
		}
		if (xr < 0.2 && level.hasCollision(cx - 1, cy - 1)) {
			if (!crotched && !cd.has("roulade"))
				xr = 0.2;
		}
	}

	/** Y collisions **/
	override function onPreStepY() {
		super.onPreStepY();

		/*if(onGround && dy==0 && !cd.has("deathScreen") && !cd.has("toohigh")){
			lastGroundedPos.cx=cx;
			lastGroundedPos.cy=cy;
		}*/

		if (onLedge) {
			dy = 0;
			yr = 0.7;
		}

		/*if(level.hasCollTypes(cx-1,cy,[4])){
			trace("on a door");
			if(ca.isDown(Action)){
				dy=-2;
				jumpResource.play(false).volume=0.5;
			}
		}*/

		// spikes
		if (level.hasCollTypes(cx, cy - 1, [4]) && yr < 0.5 && !cd.has("invincible")) {
			// cd.setS("tooHigh",0.1);
			cd.setMs("invincible", 2000);
			blink(0xff0000);
			fx.bloodSpread(spr.x, spr.y - 32);
			life--;
			cd.setS("greyScale", 5);
		}
		if (level.hasCollTypes(cx, cy, [4]) && !cd.has("invincible")) {
			// cd.setS("tooHigh",0.1);
			cd.setMs("invincible", 2000);
			fx.bloodSpread(spr.x, spr.y);
			blink(0xff0000);
			life--;
			cd.setS("greyScale", 5);
		}

		// echelles
		if (level.hasLadder(cx, cy)) {
			if (ca.isDown(MoveUp)) {
				dy = 0;
				dy = -0.21;
			} else if (ca.isDown(MoveDown)) {
				dy = 0;
				dy = 0.21;
			} else if (!cd.has("wasPressingJump")) {
				dy = 0;
			}
		}
		// planchette
		if (ca.isPressed(Action) && ca.isDown(MoveDown)) {
			cd.setMs("slideDown", 100);
		}
		// breakable breaking
		if (onBreakable && cd.has("slideDown")) {
			level.breakables.remove(Breaks,cx,cy+1);
			camera.bump(2,8);
		}
		if (landing && !cd.has("slideDown")) {
			dy = 0;
			yr = 1;
		}

		// Land on ground
		if (yr > 1 && level.hasCollision(cx, cy + 1)) {
			setSquashY(0.5);
			// camera.bump(0,dy*dy*20);
			if (isAlive() && !cd.has("toohigh") && !cd.has("deathScreen")) {
				lastGroundedPos.cx = cx;
				lastGroundedPos.cy = cy;
				lastGroundedPos.level = game.currentLevel;
			}

			dy = 0;
			yr = 1;
			bdy = 0;
			ca.rumble(0.2, 0.06);
		}

		// sticky elevator
		if (cd.has("recentlyOnElevator") && !cd.has('wasPressingJump') && !level.hasCollision(cx, cy)) {
			// dy=0;

			setPosY(puppetMaster.attachY - 16);
			onPosManuallyChangedY();

			if (puppetMaster.dy > 0) {
				cy = Std.int(puppetMaster.cy);
				cy--;
				// dy=0.25;
				yr = puppetMaster.yr + 0.25;

				// spr.y=puppetMaster.y-24;
				// dy=0.25;
				// onPosManuallyChangedY();
				// dy=puppetMaster.dy;
				// dy+=puppetMaster.speed+0.2;
				// yr=puppetMaster.yr+0.1;
				// dy=puppetMaster.dy+0.05;
				//	yr+=0.15;
			} else {
				cy = puppetMaster.cy;
				cy--;
				yr = puppetMaster.yr;
			}
		}

		// Ceiling collision
		/*if(level.hasCollision(cx,cy-1)){
			if(crotched && yr<0.2)
				yr = 0.2;
				dy=0;
				onPosManuallyChangedY();
			if(!crotched && yr<0.5)
				yr=0.5;
				dy=0;
		}*/
		if (yr < 0.8 && level.hasCollision(cx, cy - 1)) {
			if (crotched) {
				yr = 0.8;
				dy = 0;
				onPosManuallyChangedY();
			}
		}
		if (yr < 0.2 && level.hasCollision(cx, cy - 1)) {
			yr = 0.2;
			dy = 0;
			onPosManuallyChangedY();
		}
	}

	/**
		Control inputs are checked at the beginning of the frame.
		VERY IMPORTANT NOTE: because game physics only occur during the `fixedUpdate` (at a constant 30 FPS), no physics increment should ever happen here! What this means is that you can SET a physics value (eg. see the Jump below), but not make any calculation that happens over multiple frames (eg. increment X speed when walking).
	**/
	override function preUpdate() {
		super.preUpdate();

		if (isHoldingAction) {
			cd.setS('isHoldingAction', 0.5);
		}

		if (!onLedge)
			fx.tail(spr.x, spr.y - 8, 0xff2200, getMoveAng(), M.fabs(walkSpeed * 1.2));
		if (cd.has("transitionOut")) {
			game.transitioner.alpha = 0;
		} /**/
		if (cd.has("greyScale")) {
			// game.aberration.grayScale=cd.getRatio("greyScale");
		}
		walkSpeed = 0;
		if (onGround)
			cd.setS("recentlyOnGround", 0.1); // allows "just-in-time" jumps
		/*if(isAlive() && !cd.has("tooHigh") && !cd.has("dying"))
			lastGroundedPos.cx=cx;
			lastGroundedPos.cy=cy; */
		if (outOfScreen) {
			cd.setMs('outofscreen', 100);
		}
		if (!cd.has('recentlyOnElevator')) {
			puppetMaster = null;
		}
		// down from edge
		if (ca.isPressed(Action) && ca.isDown(MoveDown) && !cd.has('getDown')) {
			cd.setMs('getDown', 500);
		}

		// oneway down

		if (ca.isDown(Jump)) {
			if (this.grapple == null) {
				this.grapple = new SampleGrapple(cast(this, Entity), getMoveAng());
				// trace(this.grapple.ang);
				g.clear();
				g.lineStyle(2, 0xffff00, 1.0);
				g.moveTo(spr.x, spr.y);
				g.lineTo(spr.x + 200 * Math.cos(-45 / 180 * Math.PI), spr.y + 200 * Math.sin(-45 / 180 * Math.PI));
				g.endFill();
			}
		}

		if ((ca.isDown(MoveDown) && ca.isPressed(Action)) && landing) {
			cd.setMs("slideDown", 100);
			dy = 0.05;
			yr = 1.1;
		}
		// roulade
		if (!cd.has("roulade")) {
			if (ca.isPressed(Action) && ((ca.isDown(MoveRight)) || (ca.isDown(MoveLeft)))) {
				spr.anim.setGlobalSpeed(1);
				cd.setMs("roulade", 400);
			}
		}

		// elevator tracker;
		if (cd.has("recentlyOnElevator") && !cd.has("startJumping")) {
			// dy=0;
			// if(ca.isPressed(Action))
			// puppetMaster.activated=!puppetMaster.activated;
			// puppetMaster.speed=0;
			/*if (dy > 0) {
					// cd.setMs("recentlyOnElevator",80);
					// dy=puppetMaster.dy;
					// yr=puppetMaster.yr;
					// cy=Std.int(puppetMaster.cy-1);
					// spr.y=puppetMaster.spr.y-32;
					// onPosManuallyChangedY();
				} else if (puppetMaster != null && spr != null) {
					// cd.setMs("recentlyOnElevator",80);
					dy = puppetMaster.dy;
					yr = puppetMaster.yr;
					cy = Std.int(puppetMaster.cy - 1);
					// spr.y=puppetMaster.spr.y-16;
					onPosManuallyChangedY();
			}*/
		}
		// computers
		var computers = Entity.ALL.filter((ent) -> ent.is(SampleComputer));

		for (com in computers) {
			if (distCase(com) < 2) {
				if (ca.isPressed(Action) && !com.cd.has("activated")) {
					com.cd.setMs("activated", 500);
				}
			}
		}

		// door
		var doors = SampleDoor.ALL;

		for (door in doors) {
			if (distCase(door) < 2 && door.spr != null) {
				if (ca.isDown(Action) && !cd.has("recentlyTeleported") && !ca.isDown(MoveDown)) {
					var isLocked = true;
					if (door.data.f_Required_Item != null) {
						if (ownItem(door.data.f_Required_Item)) {
							trace(inventory.toString());
							trace(door.data.f_Required_Item);
							say("Unlocked !", 0xff0000);
							fx.markerText(cx, cy - 2, "Unlocked !", 8);
							isLocked = false;
							door.locked = false;
							goodResource.play(false, 0.1);
							doorResource.play(false, 1.0);
						} else {
							// door.locked=true;
							wrongResource.play(false, 0.5);
							trace("item required");
							door.locked = true;
							isLocked = true;
							// var mod=new ui.Modal();
							// mod.udelayer.addMs("closing",()->{mod.close();game.resume();},1000);
							say(door.data.f_Required_Item + " required !", 0xff0000);
							fx.markerText(cx, cy - 2, door.data.f_Required_Item + " required !", 8);
							return;
						}
					} else if (door.locked == true && game.gameStats.has(door.iid + "activated")) {
						door.locked = false;
						isLocked = false;
						goodResource.play(false, 0.1);
						doorResource.play(false, 1.0);
					} else {
						isLocked = door.locked;
					}
					var target = doors.filter((ent) -> (ent.data != door.data) && ent.iid == door.data.f_Entity_ref.entityIid)[0];
					// trace("target:" + target);
					if (target != null && !cd.has("recentlyTeleported")) {
						if (target.data.f_Entity_ref.levelIid != door.data.f_Entity_ref.levelIid) {
							destination = {
								level: door.data.f_Entity_ref.levelIid,
								door: door.data.f_Entity_ref.entityIid,
								offsetX: 0.0,
								offsetY: 0.0
							};
							// target=null;
							cd.setS('recentlyTeleported', 1);
							for (lvl in Assets.worldData.levels) {
								if (lvl.iid == destination.level) {
									game.startLevel(lvl);
								}
							}
							return;
						}
					}
					if (target != null && isLocked == false && door.locked == false) {
						// camera.targetZoom(3);
						doorResource.play(false, 2.0);
						blink(0x000000);
						game.tw.createMs(game.transitioner.alpha, 1, TEaseOut, 200).end(function() {
							cx = target.cx;
							cy = target.cy;
							camera.centerOnTarget();
							camera.trackEntity(this, true, 4);
							// trace(target.data.f_Entity_ref.entityIid);
							cd.setS("recentlyTeleported", 0.5);
							cd.setS("transitionOut", 0.2);
						});
					} else if (isLocked == false) {
						// trace("no target");
						doorResource.play(false, 1.0);
						cd.setMs("recentlyTeleportedToLevel", 500);
						// cd.setMs("startLevel",100);
						// trace(level.name);
						// trace(door.data.f_Entity_ref.levelIid);
						destination = {
							level: door.data.f_Entity_ref.levelIid,
							door: door.data.f_Entity_ref.entityIid,
							offsetX: 0.0,
							offsetY: 0.0
						}
						// camera.zoomTo(3);
						/*game.pause();
							Assets.worldData.getLevelAt(door.data.)
							destination=Assets.worldData.getLevel(levelIid);
								
							trace(destination); */

						cd.setS("transitionOut", 0.2);
						// blink(0x000000);
						// game.tw.createMs(spr.alpha, 0, TLinear, 100).end(() -> ca.lock());
					}
					if (isLocked == false) {
						say("Let's Go !", 0xff00ff);
						if (door.spr.anim.isPlaying("closed"))
							door.spr.anim.play("open").chain("opened");
						if (door.spr.anim.isPlaying("opened"))
							door.spr.anim.play("opened");
						// game.scroller.under(door.spr);
					}
				}
			} else if (door.spr != null) {
				if (door.spr.anim.isPlaying("opened"))
					door.spr.anim.play("close").chain("closed");
			}
		}

		// pre-jump
		if (ca.isPressed(Jump) || ca.isPressed(MoveUp)) {
			cd.setMs("wasPressingJump", 200);
		}

		if (ca.isPressed(Attack) && !cd.has("attacking")) {
			cd.setMs("attacking", 400);
			spr.anim.chain(anims.attack, 1).setStateAnimSpeed("attack", 2.0);
			// hud.notify("Fighting !");
			fx.spyraleRotation(centerX, centerY, 0xffee55, dir);
		}

		if (ca.isPressed(Action)) {
			cd.setMs("recentlyPressedAction", 100);
		}

		// fire
		if (ca.isPressed(SuperAttack) && cd.getMs('recentlyFire') <= 0.1) {
			cd.setMs("recentlyFire", 0.25);
			cd.setS("recentMove", 0.2);
			game.stopFrame();
			fx.flashBangS(0xffffff, 0.9, 0.025);

			fx.spyraleRotation(centerX, centerY, 0xeeff55, dir);
			// fx.dotsExplosionExample(centerX, centerY, 0xffcc00);

			/*var s=new SampleSlime();
				s.cx=cx+dir;
				s.cy=cy;
				s.dir=dir;
				//onPosManuallyChangedY();
				game.scroller.over(spr); */
		}
		// Crotch
		if (crotched) {
			// setSquashY(0.9);
			// set_hei(12);
		} else {
			// set_hei(24);
		}
		if (ca.isPressed(MoveDown))
			setSquashY(0.8);
		if (ca.isPressed(Jump))
			setSquashX(0.8);

		// Walk
		if (ca.getAnalogDist2(MoveLeft, MoveRight) > 0) {
			// As mentioned above, we don't touch physics values (eg. `dx`) here. We just store some "requested walk speed", which will be applied to actual physics in fixedUpdate.
			walkSpeed = ca.getAnalogValue2(MoveLeft, MoveRight); // -1 to 1
			cd.setS("recentMove", 0.2);
		}
		if (ca.isKeyboardPressed(K.NUMPAD_9)) {
			game.manager.masterVolume < 0.9 ? game.manager.masterVolume += 0.1 : 0;
			trace(game.manager.masterVolume);
		}
		if (ca.isKeyboardPressed(K.NUMPAD_3)) {
			game.manager.masterVolume > 0.1 ? game.manager.masterVolume -= 0.1 : 0;
			trace(game.manager.masterVolume);
		}
	}

	public function checkAchievements() {
		if (game.gameStats.has('Fixed_fuse') && !game.gameStats.has('story_line_1')) {
			var story = new Achievement("story_line_1", "done", () -> return game.gameStats.has('Fixed_fuse'), () -> {
				trace("Bien Joué, on va pouvoir reboot le générateur principal.");
				hud.notify("Bien Joué, on va pouvoir reboot le générateur principal.");
				game.pause();
			});
			game.gameStats.registerState(story);
		}
	}

	override function fixedUpdate() {
		super.fixedUpdate();
		checkAchievements();
		/*shadeNorm.mp.x = spr.x;
			shadeNorm.mp.y = spr.y; */

		// elevator tracker;

		if (cd.has("recentlyOnElevator") && !cd.has("startJumping") && puppetMaster != null) {
			// dy=puppetMaster.dy;
			/*if (puppetMaster.dy == 0)
					
				spr.y = puppetMaster.y - 16;

				onPosManuallyChangedY(); */

			// puppetMaster.spr.parent.addChild(spr);
			// dy = 0;
			// setPosY(puppetMaster.spr.y-16);
			// onPosManuallyChangedY();
		}

		var slimes = Entity.ALL.filter((ent) -> ent.is(SampleSlime));
		for (slime in slimes) {
			if (cd.has("attacking") && distPx(slime) <= 16) {
				cd.unset("attacking");
				// hud.notify("outch!");
				slime.destroy();
			}
			if (!cd.has("attacking") && distCase(slime) < 1) {
				if (!cd.has("invincible") && !cd.has("roulade")) {
					bdy -= 0.25;
					bdx -= dir * 0.25;
					life--;
					game.stopFrame();
					cd.setMs("invincible", 2000);
					blink(0xff0000);
				}
			}
		}
		if (cd.has("invincible") && !cd.has("clignotage")) {
			blink(0xffffff);
			cd.setMs("clignotage", 200);
			// fx.markerText(cx,cy-2,"Attention!",10);
		}
		if (cd.has("recentlyTeleportedToLevel") && !cd.has("startlevel")) {
			cd.setS("startlevel", 1);
			// trace(Assets.worldData.levels);
			// camera.zoomTo(3);
			game.tw.createMs(game.transitioner.alpha, 0 > 1, TEaseOut, 100).end(function() {
				for (lvl in Assets.worldData.levels) {
					if (lvl.iid == destination.level) {
						hud.notify('téléportinge');
						spr.alpha = 1;
						ca.unlock();

						game.startLevel(lvl);
					}
				}
			});

			// game.pause();
		}
		if ((!isAlive()) && !cd.has("deathScreen")) { // || !outOfScreen
			cd.setMs("deathScreen", 1000);
			cd.setS("transitionOut", 0.1);
			game.delayer.addS("backinplace", function() {
				cx = lastGroundedPos.cx;
				cy = lastGroundedPos.cy;
				cancelVelocities();
				onPosManuallyChangedBoth();
				initLife(maxLife);
				if (lastGroundedPos.level != game.currentLevel)
					trace('back in place aborded');
				game.startLevel(lastGroundedPos.level);
			}, 0.1);
		}
		if (cd.has("transitionOut"))
			game.transitioner.alpha = 0; // cd.getRatio("transitionOut");

		game.disp.normalMap.scrollDiscrete(1, -2);

		// Gravity
		if (!onGround && !cd.has("recentlyOnElevator") && !ladding)
			dy += gravity * 1.5; // 0.05
		if (dy > 1.5)
			dy = 1.5;
		if (cd.has('recentlyOnElevator') && !cd.has('startJumping')) {
			dy = 0; // puppetMaster.dy;
		}
		if (dyTotal >= 1.5 && isAlive() && !cd.has("toohigh"))
			cd.setMs("toohigh", 1000);

		if (cd.has("toohigh") && isAlive()) {
			if (onGround && !onLedge) {
				cd.unset("toohigh");
				life = 0;
				setAffectS(Stun, 1.5, true);
				cd.setMs("dying", 400);
				game.addSlowMo("ouf", 1, 0.6);
				say("AAAAAAAAAH!", 0xff0000);
				fx.markerText(cx, cy - 2, "Ah!", 4);
				fx.flashLight(0xff0000, 0.5, 1);
				cd.setS("transitioning", 1);
				fallResource.play(false).volume = 1.0;
			} else if (onLedge && (ca.isDown(MoveUp) || ca.isDown(MoveDown))) {
				dy = 0;
				cd.unset("toohigh");
				// cd.setS("slowmo",1.5);
				fx.flashLight(0xffffff, 0.5, 1);
				game.stopFrame();
				game.addSlowMo("ouf", 1, 0.6);
				camera.forceZoom(3);
				game.tw.createS(spr.alpha, 1, TLinear, 1.5).end(() -> camera.forceZoom(1.8));
				fx.markerText(cx, cy - 2, "Ouf!", 4);
			}
		}
		if (cd.has("slowmo")) {
			App.ME.setTimeMultiplier(0.25);
		} else {
			App.ME.setTimeMultiplier(1);
		}
		if (hasAffect(Stun) && cd.has("dying"))
			cancelVelocities();
		// debug(Std.int(life));

		if (!isAlive() || (hasAffect(Stun)) || game.cd.has("sepia") || game.cd.has("titleScreen")) {
			ca.lock();
		} else {
			ca.unlock();
		}

		if (hasAffect(Stun)) {
			trace("Stunning");
			if (!cd.has("alphaBlink")) {
				spr.alpha = 0;
				cd.setMs("alphaBlink", 250);
			} else if (!cd.has("pauseBlink")) {
				spr.alpha = 1;
				cd.setMs("pauseBlink", 250);
			}
		}

		if (cd.has("recentlyOnElevator") && !cd.has('startJumping')) { // && puppetMaster.dy > 0
			// dy=puppetMaster.dy;
			yr = puppetMaster.yr;
			cy = M.floor(puppetMaster.cy - 1);
			// spr.y = puppetMaster.top - 16;
			onPosManuallyChangedY();
			// cancelVelocities();
		}
		// Apply requested walk movement

		// fx.tail(spr.x,spr.y,getMoveAng());

		// getdown
		if (cd.has('getDown')) {
			cd.unset('getDown');
			if (onGround && !level.hasCollision(cx - 1, cy + 1)) {
				dir = 1;
				xr = -0.2;
				dy = 0;
				cy = cy + 1;
				yr = 0.1;
			} else if (onGround && !level.hasCollision(cx + 1, cy + 1)) {
				dir = -1;
				xr = 1.2;
				dy = 0;
				cy = cy + 1;
				yr = 0.1;
			} else if (!onGround) {
				dy = 0.5;
				dx = 0.0;
				cd.setMs("slamDown", 250);
			}
		}

		// slamDown
		if (cd.has('slamDown')) {
			fx.lumiere(spr.x, spr.y, 0xffffff, 16);
		}

		// Jump
		if ((cd.has("recentlyOnGround") && !stuck) && cd.has("wasPressingJump")) {
			if (life > 0 && !cd.has("toohigh") && !cd.has("deathScreen")) {
				lastGroundedPos.cx = cx;
				lastGroundedPos.cy = cy;
				lastGroundedPos.level = game.currentLevel;
			}
			setSquashX(0.6);
			cd.unset("recentlyOnGround");
			cd.unset("wasPressingJump");
			fx.dotsExplosionExample(centerX, centerY, 0xffcc00);
			// ca.rumble(0.05, 0.06);
			cd.setS("recentMove", 0.2);
			dy = -0.0514;
			jumps = 1;
			if (cd.has("recentlyOnElevator")) {
				// dy -= M.fabs(puppetMaster.dy);
			}
			cd.setS("startJumping", 0.36);
			jumpResource.play(false).volume = 0.5;
		}
		// double jump
		if (!onGround && dy > 0 && cd.has('wasPressingJump') && jumps < maxJumps) {
			cd.unset("recentlyOnGround");
			cd.unset("wasPressingJump");
			jumps++;
			fx.dotsExplosionExample(centerX, centerY, 0xffcc00);
			// ca.rumble(0.05, 0.06);
			cd.setS("recentMove", 0.2);
			dy = -0.0514;
			cd.setS("startJumping", 0.36);
			jumpResource.play(false).volume = 0.5;
		}
		if (cd.has("startJumping")) {
			if (ca.isDown(MoveUp) || ca.isDown(Jump)) {
				dy -= cd.getS("startJumping") * 0.425;
			}
		}

		if (walkSpeed != 0) {
			var speed = (stuck && !cd.has('roulade')) ? 0.01 : 0.05;

			if (cd.has('roulade')) {
				speed *= 2.05;
			}

			dx += walkSpeed * speed;
			dir = dx > 0 ? 1 : -1;
			if (spr.anim.isPlaying("walk")) {
				spr.anim.setGlobalSpeed(M.fabs(dx) * 8);
			} else {
				spr.anim.setGlobalSpeed(1);
			}
			if (M.fabs(dx) > 0.1)
				fx.smogg(attachX, attachY, 0xaaaaaa, 0.25);
		} else {
			if (stuck && cd.has('roulade')) {
				dir = dx > 0 ? 1 : -1;
				dx += dir * 0.1;
				cd.unset('roulade');
				cd.setMs('roulade', 60);
			}
		}
		// fx.lumiere(spr.x,spr.y,0xffffff,16);
		/*if(level.hasForground(cx,cy,1) && !cd.has("alphaTween") && Game.ME.forgroundLayer.alpha==1){
				cd.setMs("alphaTween",50);
				game.tw.createMs(Game.ME.forgroundLayer.alpha,0.5,TLinear,50);
				//Game.ME.forgroundLayer.blendMode=SoftAdd;
			}else if(!cd.has("alphaTween") && Game.ME.forgroundLayer.alpha==0.5){
				cd.setMs("alphaTween",50);
				game.tw.createMs(Game.ME.forgroundLayer.alpha,1,TLinear,50);
				//Game.ME.forgroundLayer.blendMode=None;
		}*/
		#if hl
		if (game.socket != null && !cd.has('sendData')) {
			if (walkSpeed != 0) {
				cd.setMs('sendData', 100);

				try {
					var req:Dynamic = Json.stringify({
						type: "move",
						who: game.socket.uid,
						x: attachX,
						y: attachY
					});
					Game.ME.socket.sendMessage(req); // +'\r\n'
				} catch (e:Dynamic) {
					trace("ça marche pas: " + e);
				}
			}
		}
		#end
	}
}
