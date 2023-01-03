package sample;

import h2d.Tile;
import h2d.Bitmap;
import h2d.ScaleGrid;
import h2d.filter.DropShadow;
import h2d.filter.Ambient;
import dn.heaps.filter.PixelOutline;
import dn.Col;

class Tutorial extends Entity {
	public static var ALL:Array<Tutorial> = [];

	var ca:ControllerAccess<GameAction>;
	var anims = dn.heaps.assets.Aseprite.getDict(hxd.Res.atlas.menu);

	// var data : Entity_Tutorial;
	public var tf:h2d.HtmlText;
	public var bg:h2d.ScaleGrid;
	public var flo:h2d.Flow;
	public var collides:Bool = false;
	public var done:Bool = false;
	public var phrases:Array<String>;

	public function new(d:Entity_Tutorial) {
		super(0, 0);
		// Init controller
		ca = App.ME.controller.createAccess();
		ca.lockCondition = Game.isGameControllerLocked;

		activated = false;
		ALL.push(this);
		data = d;
		setPosPixel(d.pixelX, d.pixelY);
		spr.set("empty");
		flo = new h2d.Flow(spr);
		bg = new h2d.ScaleGrid(Assets.menu.getTile("idle"), 8, 12, 8, 8);
		bg.tile = Assets.menu.getTile("idle");
		bg.tileBorders = true;
		bg.ignoreScale = true;
		bg.tileCenter = true;
		flo.backgroundTile = bg.tile;
		flo.borderWidth = 8;
		flo.borderHeight = 12;
		flo.padding = 16;

		// tf.text = tf.formatText(data.f_Multilines);
		// var txtWid = tf.calcTextWidth(tf.text);
		tf = new h2d.HtmlText(Assets.fontPixel, flo);
		tf.setScale(1);
		tf.textColor = 0xffffff;
		tf.maxWidth = data.width * 2 - 32;
		// tf.font.resizeTo(9);
		tf.x = 8;
		tf.y = 8;
		tf.filter = new dn.heaps.filter.PixelOutline(0x000000);
		phrases = data.f_Multilines.split("\n");
		// tf.text = tf.formatText(phrases[0]);
		setPivots(-1,-1);
		spr.setScale(0.5);
		entityVisible = false;
		game.scroller.add(spr, Const.DP_UI);
	}

	public var next = 0;
	public var txt = "";
	public var outext = "";
	public var lastext = "";
	public var currentPhraseIndex = 0;

	override function fixedUpdate() {
		super.fixedUpdate();

		if (activated && entityVisible) {
			if (ca.isDown(Jump) && !cd.has("reading")) {
				cd.setMs("reading", 200);
				if (currentPhraseIndex < phrases.length) {
					invalidate();
					currentPhraseIndex++;
				} else {
					hide();
				}
			}
			if (ca.isPressed(Action)) {
				hide();
			}
		}
	}

	public function hide() {
		game.cd.unset('sepia');
		activated = false;
		entityVisible = false;
		currentPhraseIndex = 0;
		game.camera.trackEntity(game.player, false, 4);
	}

	public function show() {
		game.cd.setS("sepia", 60);
		activated = true;
		entityVisible = true;
		currentPhraseIndex = 0;
		invalidate();
		game.camera.trackEntity(this, false, 4);
	}

	public function invalidate() {
		tf.text = tf.formatText(phrases[currentPhraseIndex]);
		//flo.reflow();
		flo.setScale(0.5);
		setPosPixel(data.cx * Const.GRID - wid * 0.5, data.cy * Const.GRID - hei * 0.5);
	}
}
