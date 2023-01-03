package sample;

import h2d.col.Point;
import h2d.filter.Bloom;

/**
	SamplePlayer is an Entity with some extra functionalities:
	- falls with gravity
	- has basic level collisions
	- controllable (using gamepad or keyboard)
	- some squash animations, because it's cheap and they do the job
**/

class SampleElevator extends Entity {
	public static var ALL : Array<SampleElevator> = [];
	public var dirY:Int=-1;
	//public var activated:Bool=true;
	//public var iid:Null<String>;
	public var startY:Int=0;
	public var endY:Int=0;
	public var speed:Float=0;
	public var maxSpeed:Float=0.25;
	public function new(ent:Entity_Elevator) {
		super(ent.cx,ent.cy);
		activated=ent.f_activated;
		ALL.push(this);
		setPosCase(ent.cx,ent.cy);
		iid=ent.iid;
		dirY=ent.f_dirY;
		startY = M.floor(Math.min(ent.f_startPoint.cy,ent.f_endPoint.cy));
		endY= M.floor(Math.max(ent.f_startPoint.cy,ent.f_endPoint.cy));
		// Placeholder display

		var outline=spr.filter = new dn.heaps.filter.PixelOutline(0x330000, 0.4);
		var bloom = new h2d.filter.Glow(0xeeffee,0.5,4,0.5,1,true);
		var group = new h2d.filter.Group([outline,bloom]);
		spr.filter = group;
		spr.set(Assets.elevator);

		var g = new h2d.Graphics(spr);
		var anims = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.elevator );
		spr.anim.registerStateAnim(anims.idle, 0);


		
		
		
	}


	override function dispose() {
		super.dispose();
		
	}

	override function preUpdate() {
		super.preUpdate();
		if(game.player.centerX >= left-16 && game.player.centerX <= right+16){
			
			//trace('okX');
			//if(game.player.attachY>=top && game.player.attachY<=bottom){//distCase(game.player.cx,game.player.cy,game.player.xr,game.player.yr)<=1
			if((game.player.attachY>=attachY-16 && game.player.attachY<attachY ) && (!game.player.cd.has("startJumping") || !game.player.cd.has("slamDown"))){	
				game.player.cd.setMs("recentlyOnElevator",33);
				game.player.puppetMaster=this;
				//game.player.dy=0;
				//game.player.cancelVelocities();
				//game.player.spr.y=spr.y-24;
				//game.player.onPosManuallyChangedY();
				//trace("bim!");
				//game.player.dy=dy;
				//game.player.setPosY(top);
				//game.player.onPosManuallyChangedY();

			}
		}

	}

	override function fixedUpdate() {
		super.fixedUpdate();
		
		//debug(dirY<0?"Up":"Down");
		if(activated==true){
			speed<maxSpeed?speed+= 0.01:speed=maxSpeed;
			//speed=maxSpeed;
			dy=dirY* speed;
			if(dirY>0 && (cy==endY && yr>0.5)){ // en bas
				yr=1;
				dirY*=-1;
				dy=0;
				activated=false;
				speed=0;
			}else if(dirY<0 && (cy==startY && yr<0.5)){ // en haut
				yr=1;
				dirY*=-1;
				dy=0;
				activated=false;
				speed=0;
			}
			if(cy<Std.int(startY+1)) cy=Std.int(startY);
			if(cy>endY) cy=endY;
		}
	}

}