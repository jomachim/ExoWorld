package sample;

import dn.Delayer;
import h2d.filter.Bloom;

/**
	SamplePlayer is an Entity with some extra functionalities:
	- falls with gravity
	- has basic level collisions
	- controllable (using gamepad or keyboard)
	- some squash animations, because it's cheap and they do the job
**/

class SampleRobot extends Entity {
	public static var ALL : Array<SampleRobot> = [];
	var anims = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.bot );
	var walkSpeed = 0.;
	var laz:HSprite;
	var delayer=new dn.Delayer(Const.FPS);
	// This is TRUE if the player is not falling
	var onGround(get,never) : Bool;
		inline function get_onGround() return !destroyed && dy==0 && yr==1 && (level.hasCollision(cx,cy+1) || level.hasOneWay(cx,cy+1));

	public function new() {
		super(5,5);

		// Start point using level entity "PlayerStart"
		var start = level.data.l_Entities.all_PlayerStart[0];
		if( start!=null )
			setPosCase(start.cx, start.cy);

		// Misc inits
		frictX = 1;
		frictY = 0.84;
		//sprScaleX=M.frand()*0.25 + 0.25;
		//sprScaleY=sprScaleX;
		dx=0.2;
		dir=1;

		

		// Placeholder display

		var outline=new dn.heaps.filter.PixelOutline(0x330000, 0.8);
		var bloom = new h2d.filter.Glow(0xeeffee,0.5,4,0.5,1,true);
		var group = new h2d.filter.Group([outline]);
		//spr.filter = group;
		spr.set(Assets.bot);
		
		spr.anim.registerStateAnim(anims.idle, 0);

		laz=new HSprite(spr);
		laz.set(Assets.lazer);
		laz.anim.registerStateAnim(anims.idle, 0);
		laz.scaleY=0.25;
		laz.alpha=0.8;
		laz.x=12;
		laz.y=-30;
		laz.tileWrap=true;
		//laz.filter=new h2d.filter.Glow(0x57e6ff,0.8,63,2.5);
		var g = new h2d.Graphics(spr);
		//g.bevel=0.25;
		//g.beginFill(0x00ff00);
		//g.drawRect(-12*0.5,-24,12,24);
	}


	override function dispose() {
		super.dispose();
		
	}


	/** X collisions **/
	override function onPreStepX() {
		super.onPreStepX();

		// Right collision
		if( xr>0.8 && level.hasCollision(cx+1,cy)){
			xr = 0.8;	
			dir=-1;	
		}
		
		// Left collision
		if( xr<0.2 && level.hasCollision(cx-1,cy)){
			xr = 0.2;
			dir=1;
		}
		
	}


	/** Y collisions **/
	override function onPreStepY() {
		
		super.onPreStepY();

		// Land on ground
		if( yr>1 && (level.hasCollision(cx,cy+1) || level.hasOneWay(cx,cy+1))) {
			setSquashY(0.5);
			
			dy = 0;
			yr = 1;
			
		}

		
		if(yr<0.2 && level.hasCollision(cx,cy-1)){
			yr = 0.2;
			dy=0;
			onPosManuallyChangedY();	
		}
	}


	/**
		Control inputs are checked at the beginning of the frame.
		VERY IMPORTANT NOTE: because game physics only occur during the `fixedUpdate` (at a constant 30 FPS), no physics increment should ever happen here! What this means is that you can SET a physics value (eg. see the Jump below), but not make any calculation that happens over multiple frames (eg. increment X speed when walking).
	**/
	override function preUpdate() {
		super.preUpdate();
		
		if( onGround )
			cd.setS("recentlyOnGround",0.1); // allows "just-in-time" jumps
			walkSpeed=dir;

		if(sightCheck(game.player) &&
			 distCase(game.player) <= 6 &&
		 !cd.has("canfire") && ((dir==1 && game.player.cx>=cx) || (dir==-1 && game.player.cx<=cx))
		 ){
			cd.setMs('canfire',1000);
			cd.setMs('lazer',250);		
		}

	}


	override function fixedUpdate() {
		super.fixedUpdate();
		//spr.colorize(0xffffff,0.5);
		if(cd.has('lazer') && isOnScreenBounds()==true){
			if(game.player.cy==cy){
				laz.alpha=cd.getRatio('lazer');
				laz.scaleX=distPx(game.player)/16.0;
				//laz.scaleY=cd.getRatio('lazer');
				blink(0xffffff);
				bdx=-dir*0.01;
				if(!game.player.crotched && !game.player.cd.has("roulade")){
					
					if(!game.player.cd.has("invincible")){
						game.player.bdx=dir*0.1;
						game.player.life--;
						game.player.cd.setMs("invincible",800);
					}
				}
			}

		}else{
			laz.alpha=0;
		}
		
		// Gravity
		if( !onGround )
			dy+=0.05;

		// Apply requested walk movement
		if( walkSpeed!=0 && onGround) {
			var speed = 0.045;
			dx = walkSpeed * speed;
			
		}
		if(cd.has("lazer")){
			dx=0;
		}
	}
}