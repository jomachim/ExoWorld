package sample;

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
class SampleComputer extends Entity {
	public static var ALL : Array<SampleComputer> = [];
	var anims = dn.heaps.assets.Aseprite.getDict(hxd.Res.atlas.computer);
	var goodRessource:Sound = null;
	var wrongRessource:Sound = null;
	var ready(get, never):Bool;

	inline function get_ready()
		return spr.anim.getAnimId() == anims.idle;

	public function new(ent:Entity_Computer) {
		if (hxd.res.Sound.supportedFormat(OggVorbis)) {
			goodRessource = hxd.Res.sounds.good;
		}
		if (hxd.res.Sound.supportedFormat(Mp3)) {
			goodRessource = hxd.Res.sounds.good;
		}
		if (hxd.res.Sound.supportedFormat(OggVorbis)) {
			wrongRessource = hxd.Res.sounds.wrong;
		}
		if (hxd.res.Sound.supportedFormat(Mp3)) {
			wrongRessource = hxd.Res.sounds.wrong;
		}
		super(ent.cx, ent.cy);
		setPosCase(ent.cx, ent.cy);
		// Placeholder display

		data = ent;
		var outline = spr.filter = new dn.heaps.filter.PixelOutline(0x330000, 0.4);
		var bloom = new h2d.filter.Glow(0xeeffee, 0.5, 4, 0.5, 1, true);
		var group = new h2d.filter.Group([outline, bloom]);
		spr.filter = group;
		spr.set(Assets.computer);

		// spr.anim.registerStateAnim(anims.closed, 2,()->cd.getS("recentlyTeleported")>0);
		spr.anim.registerStateAnim(anims.idle, 0);
		spr.anim.registerStateAnim(anims.idle2, 1, () -> distCase(game.player) <= 2);

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
		if (distCase(game.player) <= 2 && !cd.has("canard")) {
			fx.markerText(cx, cy - 2, "Press ACTION", 5.0);
			cd.setS("canard", 5.0);
		};

		if (cd.has("activated") && !cd.has("recentlyActivated")) {
			cd.unset("activated");
			var len=data.f_Entity_ref.length;
			for ( i in 0...len) {
				var ref= data.f_Entity_ref[i];
				if(Entity.ALL.filter((ent)->{return ent.iid==ref.entityIid;}).length==0
					 &&	!game.gameStats.has(ref.entityIid+"activated")){
					trace("ENTITY IS NOT IN THIS LEVEL");
					var ach=new Achievement(ref.entityIid+"activated","Activated",()->return true,
					()->{
						//trace("BIEN PLAYED");
					});
					game.gameStats.registerState(ach);
					goodRessource.play().volume = 0.25;
					hud.notify("something happened...");
				}
				for (rep in sample.Repeater.ALL){
					if(rep.iid == ref.entityIid){
						rep.activated=true;
						goodRessource.play().volume = 0.25;
					}
				}
				for (elev in SampleElevator.ALL) {
					if (elev.iid == ref.entityIid) {
						if (elev.activated == false) {
							elev.activated = true;
							goodRessource.play().volume = 0.25;
							spr.anim.play("check");
							hud.notify("activation");
							cd.setMs("recentlyActivated", 800);
							 //camera.trackEntity(elev,false,1);
							 //game.ca.lock();
							 /*cd.setS("showTargetElevator",2,true,()->{
								game.ca.unlock();
								
								camera.trackEntity(game.player,true,0.2);
							 });*/
						} else {
							fx.markerText(cx, cy + 2, "Please, wait...", 4);
							wrongRessource.play().volume = 0.25;
							spr.anim.play("wrong");
							cd.setMs("recentlyActivated", 800);
						}
					}
				}

				for (en in SampleChest.ALL) {
					if (en.data.iid == ref.entityIid) {
						
						fx.markerEntity(en);
						//goodRessource.play().volume = 0.25;
						if (en.locked == false) {
							en.locked = true;
							goodRessource.play().volume = 0.5;
							spr.anim.play("check");
							hud.notify("activation");
							cd.setMs("recentlyActivated", 800);
						} else {
							en.locked = false;
							fx.markerText(cx, cy + 2, "Please, wait...", 4);
							wrongRessource.play().volume = 0.5;
							spr.anim.play("wrong");
							cd.setMs("recentlyActivated", 800);
						}
					}
				}

				for( light in SampleLight.ALL){
					if(light.data.iid==ref.entityIid){
						light.activated=!light.activated;
						if(light.activated==true){
							//trace("shine like a bright light");
						}
					}
				}
				
				for( rec in sample.SampleExitRect.ExitRect.ALL){
					if(rec.data.iid==ref.entityIid){
						rec.activated=true;
						rec.locked=false;
					}
				}

				for(tut in SampleTutorial.Tutorial.ALL){
					if(tut.data.iid==ref.entityIid){
						tut.activated=true;
						tut.show();
					}
					
				}
			}
		}
	}
}
