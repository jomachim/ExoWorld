// import sample.ChromaticAberrationShader;
import sample.WaterPond;
import h2d.SpriteBatch;
import h2d.Object;
import h2d.filter.Mask;
import h3d.shader.SpecularTexture;
import sample.SimpleShader;
import dn.heaps.filter.PixelOutline;
import h2d.Graphics;
import h2d.Bitmap;
import sample.SampleChest;
import sample.SampleLight;
import sample.SampleElevator;
import sample.SampleChaine;
import dn.heaps.FlowBg;
import h2d.Flow;
import ui.Modal;
import ui.Window;
import sample.SamplePlayer;
import h2d.Text;
import sample.Aberration;
import GameStats;
import Meteo;
import h3d.mat.Texture;
#if hl
import SocketClient;
#end

class Game extends dn.Process {
	public static var ME:Game;

	#if hl
	public var socket:SocketClient;
	#end

	/** Game controller (pad or keyboard) **/
	public var ca:ControllerAccess<GameAction>;

	/** Particles **/
	public var fx:Fx;

	/** Basic viewport control **/
	public var camera:Camera;

	/** GameStats Achievements **/
	public var gameStats:GameStats = new GameStats();

	public var markach:Dynamic = null;
	public var meteo:Meteo = new Meteo();

	/** Container of all visual game objects. Ths wrapper is moved around by Camera. **/
	public var scroller:h2d.Layers;

	public var warFobj:h2d.Object = null;
	public var backgroundLayer:h2d.Layers;
	public var forgroundLayer:h2d.Layers;
	public var warFogLayer:h2d.Layers;
	public var transitioner:h2d.Layers;
	public var manager:Null<hxd.snd.Manager>;
	public var itf:h2d.Text;
	public var aberration:Aberration;
	public var lifeTile:h2d.Tile = Assets.tiles.getTile(D.tiles.fxHeart0);
	public var keyTile:h2d.Tile = Assets.tiles.getTile(D.tiles.fxKey);
	public var goldkeyTile:h2d.Tile = Assets.tiles.getTile(D.tiles.fxGoldKey);
	public var idCardTile:h2d.Tile = Assets.tiles.getTile(D.tiles.fxIdCard);
	public var moneyTile:h2d.Tile = Assets.tiles.getTile(D.tiles.fxMoney);
	public var credTile:h2d.Tile = Assets.tiles.getTile(D.tiles.fxCredit_Card);
	public var uiLayer:h2d.Layers;
	public var heart_bmp:h2d.Bitmap;
	public var key_bmp:h2d.Bitmap;
	public var goldkey_bmp:h2d.Bitmap;
	public var cred_bmp:h2d.Bitmap;
	public var money_bmp:h2d.Bitmap;
	public var id_bmp:h2d.Bitmap;
	public var bmp:h2d.Bitmap;
	public var player:Null<SamplePlayer>;

	/** displacement filer **/
	public var disp:h2d.filter.Displacement;

	public var simpleShader:SimpleShader;
	public var currentFrame:Int = 0;

	// public var chroma:ChromaticAberrationShader;

	/** Level data **/
	public var level:Level;

	public var currentLevel:World_Level;

	/** UI **/
	public var hud:ui.Hud;

	/** Slow mo internal values**/
	var curGameSpeed = 1.0;

	var slowMos:Map<String, {id:String, t:Float, f:Float}> = new Map();

	// public var mapTexture:Texture=new Texture(512,512);

