import hxd.res.Sound;
import h2d.Text;
import h2d.Interactive;
import sample.SimpleShader;
import h2d.col.Ray;
import h2d.Bitmap;
import h2d.Graphics;

class TitleScreen extends dn.Process {
	public static var ME:TitleScreen;

	/** Game controller (pad or keyboard) **/
	public var ca:ControllerAccess<GameAction>;

	/** Particles **/
	public var fx:Fx;

	/** Basic viewport control **/
	public var camera:Camera;

	/** Container of all visual game objects. Ths wrapper is moved around by Camera. **/
	public var scroller:h2d.Layers;

	public var transitioner:h2d.Layers;
	public var backgroundLayer:h2d.Layers;

	public var manager:Null<hxd.snd.Manager>;
	public var giftResource:Sound = null;

	// public var player:Null<SamplePlayer>;

	/** displacement filer **/
	public var disp:h2d.filter.Displacement;

	public var nothing:h2d.filter.Nothing;
	public var simpleShader:SimpleShader;
	public var glow:h2d.filter.Glow;

	/** Level data **/
	public var level:Level;

	public var currentLevel:World_Level;
	public var title:h2d.Bitmap;

	/** UI **/
	// public var hud : ui.Hud;

	/** Slow mo internal values**/
	var curGameSpeed = 1.0;

	var slowMos:Map<String, {id:String, t:Float, f:Float}> = new Map();
	var currentFrame:Int = 0;
	var menuIndex:Int = 0;

	function showOptions() {
		trace("showing options");
	}

	var menuOptions:Array<Dynamic> = [
		{option: "Start New Game", cb: App.ME.startGame},
		{option: "Load saved Game", cb: () -> true},
		{option: "Options", cb: () -> true},
		{option: "Reset", cb: App.ME.startTitleScreen},
		{option: "Quit", cb: App.ME.exit}
	];
	var bts:Array<Interactive> = [];

	public function new() {
		super(App.ME);
		trace('titlescreen');
		ME = this;
		ca = App.ME.controller.createAccess();
		ca.lockCondition = isGameControllerLocked;
		createRootInLayers(App.ME.root, Const.DP_BG);
		disp = new h2d.filter.Displacement(Assets.normdisp.tile, 1, 1);
		backgroundLayer = new h2d.Layers();
		scroller = new h2d.Layers();
		transitioner = new h2d.Layers();
		root.add(backgroundLayer, Const.DP_BG);
		root.add(scroller, Const.DP_MAIN);
		root.add(transitioner, Const.DP_BG);
		nothing = new h2d.filter.Nothing(); // force rendering for pixel perfect
		simpleShader = new sample.SimpleShader(2.0);
		glow = new h2d.filter.Glow(0x2b2ba9, 0.8, 3, 1, 2);

		// backgroundLayer.filter = new h2d.filter.Group([disp,glow]);//;
		// fx = new Fx();
		// var hud = new ui.Hud();
		// camera = new Camera();
		// camera.zoomTo(2.5);
		// startLevel(Assets.worldData.all_levels.The_Caves);
		var g = new h2d.Graphics();

		scroller.addChild(g);

		if (title == null) {
			title = new Bitmap(Assets.gametitle.tile);
			title.scale(2);
			title.setPosition(w() * 0.5 / Const.UI_SCALE - title.width * 0.5, h() * 0.5 / Const.UI_SCALE - title.height * 0.5);

			scroller.addChild(title);
			scroller.filter = new h2d.filter.Group([nothing, disp]);
			// engine.backgroundColor=new dn.Col(0x000000);
			if (App.ME.root.getScene() != null)
				App.ME.root.getScene().filter = new h2d.filter.Group([simpleShader, new dn.heaps.filter.Crt()]);
		}
		/*var start_bt=new Interactive(128,32);
			var start_txt=new Text(Assets.fontPixel);
			start_txt.text="START NEW GAME";
			start_bt.scale(4);
			start_bt.x=w()*0.5;
			start_bt.y=h()*0.5;
			scroller.add(start_bt,Const.DP_UI);
			start_bt.addChild(start_txt);
			start_bt.backgroundColor=new dn.Col(0x452e2e);
			start_bt.onPush=start_bt.onOver=(e)->{
				start_bt.backgroundColor=new dn.Col(0xff0000);
			}
			start_bt.onRelease=(e)->{
				App.ME.startGame();
				
		}*/

		// If we support mp3 we have our sound
		if (hxd.res.Sound.supportedFormat(OggVorbis)) {
			giftResource = hxd.Res.sounds.gift;
		}
		if (hxd.res.Sound.supportedFormat(Mp3)) {
			giftResource = hxd.Res.sounds.gift;
		}
		if (giftResource != null) {
			// Play the music and loop it
			giftResource.play(false).volume = 0.15;
		}

		for (i in 0...menuOptions.length) {
			var m = menuOptions[i];
			m.index = i;
			var bt_txt = new Text(Assets.fontPixel);
			var bt = new Interactive(128, 32);
			bt_txt.scale(2);
			bt.addChild(bt_txt);
			scroller.add(bt, Const.DP_UI);
			bt.filter = menuIndex == 0 ? nothing : glow;
			bt_txt.text = m.option;
			bt.x = w() * 0.5 - bt.width * 0.5;
			bt.y = h() * 0.5 + 32 * i;
			bt.onRelease = (e) -> {
				m.cb();
			}
			bt.onOver = (e) -> {
				cd.setS('select',0.5);
				// bt.filter = glow;
				menuIndex = m.index;
				tw.createMs(bt_txt.scaleX, 2.5, TLinear, 200);
				tw.createMs(bt_txt.scaleY, 2.5, TBackOut, 200);
			}
			bt.onOut = (e) -> {
				cd.setS('select',0.5);
				tw.createMs(bt_txt.scaleX, 2, TLinear, 200);
				tw.createMs(bt_txt.scaleY, 2, TBackOut, 200);
			}
			bts.push(bt);
		}
	}

