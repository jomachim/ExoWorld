package sample;

import h2d.Graphics;
import sample.SampleExitRect.ExitRect;
import h2d.filter.Shader;
import hxd.Timer;
import dn.heaps.GameFocusHelper;
import h3d.shader.SinusDeform;
import dn.heaps.filter.PixelOutline;
import dn.Process;
import h2d.filter.Mask;
import h2d.Bitmap;
import hxd.res.Font;
import h2d.Text;
import h2d.Object;
import h2d.filter.AbstractMask;
import h2d.filter.AbstractMask.Hide;
import h2d.Layers;
import ase.Layer;
import h3d.Matrix;
import h2d.filter.Ambient;
import sample.SampleTriggerRect.TriggerRect;
import sample.SampleTutorial.Tutorial;
import h2d.Tile;
import h3d.Vector;
import h3d.mat.Texture;
import hxd.fmt.hdr.Reader;
import hxd.res.Sound;
import GameStats.Achievement;
import haxe.http.HttpBase;

/**
	This small class just creates a SamplePlayer instance in current level
**/
class SampleGame extends Game {
	public function new() {
		if (manager != null)
			manager.stopAll();
		super();
		
		// camera.zoomTo(3);
		/*var httpResponse=sys.Http.requestUrl("https://alterpixel.fr/").toString();
			trace(httpResponse); */
		// trace(haxe.Resource.listNames());
	}

	var firstRun:Bool = true;

	public var shadeNorm:NormalShader;

	public var distor:ExperimentalFilter;
	// public var chroma:ChromaticAberrationShader;
	public var fader:Null<h2d.Object>;
	public var modal:Null<ui.Modal>;
	public var musicResource:Sound = null;

	/** Window/app resize event **/
	override function onResize() {
		super.onResize();
		if (transitioner != null)
			transitioner.removeChildren();
		var black = new h2d.Graphics(fader);
		black.beginFill(0x000000, 1);
		black.drawRect(0, 0, w(), h());
		transitioner.add(black);
		dn.Process.resizeAll();
	}