	public function new() {
		super(App.ME);
		#if hl
		if (socket == null)
			socket = new SocketClient();
		#end
		currentFrame = 0;
		ME = this;
		ca = App.ME.controller.createAccess();
		ca.lockCondition = isGameControllerLocked;
		engine.backgroundColor = 0x000000;
		createRootInLayers(App.ME.root, Const.DP_BG);
		disp = new h2d.filter.Displacement(Assets.normdisp.tile, 1, 1);
		backgroundLayer = new h2d.Layers();
		scroller = new h2d.Layers();
		forgroundLayer = new h2d.Layers();
		transitioner = new h2d.Layers();
		root.add(backgroundLayer, Const.DP_BG);
		root.add(scroller, Const.DP_MAIN);
		scroller.add(forgroundLayer, Const.DP_FRONT);
		root.add(transitioner, Const.DP_TOP);
		root.filter = new h2d.filter.Nothing(); // scroller    force rendering for pixel perfect
		var glo = new h2d.filter.Glow(0x0000ff);
		// backgroundLayer.filter = new h2d.filter.Group([disp,glo]);//;
		// itf.filter=new dn.heaps.filter.PixelOutline();
		fx = new Fx();
		hud = new ui.Hud();
		camera = new Camera();
		camera.setTrackingSpeed(4);
		// camera.zoomTo(2);
		GameStats.ALL = [];
		startLevel(Assets.worldData.all_levels.Level_21);
	}

	public static function isGameControllerLocked() {
		return !exists() || ME.isPaused() || App.ME.anyInputHasFocus();
	}

	public static inline function exists() {
		return ME != null && !ME.destroyed;
	}

	/** Load a level **/
	public function startLevel(l:World.World_Level) {
		currentFrame = 0;
		if (level != null)
			level.destroy();
		fx.clear();
		forgroundLayer.removeChildren();
		// scroller.removeChildren();
		backgroundLayer.removeChildren();
		for (e in Entity.ALL.filter(ent -> !ent.is(SamplePlayer))) // <---- Replace this with more adapted entity destruction (eg. keep the player alive)
			e.destroy();
		for (e in sample.SampleChaine.ALL)
			e.destroy();
		for (e in sample.SampleComputer.ALL)
			e.destroy();
		for (e in sample.SampleElevator.ALL)
			e.destroy();
		for (e in sample.SampleDoor.ALL)
			e.destroy();
		for (e in sample.SampleLight.ALL)
			e.destroy();
		for (e in sample.SampleChest.ALL)
			e.destroy();
		for (e in sample.SampleSlime.ALL)
			e.destroy();
		for (e in sample.SampleTutorial.Tutorial.ALL)
			e.destroy();
		for (e in sample.SampleTriggerRect.TriggerRect.ALL)
			e.destroy();
		for (e in sample.SampleExitRect.ExitRect.ALL)
			e.destroy();
		for (e in sample.WaterPond.ALL)
			e.destroy();
		for (e in sample.PassageDoor.ALL)
			e.destroy();
		for (e in sample.Switcher.ALL)
			e.destroy();
		garbageCollectEntities();

		level = new Level(l);
		currentLevel = l;
		// <---- Here: instanciate your level entities

		camera.centerOnTarget();
		hud.onLevelStart();
		dn.Process.resizeAll();
	}

	/** Called when either CastleDB or `const.json` changes on disk **/
	@:allow(App)
	function onDbReload() {
		hud.notify("DB reloaded");
	}

	/** Called when LDtk file changes on disk **/
	@:allow(assets.Assets)
	function onLdtkReload() {
		hud.notify("LDtk reloaded");
		if (level != null)
			startLevel(Assets.worldData.getLevel(level.data.uid));
	}

	/** Window/app resize event **/
	override function onResize() {
		super.onResize();
		dn.Process.resizeAll();
	}

	/** Garbage collect any Entity marked for destruction. This is normally done at the end of the frame, but you can call it manually if you want to make sure marked entities are disposed right away, and removed from lists. **/
	public function garbageCollectEntities() {
		if (Entity.GC == null || Entity.GC.length == 0)
			return;

		for (e in Entity.GC)
			e.dispose();
		Entity.GC = [];
	}

	/** Called if game is destroyed, but only at the end of the frame **/
	override function onDispose() {
		super.onDispose();

		fx.destroy();
		for (e in Entity.ALL)
			e.destroy();
		garbageCollectEntities();

		if (ME == this)
			ME = null;
	}