	public static function isGameControllerLocked() {
		return !exists() || ME.isPaused() || App.ME.anyInputHasFocus();
	}

	public static inline function exists() {
		return ME != null && !ME.destroyed;
	}

	/** Load a level **/
	public function startLevel(l:World.World_Level) {
		if (level != null)
			level.destroy();
		// fx.clear();
		for (e in Entity.ALL) // <---- Replace this with more adapted entity destruction (eg. keep the player alive)
			e.destroy();
		garbageCollectEntities();

		level = new Level(l);
		currentLevel = l;
		// <---- Here: instanciate your level entities

		// camera.centerOnTarget();
		// hud.onLevelStart();
		dn.Process.resizeAll();
	}

	/** Called when either CastleDB or `const.json` changes on disk **/
	@:allow(App)
	function onDbReload() {
		// hud.notify("DB reloaded");
	}

	/** Called when LDtk file changes on disk **/
	@:allow(assets.Assets)
	function onLdtkReload() {
		// hud.notify("LDtk reloaded");
		if (level != null)
			startLevel(Assets.worldData.getLevel(level.data.uid));
	}

	/** Window/app resize event **/
	override function onResize() {
		super.onResize();
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

		// fx.destroy();
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
		disp.normalMap.scrollDiscrete(1, -2);
		// disp.normalMap.dy=2;
		// disp.normalMap.dx=1;
		if (currentFrame >= 0)
			currentFrame++;
		// simpleShader.shader.multiplier=Math.sin(currentFrame/360*Math.PI)*6;
		// Entities "30 fps" loop
		for (e in Entity.ALL)
			if (!e.destroyed)
				e.fixedUpdate();
		if (cd.has("select")) {
			for (i in 0...bts.length) {
				if (i == menuIndex) {
					bts[i].filter = glow;
					tw.createMs(bts[i].getChildAt(0).scaleX,2.5,TLinear,200);
					tw.createMs(bts[i].getChildAt(0).scaleY,2.5,TBackOut,200);
				} else {
					bts[i].filter = nothing;
					tw.createMs(bts[i].getChildAt(0).scaleX, 2, TLinear, 200);
					tw.createMs(bts[i].getChildAt(0).scaleY, 2, TBackOut, 200);
				}
			}
		}

		if (ca.isPressed(Action) || ca.isPressed(Pause)) {
			// trace('starting game ?');
			// App.ME.startGame();
			menuOptions[menuIndex].cb();
		}
	}

	/** Main loop **/
	override function update() {
		super.update();
		if (ca.isPressed(MoveDown) && !cd.has('select')) {
			cd.setS('select', 0.5);
			menuIndex++;
			if (menuIndex > menuOptions.length - 1) {
				menuIndex = 0;
			}
		}
		if (ca.isPressed(MoveUp) && !cd.has('select')) {
			cd.setS('select', 0.5);
			menuIndex--;
			if (menuIndex < 0) {
				menuIndex = menuOptions.length - 1;
			}
		}
		// Entities main loop
		for (e in Entity.ALL)
			if (!e.destroyed)
				e.frameUpdate();

		// Global key shortcuts
		if (!App.ME.anyInputHasFocus() && !ui.Modal.hasAny() && !Console.ME.isActive()) {
			// Exit by pressing ESC twice
			#if hl
			if (ca.isKeyboardPressed(K.ESCAPE))
				if (!cd.hasSetS("exitWarn", 3)) {
					// hud.notify(Lang.t._("Press ESCAPE again to exit."));
				} else {
					App.ME.exit();
				}
			#end

			// Attach debug drone (CTRL-SHIFT-D)
			#if debug
			if (ca.isPressed(ToggleDebugDrone))
				new DebugDrone(); // <-- HERE: provide an Entity as argument to attach Drone near it
			#end
			if (ca.isPressed(Pause))
				App.ME.toggleGamePause();
			if (App.ME.isPaused())
				// new ui.Modal();

				// Restart whole game
				if (ca.isPressed(Restart))
					App.ME.startGame();
		}
	}
}
