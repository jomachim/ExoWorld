/**
	"App" class takes care of all the top-level stuff in the whole application. Any other Process, including Game instance, should be a child of App.
**/

import dn.Process;

class App extends dn.Process {
	public static var ME:App;

	/** 2D scene **/
	public var scene(default, null):h2d.Scene;

	/** Used to create "ControllerAccess" instances that will grant controller usage (keyboard or gamepad) **/
	public var controller:Controller<GameAction>;

	/** Controller Access created for Main & Boot **/
	public var ca:ControllerAccess<GameAction>;

	/** If TRUE, game is paused, and a Contrast filter is applied **/
	public var screenshotMode(default, null) = true;

	public function new(s:h2d.Scene) {
		super();
		ME = this;
		scene = s;
		createRoot(scene);

		initEngine();
		initAssets();
		initController();

		// Create console (open with [²] key)
		new ui.Console(Assets.fontPixel, scene); // init debug console

		// create interface de jeu ?
		// new ui.Bar(24,4,0x00ff00);

		// Optional screen that shows a "Click to start/continue" message when the game client looses focus
		#if js
		new dn.heaps.GameFocusHelper(scene, Assets.fontPixel);
		#end
		// startTitleScreen();
		startGame();
	}

	#if hl
	public static function onCrash(err:Dynamic) {
		var title = L.untranslated("Fatal error");
		var msg = L.untranslated('I\'m really sorry but the game crashed! Error: ${Std.string(err)}');
		var flags:haxe.EnumFlags<hl.UI.DialogFlags> = new haxe.EnumFlags();
		flags.set(IsError);

		var log = [Std.string(err)];
		try {
			log.push("BUILD: " + Const.BUILD_INFO);
			log.push("EXCEPTION:");
			log.push(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));

			log.push("CALL:");
			log.push(haxe.CallStack.toString(haxe.CallStack.callStack()));

			sys.io.File.saveContent("crash.log", log.join("\n"));
			hl.UI.dialog(title, msg, flags);
		} catch (_) {
			sys.io.File.saveContent("crash2.log", log.join("\n"));
			hl.UI.dialog(title, msg, flags);
		}