	/**
		Start a cumulative slow-motion effect that will affect `tmod` value in this Process
		and all its children.

		@param sec Realtime second duration of this slowmo
		@param speedFactor Cumulative multiplier to the Process `tmod`
	**/
	public function addSlowMo(id:String, sec:Float, speedFactor = 0.3) {
		if (slowMos.exists(id)) {
			var s = slowMos.get(id);
			s.f = speedFactor;
			s.t = M.fmax(s.t, sec);
		} else
			slowMos.set(id, {id: id, t: sec, f: speedFactor});
	}

	/** The loop that updates slow-mos **/
	final function updateSlowMos() {
		// Timeout active slow-mos
		for (s in slowMos) {
			s.t -= utmod * 1 / Const.FPS;
			if (s.t <= 0)
				slowMos.remove(s.id);
		}

		// Update game speed
		var targetGameSpeed = 1.0;
		for (s in slowMos)
			targetGameSpeed *= s.f;
		curGameSpeed += (targetGameSpeed - curGameSpeed) * (targetGameSpeed > curGameSpeed ? 0.2 : 0.6);

		if (M.fabs(curGameSpeed - targetGameSpeed) <= 0.001)
			curGameSpeed = targetGameSpeed;
	}

	/**
		Pause briefly the game for 1 frame: very useful for impactful moments,
		like when hitting an opponent in Street Fighter ;)
	**/
	public inline function stopFrame() {
		ucd.setS("stopFrame", 0.2);
	}

	/** Loop that happens at the beginning of the frame **/
	override function preUpdate() {
		super.preUpdate();

		for (e in Entity.ALL)
			if (!e.destroyed)
				e.preUpdate();
	}

	/** Loop that happens at the end of the frame **/
	override function postUpdate() {
		super.postUpdate();
		// ME.root.getChildLayer(forgroundLayer).x = scroller.x * 0.5;

		// Update slow-motions
		updateSlowMos();
		baseTimeMul = (0.2 + 0.8 * curGameSpeed) * (ucd.has("stopFrame") ? 0.3 : 1);
		Assets.tiles.tmod = tmod;

		// Entities post-updates
		for (e in Entity.ALL)
			if (!e.destroyed)
				e.postUpdate();

		// Entities final updates
		for (e in Entity.ALL)
			if (!e.destroyed)
				e.finalUpdate();

		// Dispose entities marked as "destroyed"
		garbageCollectEntities();
	}

