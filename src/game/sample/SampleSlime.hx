package sample;

import h2d.filter.Bloom;

/**
	SamplePlayer is an Entity with some extra functionalities:
	- falls with gravity
	- has basic level collisions
	- controllable (using gamepad or keyboard)
	- some squash animations, because it's cheap and they do the job
**/

class SampleSlime extends Entity {
	public static var ALL : Array<SampleSlime> = [];
	var anims = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.slime );
	var walkSpeed = 0.;

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
		sprScaleX=M.frand()*0.25 + 0.25;
		sprScaleY=sprScaleX;
		dx=0.2;
		dir=1;

		

		// Placeholder display

		var outline=spr.filter = new dn.heaps.filter.PixelOutline(0x330000, 0.4);
		var bloom = new h2d.filter.Glow(0xeeffee,0.5,4,0.5,1,true);
		var group = new h2d.filter.Group([outline,bloom]);
		spr.filter = group;
		spr.set(Assets.slime);
		
		spr.anim.registerStateAnim(anims.idle, 0);


		var g = new h2d.Graphics(spr);
		g.bevel=0.25;
		g.beginFill(0x00ff00);
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
	}


	override function fixedUpdate() {
		super.fixedUpdate();
		//spr.colorize(0xffffff,0.5);
		
		
		// Gravity
		if( !onGround )
			dy+=0.05;

		// Apply requested walk movement
		if( walkSpeed!=0 && onGround) {
			var speed = 0.045;
			dx = walkSpeed * speed;
			
		}
	}
}