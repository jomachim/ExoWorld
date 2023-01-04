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

class SampleChest extends Entity {
	public static var ALL : Array<SampleChest> = []; 
	var anims = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.chest );
	//public var locked:Bool=false;
	public var requierements:Array<Dynamic>=[];
	public var loots:Array<Dynamic>=[];
	public var looted:Bool=false;
	var opened(get,never):Bool;
		inline function get_opened() return spr.anim.isPlaying(anims.opened) && locked==false;

	public function new(ch:Entity_Chest) {
		super(ch.cx,ch.cy);
		locked=ch.f_locked;
		loots=ch.f_Loots;
		looted=false;
		// Placeholder display
		iid=ch.iid;
		data=ch;
		//trace(ch.iid);
		var outline=spr.filter = new dn.heaps.filter.PixelOutline(0x330000, 0.4);
		var bloom = new h2d.filter.Glow(0xeeffee,0.5,4,0.5,1,true);
		var group = new h2d.filter.Group([outline,bloom]);
		spr.filter = group;
		spr.set(Assets.chest);
		
		
		//spr.anim.registerStateAnim(anims.closed, 2,()->cd.getS("recentlyTeleported")>0);
		spr.anim.registerStateAnim(anims.closed, 0,2,()->!looted);
		spr.anim.registerStateAnim(anims.opened, 10,2,()->looted);
		spr.anim.registerStateAnim(anims.opened, 100,2,()->game.gameStats.has(data.iid+"looted"));


		var g = new h2d.Graphics(spr);
		SampleChest.ALL.push(this);
	}


	override function dispose() {
		super.dispose();
		
	}

	override function fixedUpdate(){
		super.fixedUpdate();
		//debug(data.f_Entity_ref.entityIid,0xff0000);
		if(locked==true && game.gameStats.has(data.iid+"activated")){
			locked=false;
		}

		if(looted==true || game.gameStats.has(data.iid+"looted")){ looted=true;return;}
		
			if(distCase(game.player)<=2 && opened==false){
				if(game.player.cd.has("recentlyPressedAction")){
					if(data.f_requiered_item!=null && game.player.inventory.contains(data.f_requiered_item)){
						locked=false;
						game.player.upgradeResource.play(false,1.0);
						trace('requiered item unlocked the chest');
						game.player.inventory.remove(data.f_requiered_item);
					}
					if(locked==true){
						fx.markerText(cx,cy-2,"LOCKED");
						game.player.wrongResource.play();
					}else{
						looted=true;
						for(loot in loots){
							if(loot==Money){
								game.player.money+=irnd(1,100);
								
							}
							if(loot==Air_Rune){
								game.player.maxJumps++;
								game.player.giftResource.play(false).volume=1;
							}
							if(loot==Fire_Rune){
								game.player.canFire=true;
								game.player.giftResource.play(false).volume=1;
							}
							if(loot==Earth_Rune){
								game.player.canQuake=true;
								game.player.giftResource.play(false).volume=1;
							}
							if(loot==Water_Rune){
								game.player.canSwim=true;
								game.player.giftResource.play(false).volume=1;
							}
							if(loot==Heart){
								game.player.maxLife++;
							}
							if(!game.player.inventory.contains(loot)){
								if(!game.gameStats.has(loot+" Obtained")){
									var a= new Achievement(loot+" Obtained",loot+" Obtained",()->game.player.inventory.contains(loot));
									game.gameStats.registerState(a);
									game.player.upgradeResource.play(false,1.0);
								}
								game.player.inventory.push(loot);
							}
						}
						//trace(game.player.inventory[0]);
						game.player.goodResource.play(false,0.1);
						spr.anim.play(anims.opened);
						if(!game.gameStats.has(data.iid+"looted")){
							var a= new Achievement(data.iid+"looted","looted",()->looted==true);
							game.gameStats.registerState(a);
						}
						
					}
					
				}
			}
		
	}

}