	/** Main loop but limited to 30 fps (so it might not be called during some frames) **/
	override function fixedUpdate() {
		super.fixedUpdate();

		if (rnd(0, 100000) < 10) {
			meteo.state = [Rainning, Sunny, Snowing][irnd(0, 2)];
		}
		simpleShader.shader.multiplier = Math.sin(currentFrame / 360 * Math.PI) * 2.5;
		if (meteo.state == Rainning) {
			var rain = irnd(0, 50);
			for (i in 0...rain)
				fx.drople(rnd(0, w()), -16, 0x11558f, i % 2 == 0, rnd(0.01, 0.5));
			for (i in 0...10)
				fx.smogg(rnd(0, w()), h());
		}
		if(meteo.state == Snowing){
			var rain = irnd(0, 50);
			for (i in 0...rain)
				fx.snow(rnd(0, w()), -16, 0x11558f, i % 2 == 0, rnd(0.01, 0.5));
		}

		// Entities "30 fps" loop
		for (e in Entity.ALL)
			if (!e.destroyed)
				e.fixedUpdate();

		if (cd.has("sepia")) {
			if (bmp == null)
				bmp = new h2d.Bitmap(h2d.Tile.fromColor(0xdd5500, w(), h()));
			bmp.alpha = 0.5;
			bmp.filter = new h2d.filter.Blur(8, 1.5, 3);
			bmp.blendMode = Add;
			if (!forgroundLayer.contains(bmp))
				forgroundLayer.add(bmp, Const.DP_FX_FRONT);
		} else {
			if (bmp != null)
				// forgroundLayer.filter=new dn.heaps.filter.PixelOutline(0x676767,0.7);
				forgroundLayer.removeChild(bmp);
		}
		if (cd.has("titleScreen")) {
			uiLayer.removeChildren(); // CLEAN THE WHOLE UI
			if (ca.isPressed(Action))
				cd.unset("titleScreen");
			var g = new Graphics();
			g.beginFill(0x000000, 1);

			g.drawRect(0, 0, w(), h());
			uiLayer.addChild(g);
			var title = new Bitmap(Assets.gametitle.tile);
			title.filter = new dn.heaps.filter.PixelOutline(0xffffff, 1);
			uiLayer.addChild(title);
			title.setPosition(w() * 0.5 * 1 / Const.SCALE - title.width * 0.5, h() * 0.5 * 1 / Const.SCALE - title.height * 0.5);
			title.scale(0.5);
			title.filter = new h2d.filter.Group([disp, new dn.heaps.filter.PixelOutline()]);
			title.alpha = cd.getRatio("titleScreen");
		} else {
			backgroundLayer.setScale(Const.SCALE + 1);
			backgroundLayer.x = scroller.x * 0.8;
			backgroundLayer.y = scroller.y * 0.8;
			/*if (rnd(0, 1000) < 100) {
				for (i in 0...4) {
					fx.smogg(rnd(0, w()), h()+16);
				}
			}*/

			// itf.text="LIFE ";//+player.life+"/"+player.maxLife;

			/*itf=new h2d.Text(Assets.fontPixel);
				itf.text="LIFE :";
				itf.textAlign=Align.Right;
				itf.x=w()/Const.SCALE*0.5;
				itf.y=4;
				itf.filter=new dn.heaps.filter.PixelOutline();
				uiLayer.addChild(itf); */
			uiLayer.removeChildren(); // CLEAN THE WHOLE UI
			var ui_bg = new h2d.Bitmap(h2d.Tile.fromColor(0x8ffbf6f2, 128, 18));
			ui_bg.x = w() / Const.SCALE * 0.5 - 64;
			ui_bg.y = 2;
			ui_bg.alpha = 0.6;
			uiLayer.addChild(ui_bg);

			var i_bg = new h2d.Bitmap(h2d.Tile.fromColor(0x8ffbf6f2, 18, 128));
			i_bg.x = 2;
			i_bg.y = 18 + 2;
			i_bg.alpha = 0.6;
			uiLayer.addChild(i_bg);
			for (i in 0...player.life) {
				var hb = new h2d.Bitmap(lifeTile);
				hb.x += w() / Const.SCALE * 0.5 + i * 8;
				hb.y = 4;
				hb.filter = new dn.heaps.filter.PixelOutline(player.cd.has("invincible") ? 0xf : 0x0);
				uiLayer.addChild(hb);
			}

			// inventory
			var i = 0;
			for (itm in player.inventory) {
				if (itm == Key) {
					key_bmp = new Bitmap(keyTile);
					key_bmp.x = 4;
					key_bmp.y = 18 + 4 + i * 16;
					key_bmp.filter = new dn.heaps.filter.PixelOutline();
					uiLayer.addChild(key_bmp);
					i++;
				}
				if (itm == KeyGold) {
					goldkey_bmp = new Bitmap(goldkeyTile);
					goldkey_bmp.x = 4;
					goldkey_bmp.y = 18 + 4 + i * 16;
					goldkey_bmp.filter = new dn.heaps.filter.PixelOutline();
					uiLayer.addChild(goldkey_bmp);
					i++;
				}
				if (itm == Credit_Card) {
					cred_bmp = new Bitmap(credTile);
					cred_bmp.x = 4;
					cred_bmp.y = 18 + 4 + i * 16;
					cred_bmp.filter = new dn.heaps.filter.PixelOutline();
					uiLayer.addChild(cred_bmp);
					i++;
				}
				if (itm == ID_Card) {
					id_bmp = new Bitmap(idCardTile);
					id_bmp.x = 4;
					id_bmp.y = 18 + 4 + i * 16;
					id_bmp.filter = new dn.heaps.filter.PixelOutline();
					uiLayer.addChild(id_bmp);
					i++;
				}
				if (itm == Money) {
					money_bmp = new Bitmap(moneyTile);
					money_bmp.filter = new dn.heaps.filter.PixelOutline();
					money_bmp.x = 4; // player.screenAttachX
					money_bmp.y = 18 + 4 + i * 16; // player.screenAttachY;
					uiLayer.addChild(money_bmp);
					/*if(money_bmp!=null){						
						Game.ME.tw.createMs(money_bmp.x,4,TLinear,500);
						Game.ME.tw.createMs(money_bmp.y,4+i*16,TLinear,500);
					}*/

					var tx = new h2d.Text(Assets.fontPixel);
					tx.filter = new dn.heaps.filter.PixelOutline();
					tx.x = 4 + 2;
					tx.y = 18 + 4 + i * 16 + 2;
					tx.text = "x" + player.money;
					uiLayer.addChild(tx);

					i++;
				}
			}

			// fog vanishing
			// scroller.getChildAtLayer()
			if (level.marks != null) {
				for (tx in -3...3) {
					for (ty in -3...3) {
						level.marks.set(Visited, player.cx + tx, player.cy + ty);
					}
				}
			}
			// level.marks.set(Visited, player.cx, player.cy);
			/*if (markach == null) {
				markach = new Achievement("fogMarks_" + level.data.identifier, "saved", () -> true, () -> true, level.marks);
			}else if (markach != null) {
				markach = new Achievement("fogMarks_" + level.data.identifier, "saved", () -> true, () -> true, level.marks);

				gameStats.registerState(markach);
				gameStats.updateAll();
			}*/
			if (warFobj == null) {
				warFobj = new h2d.Object();
			}
			warFobj.removeChildren();
			var tl =D.tiles.vide;
			for (cx in -3...level.cWid+3) {
				for (cy in -3...level.cHei+3) {
					
					if (!level.marks.has(Visited, cx, cy)) {
						tl = D.tiles.fogC;
						if (level.marks.has(Visited, cx - 1, cy)) {
							tl = D.tiles.fogW;
						} else if (level.marks.has(Visited, cx + 1, cy)) {
							tl = D.tiles.fogE;
						} else if (level.marks.has(Visited, cx, cy + 1)) {
							tl = D.tiles.fogS;
						} else if (level.marks.has(Visited, cx, cy - 1)) {
							tl = D.tiles.fogN;
						} else if (level.marks.has(Visited, cx + 1, cy + 1)) {
							tl = D.tiles.fogSE;
						} else if (level.marks.has(Visited, cx - 1, cy - 1)) {
							tl = D.tiles.fogNW;
						} else if (level.marks.has(Visited, cx + 1, cy - 1)) {
							tl = D.tiles.fogNE;
						} else if (level.marks.has(Visited, cx - 1, cy + 1)) {
							tl = D.tiles.fogSW;
						} else if (level.marks.has(Visited, cx + 1, cy - 1) && level.marks.has(Visited, cx, cy - 1)) {
							tl = D.tiles.fogNE1;
						}
					
						
					}else{
						tl =D.tiles.vide;
						if(cx==0){tl=D.tiles.fogE;}
						if(cx==level.cWid-1){tl=D.tiles.fogW;}
						if(cy==0){tl=D.tiles.fogS;}
						if(cy==level.cHei-1){tl=D.tiles.fogN;}

						if(cx==0 && cy==0){tl=D.tiles.fogSE;}
						if(cx==level.cWid-1 && cy==level.cHei-1){tl=D.tiles.fogNW;}
						if(cx==0 && cy==level.cHei-1){tl=D.tiles.fogNE;}
						if(cx==level.cWid-1 && cy==0){tl=D.tiles.fogSW;}

					}
					if(cx<=-1 || cx>=level.cWid || cy<=-1 || cy>=level.cHei){
						tl = D.tiles.fogC;
					}
					var fogTile = new Bitmap(Assets.tiles.getTile(tl));
					fogTile.x = cx * 16;
					fogTile.y = cy * 16;
					warFobj.addChild(fogTile);
				}
			}
			if(!scroller.contains(warFobj)){
				scroller.add(warFobj);}

			// mask
			var containerMask:Object = new h2d.Mask(64, 64, root);
			/*var mask:Graphics = new Graphics(containerMask);
				mask.beginFill(0x65ffffff);
				mask.drawCircle(4,4,64,64);
				mask.endFill();
				mask.clip();
			 */
			// var mask:h2d.Mask = new h2d.Mask(64,64,root);

			containerMask.x = 48;
			containerMask.y = 16;

			// minimap
			var containerMap:Object = new h2d.Object(root);
			var minimap = new Graphics(containerMap);

			minimap.x = 32;
			minimap.y = 32;
			var z = 0.08;
			for (zone in Assets.worldData.levels) {
				var vis = gameStats.has(zone.identifier + "_visited");
				if (!vis)
					continue;
				var couleur = vis && zone.identifier == level.data.identifier ? 0x00ff00 : 0xffff00;
				minimap.beginFill(couleur, 0.5);
				minimap.lineStyle(1, couleur);
				minimap.drawRect(zone.worldX * z, zone.worldY * z, zone.pxWid * z, zone.pxHei * z);
				minimap.endFill();
			}
			minimap.beginFill(0xffffff, 0.25);
			minimap.lineStyle(1, 0xffffff, 0.8);
			// minimap.drawCircle((currentLevel.worldX*z+player.cx*16*z),(currentLevel.worldY*z+player.cy*16*z),32,64);
			minimap.drawRect((currentLevel.worldX * z + player.cx * 16 * z) - 32, (currentLevel.worldY * z + player.cy * 16 * z) - 32, 64, 64);

			minimap.endFill();
			minimap.beginFill(0xff0000, 0.8);
			minimap.drawCircle((currentLevel.worldX * z + player.cx * 16 * z), (currentLevel.worldY * z + player.cy * 16 * z), 1, 16);
			minimap.endFill();
			minimap.x -= currentLevel.worldX * z + player.cx * 16 * z;
			minimap.y -= currentLevel.worldY * z + player.cy * 16 * z;
			// minimap.clip();
			// minimap.drawTo(mapTexture);
			// minimap.filter=new h2d.filter.Mask(mask);
			containerMask.addChild(containerMap);
			containerMask.filter = new dn.heaps.filter.PixelOutline();
			uiLayer.addChild(containerMask);

			uiLayer.alpha = 1 - transitioner.alpha;

			gameStats.updateAll();
		}
	}