		hxd.System.exit();
	}
	#end

	/** Start game process **/
	public function startGame() {
		if (Game.exists()) {
			// Kill previous game instance first
			Game.ME.destroy();
			root.removeChildren();
			dn.Process.updateAll(1); // ensure all garbage collection is done
			_createGameInstance();
			hxd.Timer.skip();
		} else if (!TitleScreen.exists()) {
			// Fresh start
			delayer.addF(() -> {
				_createTitleScreenInstance();
				// _createGameInstance();
				hxd.Timer.skip();
			}, 1);
		} else {
			// Fresh game start
			TitleScreen.ME.destroy();
			dn.Process.updateAll(1);
			delayer.addF(() -> {
				// _createTitleScreenInstance();
				_createGameInstance();
				hxd.Timer.skip();
			}, 1);
		}
	}

	/**
	 * start TileScreen; (enfin il essaye);
	 */
	public function startTitleScreen() {
		if (TitleScreen.exists()) {
			TitleScreen.ME.destroy();
			dn.Process.updateAll(1);
			_createTitleScreenInstance();
			hxd.Timer.skip();
		} else {
			delayer.addF(() -> {
				_createTitleScreenInstance();
				hxd.Timer.skip();
			}, 1);
		}
	}

	public function startSavedScreen() {
		
			delayer.addF(() -> {
				_createSavedScreenInstance();
				hxd.Timer.skip();
			}, 1);
		
	}

	final function _createTitleScreenInstance() {
		new TitleScreen();
	}

	final function _createGameInstance() {
		// new Game(); // <---- Uncomment this to start an empty Game instance
		new sample.SampleGame(); // <---- Uncomment this to start the Sample Game instance
		// new TitleScreen();
	}

	final function _createSavedScreenInstance() {
		new sample.SavedScreen();
	}

	public function anyInputHasFocus() {
		return Console.ME.isActive() || cd.has("consoleRecentlyActive");
	}

	/**
		Set "screenshot" mode.
		If enabled, the game will be adapted to be more suitable for screenshots: more color contrast, no UI etc.
	**/
	public function setScreenshotMode(v:Bool) {
		screenshotMode = v;

		if (screenshotMode) {
			var f = new h2d.filter.ColorMatrix();
			f.matrix.colorContrast(0.2);
			root.filter = f;
			if (Game.exists()) {
				Game.ME.hud.root.visible = false;
				Game.ME.pause();
			}
		} else {
			if (Game.exists()) {
				Game.ME.hud.root.visible = true;
				Game.ME.resume();
			}
			root.filter = null;
		}
	}

	/** Toggle current game pause state **/
	public inline function toggleGamePause()
		setGamePause(!isGamePaused());

	/** Return TRUE if current game is paused **/
	public inline function isGamePaused()
		return Game.exists() && Game.ME.isPaused();

	/** Set current game pause state **/
	public function setGamePause(pauseState:Bool) {
		if (Game.exists())
			if (pauseState)
				Game.ME.pause();
			else
				Game.ME.resume();
	}

	/**
		Initialize low-level engine stuff, before anything else
	**/
	function initEngine() {
		// Engine settings
		engine.backgroundColor = 0x000000;
		engine.autoResize = true;
		#if (hl && !debug)
		engine.fullScreen = true; // false;
		#end

		#if (hl && !debug)
		hl.UI.closeConsole();
		hl.Api.setErrorHandler(onCrash);
		#end

		// Heaps resource management
		#if (hl && debug)
		hxd.Res.initLocal();
		hxd.res.Resource.LIVE_UPDATE = true;
		#else
		hxd.Res.initEmbed();
		#end

		// Sound manager (force manager init on startup to avoid a freeze on first sound playback)
		hxd.snd.Manager.get();
		hxd.Timer.skip(); // needed to ignore heavy Sound manager init frame

		// Framerate
		hxd.Timer.smoothFactor = 0.9;
		hxd.Timer.wantedFPS = Const.FPS;
		dn.Process.FIXED_UPDATE_FPS = Const.FIXED_UPDATE_FPS;
	}

	/**
		Init app assets
	**/
	function initAssets() {
		// Init game assets
		Assets.init();

		// Init lang data
		Lang.init("en");

		// Bind DB hot-reloading callback
		Const.db.onReload = onDbReload;
	}

	/** Init game controller and default key bindings **/
	function initController() {
		controller = dn.heaps.input.Controller.createFromAbstractEnum(GameAction);

		// Gamepad bindings
		controller.bindPadLStick4(MoveLeft, MoveRight, MoveUp, MoveDown);
		controller.bindPad(Jump, A);
		controller.bindPad(Attack, B);
		controller.bindPad(Action, X);
		controller.bindPad(SuperAttack, Y);
		controller.bindPad(Restart, SELECT);
		controller.bindPad(Pause, START);
		controller.bindPad(MoveLeft, DPAD_LEFT);
		controller.bindPad(MoveRight, DPAD_RIGHT);
		controller.bindPad(MoveUp, DPAD_UP);
		controller.bindPad(MoveDown, DPAD_DOWN);
		controller.bindPad(MenuCancel, Y);
		controller.bindPad(MenuOpen, LT);
		controller.bindPad(MenuOk,A);
		

		// Keyboard bindings
		controller.bindKeyboard(MoveLeft, [K.LEFT, K.Q, K.A]);
		controller.bindKeyboard(MoveRight, [K.RIGHT, K.D]);
		controller.bindKeyboard(MoveUp, [K.UP, K.Z, K.W]);
		controller.bindKeyboard(MoveDown, [K.DOWN, K.S]);
		controller.bindKeyboard(Jump, K.SPACE);
		controller.bindKeyboard(Action, [K.X, K.ALT]);
		controller.bindKeyboard(Attack, K.E);
		controller.bindKeyboard(SuperAttack, [K.E, K.A]);
		controller.bindKeyboard(Restart, K.R);
		controller.bindKeyboard(ScreenshotMode, K.F9);
		controller.bindKeyboard(Pause, K.P);
		controller.bindKeyboard(Pause, K.PAUSE_BREAK);
		controller.bindKeyboard(MenuCancel, K.ESCAPE);
		controller.bindKeyboard(MenuOpen, K.TAB);

		// Debug controls
		#if debug
		controller.bindPad(DebugTurbo, LT);
		controller.bindPad(DebugSlowMo, LB);
		controller.bindPad(DebugDroneZoomIn, RSTICK_UP);
		controller.bindPad(DebugDroneZoomOut, RSTICK_DOWN);

		controller.bindKeyboard(DebugDroneZoomIn, K.PGUP);
		controller.bindKeyboard(DebugDroneZoomOut, K.PGDOWN);
		controller.bindKeyboard(DebugTurbo, [K.END, K.NUMPAD_ADD]);
		controller.bindKeyboard(DebugSlowMo, [K.HOME, K.NUMPAD_SUB]);
		controller.bindPadCombo(ToggleDebugDrone, [LSTICK_PUSH, RSTICK_PUSH]);
		controller.bindKeyboardCombo(ToggleDebugDrone, [K.D, K.CTRL, K.SHIFT]);
		#end

		ca = controller.createAccess();
		ca.lockCondition = () -> return destroyed || anyInputHasFocus();
	}

	/** Return TRUE if an App instance exists **/
	public static inline function exists()
		return ME != null && !ME.destroyed;

	/** Close & exit the app **/
	public function exit() {
		destroy();
	}

	override function onDispose() {
		super.onDispose();

		#if hl
		hxd.System.exit();
		#end
	}

	/** Called when Const.db values are hot-reloaded **/
	public function onDbReload() {
		if (Game.exists())
			Game.ME.onDbReload();
	}

	public var menuModal:ui.Modal;

	override function update() {
		Assets.update(tmod);

		super.update();
		if (ca.isPressed(MenuOpen) && !cd.has('menuOpen')) {
			cd.setMs('menuOpen', 1800);
			menuModal = new ui.Modal();
			var menuFlow = new h2d.Flow(root);
			var tf = new h2d.Text(Assets.fontPixel, menuFlow);

			tf.filter = new dn.heaps.filter.PixelOutline();
			tf.x = 32;
			tf.y = 32;
			tf.text = 'MENU';
			menuModal.add(menuFlow);
			menuModal.ca.releaseExclusivity();
		}
		if (ca.isPressed(ScreenshotMode))
			setScreenshotMode(!screenshotMode);

		if (ca.isPressed(Pause))
			toggleGamePause();

		if (isGamePaused() && ca.isPressed(MenuCancel))
			setGamePause(false);

		if (ui.Console.ME.isActive())
			cd.setF("consoleRecentlyActive", 2);
	}
}