	override function startLevel(l:World_Level) {
		// App.ME.emitResizeAtEndOfFrame();
		super.startLevel(l);
		currentLevel = l;
		// camera.zoomTo(3);
		if (itf == null) {
			uiLayer = new h2d.Layers(root);
			uiLayer.scale(Const.SCALE);
			itf = new Text(Assets.fontPixel);
			itf.text = "LIFE :";
			itf.textAlign = Align.Right;
			itf.x = w() / Const.SCALE * 0.5;
			itf.y = 4;
			uiLayer.addChild(itf);
			heart_bmp = new Bitmap(lifeTile);
			heart_bmp.x = itf.x - 8;
			heart_bmp.y = 4;
			heart_bmp.scale(Const.SCALE * 0.5);
			uiLayer.add(heart_bmp);
		}

		if (fader == null) {
			fader = new h2d.Object();
			var black = new h2d.Graphics(fader);
			black.beginFill(0x000000, 1);
			black.drawRect(0, 0, w(), h());
			transitioner.add(black);
		} else {
			transitioner.removeChildren();
			var black = new h2d.Graphics(fader);
			black.beginFill(0x000000, 1);
			black.drawRect(0, 0, w(), h());
			transitioner.add(black);
		}

		/*transitioner.alpha=0.75;
			var tw=new Tweenie(Const.FPS);
			tw.createMs(transitioner.alpha,0,TEaseOut, 500); */
		// add slimes enemy
		// var slimeLayer=new Layers();

		for (exit in level.data.l_Entities.all_ExitRect) {
			var _exit = new ExitRect(exit);
			if (player != null) {
				if (player.destination.door != null) {
					if (_exit.data.iid == player.destination.door) {
						delayer.addF('go', () -> {
							if (_exit.wid < _exit.hei) { // left/right
								var ox = player.destination.offsetX;
								var oy = player.destination.offsetY;
								if (ox > 0.0) {
									player.setPosPixel(_exit.centerX - 16, _exit.centerY + oy);
								} else {
									player.setPosPixel(_exit.centerX + 16, _exit.centerY + oy);
								}
							} else { // up/down > center y , offset X
								var ox = player.destination.offsetX;
								var oy = player.destination.offsetY;
								if (oy > 0.0) {
									player.setPosPixel(_exit.centerX + ox, _exit.centerY + 16);
								} else {
									player.setPosPixel(_exit.centerX + ox, _exit.centerY - 16);
								}
								/*if(player.attachX<_exit.attachX || player.attachX>_exit.attachX+_exit.wid){
									player.setPosPixel(_exit.centerX,_exit.centerY);
								}*/
							}
							camera.centerOnTarget();

							// fromdoor = true;
							// trace(d.data.iid);
							// trace("success ! EXIT MOVED");
							// player.destination=null;
							// trace("pos: " + exit.cx + "," + exit.cy);
						}, 0);
					}
				}
			}
		}

		for (slime in level.data.l_Entities.all_SlimeSpawner) {
			var s = new SampleRobot();
			s.setPosCase(slime.cx, slime.cy);
		}
		var fromdoor = false;
		// add doors
		// if(player!=null) trace("player destination door:"+player.destination.door);
		for (door in level.data.l_Entities.all_Door) {
			var d = new SampleDoor(door);
			d.data = door;
			d.requierements.push(door.f_Required_Item);
			d.setPosCase(door.cx, door.cy);
			// scroller.under(d.spr);
			// scroller.over(d.spr);
			if (player != null) {
				if (player.destination.door != null) {
					if (d.data.iid == player.destination.door) {
						player.cx = d.cx;
						player.cy = d.cy;
						fromdoor = true;
						// trace(d.data.iid);
						// trace("success !");
						// player.destination=null;
						camera.centerOnTarget();
						camera.trackEntity(player, true);
					}
				}
			}
		}
		// add Ventilo
		for (vent in level.data.l_Entities.all_Ventilo) {
			new SampleVentilo(vent);
		}

		// add Elevators
		for (elev in level.data.l_Entities.all_Elevator) {
			var el = new SampleElevator(elev);
			var ch = new SampleChaine(elev);
		}

		// computers switches
		for (com in level.data.l_Entities.all_Computer) {
			var s = new SampleComputer(com);
		}

		// add chests
		for (chest in level.data.l_Entities.all_Chest) {
			new SampleChest(chest);
		}

		// add TriggerRect
		for (rect in level.data.l_Entities.all_TriggerRect) {
			new TriggerRect(rect);
		}

		// add lights
		for (light in level.data.l_Entities.all_Light) {
			new SampleLight(light);
		}

		// add Tutorial
		for (tuto in level.data.l_Entities.all_Tutorial) {
			new Tutorial(tuto);
			// forgroundLayer.addChild(tut.spr);
		}

		// add signals
		for (sig in level.data.l_Entities.all_Signal) {
			new Signal(sig);
			// forgroundLayer.addChild(tut.spr);
		}

		// add repeaters
		for (rep in level.data.l_Entities.all_Repeater) {
			new Repeater(rep);
			// forgroundLayer.addChild(tut.spr);
		}

		// add booms
		for (boom in level.data.l_Entities.all_Boom) {
			new Boom(boom);
			// forgroundLayer.addChild(tut.spr);
		}

		// add rigidbodies
		for (body in level.data.l_Entities.all_RigidBody) {
			new sample.SampleRigidBody.RigidBody(body);
			// forgroundLayer.addChild(tut.spr);
		}

		// add Water ponds
		for (pond in level.data.l_Entities.all_Water) {
			new sample.WaterPond(pond);
			// forgroundLayer.addChild(tut.spr);
		}

		// add breakables
		for (rock in level.data.l_Entities.all_Breakable) {
			new sample.Breakable(rock);
			level.breakables.set(Breaks,rock.cx,rock.cy);
			// forgroundLayer.addChild(tut.spr);
		}

		// add switchers
		for (sw in level.data.l_Entities.all_Switcher) {
			new sample.Switcher(sw);
			// forgroundLayer.addChild(tut.spr);
		}
		// add passageDoors
		for (door in level.data.l_Entities.all_PassageDoor) {
			new sample.PassageDoor(door);
			// forgroundLayer.addChild(tut.spr);
		}

		// add player
		var start = level.data.l_Entities.all_PlayerStart[0];
		if (player == null) {
			player = new SamplePlayer();
			// is player coming from a door ?
			disp = new h2d.filter.Displacement(Assets.normdisp.tile, 1, 1);
			player.setPosCase(start.cx, start.cy);
		} else {
			if (fromdoor == false) {
				player.cx = player.lastGroundedPos.cx;
				player.cy = player.lastGroundedPos.cy;
			}
		}
		/*else {
			if (fromdoor==false) {
				player.setPosCase(start.cx, start.cy);
			} else {
				player.setPosCase(player.destination.door.cx,player.destination.door.cy); // to change
			}

		}*/
		/*
			warFog here ?
		 */

		for (cx in 0...level.cWid) {
			for (cy in 0...level.cHei) {
				/*var fogTile=new Bitmap(Assets.tiles.getTile( D.tiles.fogC ));
					fogTile.x=cx*16;
					fogTile.y=cy*16;
					warFobj.addChild(fogTile); */
				level.marks.set(None, cx, cy);
			}
		}
		if (gameStats.has(level.data.identifier + "_visited") && gameStats.has("fogMarks_" + level.data.identifier)) {
			level.marks = gameStats.get("fogMarks_" + level.data.identifier).data;
			trace('saved marks' + gameStats.get("fogMarks_" + level.data.identifier).data);
		}

		/*scroller.add(warFobj);*/

		// scroller.add(forgroundLayer,Const.DP_TOP);
		scroller.over(player.spr);

		// var temp=new h2d.Layers();
		// temp.add(forgroundLayer);
		// scroller.add(temp);

		disp.normalMap.scrollDiscrete(0.01, 0.02);
		itf.filter = new dn.heaps.filter.PixelOutline();
		backgroundLayer.filter = disp;
		// var tex=new hxsl.Types.Texture(w(), h(), [Target]);
		// root.drawTo(tex);
		// root.drawTo(tex);
		// var sinus=new SinusDeform();
		// root.filter= new h2d.filter.Shader<ScreenShader>(sinus,"texture");

		// root.filter = new h2d.filter.Group([disp]);//new h2d.filter.Bloom(1.1,1.1,16),
		// scroller.filter=disp;//shadeNorm;
		camera.zoomTo(1.25);

		hud.notify(l.identifier);
		// new Ambient(root,new Matrix());
		// new h2d.filter.Shader<SinusDeform>(new SinusDeform(),"texture"),new h2d.filter.Glow(0xffffff,1.1,64,1),
		aberration = new Aberration();
		simpleShader = new sample.SimpleShader(2.0);
		distor = new ExperimentalFilter(1.0, 16, 1.0);
		simpleShader.shader.multiplier = 16;
		Game.ME.root.getScene().filter = new h2d.filter.Group([simpleShader, new dn.heaps.filter.Crt()]); // ,distor aberration
		// GameFocusHelper.isUseful()

		// aberration.grayScale=1.0;
		// aberration.etime++;

		// If your audio file is named 'my_music.mp3', it has a shitty name

		if (manager == null) {
			manager = hxd.snd.Manager.get();
			manager.masterVolume = 0.25;
			manager.masterChannelGroup.addEffect(new hxd.snd.effect.Pitch(1.0));
			var spa=new hxd.snd.effect.Spatialization();
			spa.fadeDistance=10;
			spa.position=new h3d.Vector(-1,0,2,1);
			spa.direction=new h3d.Vector(0.5,0.5,2);
			manager.masterChannelGroup.addEffect(spa);
			manager.masterSoundGroup.maxAudible = 4;

			// If we support mp3 we have our sound
			if (hxd.res.Sound.supportedFormat(OggVorbis)) {
				musicResource = hxd.Res.sounds.music;
			}
			if (hxd.res.Sound.supportedFormat(Mp3)) {
				musicResource = hxd.Res.sounds.music;
			}

			if (musicResource != null) {
				// Play the music and loop it
				// musicResource.play(false).volume=0.1;
			}
		}

		if (level.visited == false && !gameStats.has(level.data.identifier + "_visited")) {
			gameStats.registerState(new Achievement(level.data.identifier + "_visited", "done", () -> level.visited == false,
				() -> trace("visited " + level.data.identifier)));
			level.visited = true;
		}
		level.visited = gameStats.has(level.data.identifier + "_visited");
		if (firstRun == true && !gameStats.has("firstRun")) {
			firstRun = false;

			var a = new Achievement("firstRun", "done", () -> return firstRun == false, () -> {
				var message = new h2d.Flow(root);

				var bg = new h2d.ScaleGrid(Assets.menu.getTile("idle"), 8, 12, 8, 8);
				// bg.ignoreScale=true;
				bg.tile = Assets.menu.getTile("idle");
				bg.tileBorders = true;
				message.backgroundTile = bg.tile;
				message.borderWidth = 8;
				message.borderHeight = 12;
				message.padding = 18;
				message.x = player.spr.x;
				message.y = player.spr.y;
				message.filter = new dn.heaps.filter.PixelOutline();
				var tf = new h2d.Text(Assets.fontPixel, message);
				tf.text = "First Run Achieved !";
				message.setScale(0.5);
				scroller.add(message, Const.DP_FRONT);
				delayer.addS("removeAchievement", () -> scroller.removeChild(message), 1);
			});
			gameStats.registerState(a);
			// gameStats.show();
			cd.setS("titleScreen", 1);
			delayer.addS("remusing", () -> resume(), 0.1);

			if (musicResource != null)
				musicResource.stop();
			musicResource.play(false).volume = 0.03;
		}
	}
}
