package sample;

import GameStats.Achievement;

class TriggerRect extends Entity {
	public static var ALL : Array<TriggerRect> = [];
	public var actionString:String;
	public var done:Bool=false;
	public var once:Bool=false;
	public var target:Entity=null;
    //public var collides:Bool = false;
	var collides(get,never):Bool;
		inline function get_collides() return game.player.centerX >= left && game.player.centerX <= right && game.player.centerY >= top && game.player.centerY <= bottom;
	
	public function new(d:Entity_TriggerRect) {
		super(0,0);
		ALL.push(this);
		data = d;
		iid=d.iid;
		actionString=d.f_ActionString;
		once=d.f_Once;
		setPosCase(d.cx, d.cy);
		pivotX=0;
		pivotY=0;
		spr.set("empty");
		var g = new h2d.Graphics(spr);
		wid=d.width;//Const.SCALE;
		hei=d.height;//Const.SCALE;
		#if debug
		g.beginFill(0x00ff00,0.25);
		g.drawRect(0,0,d.width,d.height);
		#end
		


	}
    override function fixedUpdate(){
		if(done || game.cd.has("titleScreen")) return;
		if(collides){
			if(actionString=="death" && !game.player.cd.has("dying")){
				game.player.life=0;
				game.player.cd.setMs("dying",400);
				game.player.cd.setS("tooHigh",0.1);

				done=true;
			}
			if(actionString=="tuto"){
				for(tut in sample.SampleTutorial.Tutorial.ALL){
						//trace(data.f_Entity_ref.entityIid+","+tut.data.iid);
					if(tut.data.iid==data.f_Entity_ref.entityIid){
						if(once && !game.gameStats.has(tut.data.iid+"tuto")){
							tut.show();
							tut.activated=true;
							trace("showing once");
							var a=new Achievement(tut.data.iid+"tuto","tuto",()->tut.activated==true);
							game.gameStats.registerState(a);
							done=true;
						}else{
							tut.show();
							tut.activated=true;
							done=true;
						}
					}
				}
					
			}
			//trace("dedans");
			if(game.player.cd.has("recentlyPressedAction")){
				cd.setMs("triggeredRect",500);
				//trace("activation potentielle");
				done=true;
			}

			if(data.f_Entity_ref!=null && once==true){
				for(ent in Entity.ALL){
					if(ent.iid==data.f_Entity_ref.entityIid){
						ent.activated=true;
						done=true;
					}
				}
			}
			
		}
        entityVisible = !done;
    }
}