	/** Main loop **/
	override function update() {
		super.update();
		#if hl
		socket.update();
		#end
		currentFrame++;
		// forgroundLayer.x =  Game.ME.scroller.x;
		// forgroundLayer.y =  Game.ME.scroller.y;
		// forgroundLayer.setScale(Const.SCALE);

		/*if(level.hasForground(player.cx,player.cy,1)){
				//player.debug(level.hasForgroundType(player.cx,player.cy,1));
				if(level.hasForgroundType(player.cx,player.cy,1)==7){
					forgroundLayer.alpha=0.8;
					for( i in 0...forgroundLayer.numChildren){
						trace(forgroundLayer.getChildAt(i).x);
					}
				}
				
			}else{
				forgroundLayer.alpha=1;
		}*/

		// Entities main loop
		for (e in Entity.ALL)
			if (!e.destroyed)
				e.frameUpdate();

		// Global key shortcuts
		if (!App.ME.anyInputHasFocus() && !ui.Modal.hasAny() && !Console.ME.isActive()) {
			// Exit by pressing ESC twice
			#if hl
			if (ca.isKeyboardPressed(K.ESCAPE))
				if (!cd.hasSetS("exitWarn", 3))
					hud.notify(Lang.t._("Press ESCAPE again to exit."));
				else
					App.ME.exit();
			#end

			// Attach debug drone (CTRL-SHIFT-D)
			#if debug
			if (ca.isPressed(ToggleDebugDrone))
				new DebugDrone(); // <-- HERE: provide an Entity as argument to attach Drone near it
			#end
			if (ca.isPressed(Pause))
				App.ME.toggleGamePause();
			if (App.ME.isPaused())
				hud.congrat("super, ouais, génial, bravo");

			// Restart whole game
			if (ca.isPressed(Restart))
				App.ME.startGame();
		}
	}
}
