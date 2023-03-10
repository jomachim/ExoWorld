package assets;

import h2d.Bitmap;
import dn.heaps.slib.*;

/**
	This class centralizes all assets management (ie. art, sounds, fonts etc.)
**/
class Assets {
	// Fonts
	public static var fontPixel : h2d.Font;

	/** Main atlas **/
	public static var tiles : SpriteLib;
	public static var hero : SpriteLib;
	public static var slime : SpriteLib;
	public static var door : SpriteLib;
	public static var elevator : SpriteLib;
	public static var computer : SpriteLib;
	public static var chaine : SpriteLib;
	public static var chest : SpriteLib;
	public static var light : SpriteLib;
	public static var ventilo : SpriteLib;
	public static var normdisp: Bitmap;
	public static var menu: SpriteLib;
	public static var gametitle:SpriteLib;
	public static var bot: SpriteLib;
	public static var lazer:SpriteLib;
	public static var signal:SpriteLib;
	public static var rigids:SpriteLib;
	public static var boom:SpriteLib;
	
	/** LDtk world data **/
	public static var worldData : World;


	static var _initDone = false;
	public static function init() {
		if( _initDone )
			return;
		_initDone = true;

		// Fonts
		fontPixel = new hxd.res.BitmapFont( hxd.Res.fonts.pixel_unicode_regular_12_xml.entry ).toFont();

		// normal map for displacement
		normdisp = new h2d.Bitmap(hxd.Res.atlas.normaldisp.toTile());
		

		// build sprite atlas directly from Aseprite file
		tiles = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.tiles.toAseprite());
		hero = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.hero.toAseprite());
		slime = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.slime.toAseprite());
		door = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.door.toAseprite());
		elevator = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.elevator.toAseprite());
		computer = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.computer.toAseprite());
		chaine = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.chaine.toAseprite());
		chest = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.chest.toAseprite());
		light = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.light.toAseprite());
		ventilo = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.ventilo.toAseprite());
		menu = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.menu.toAseprite());
		gametitle = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.gametitle.toAseprite());
		lazer = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.lazer.toAseprite());
		bot = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.bot.toAseprite());
		signal = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.signal.toAseprite());
		rigids = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.rigids.toAseprite());
		boom = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.boom.toAseprite());
		// Hot-reloading of CastleDB
		#if debug
		hxd.Res.data.watch(function() {
			// Only reload actual updated file from disk after a short delay, to avoid reading a file being written
			App.ME.delayer.cancelById("cdb");
			App.ME.delayer.addS("cdb", function() {
				CastleDb.load( hxd.Res.data.entry.getBytes().toString() );
				Const.db.reload_data_cdb( hxd.Res.data.entry.getText() );
			}, 0.2);
		});
		#end

		// Parse castleDB JSON
		CastleDb.load( hxd.Res.data.entry.getText() );

		// Hot-reloading of `const.json`
		hxd.Res.const.watch(function() {
			// Only reload actual updated file from disk after a short delay, to avoid reading a file being written
			App.ME.delayer.cancelById("constJson");
			App.ME.delayer.addS("constJson", function() {
				Const.db.reload_const_json( hxd.Res.const.entry.getBytes().toString() );
			}, 0.2);
		});

		// LDtk init & parsing
		worldData = new World();

		// LDtk file hot-reloading
		#if debug
		var res = try hxd.Res.load(worldData.projectFilePath.substr(4)) catch(_) null; // assume the LDtk file is in "res/" subfolder
		if( res!=null )
			res.watch( ()->{
				// Only reload actual updated file from disk after a short delay, to avoid reading a file being written
				App.ME.delayer.cancelById("ldtk");
				App.ME.delayer.addS("ldtk", function() {
					worldData.parseJson( res.entry.getText() );
					if( Game.exists() )
						Game.ME.onLdtkReload();
				}, 0.2);
			});
		#end
	}


	/**
		Pass `tmod` value from the game to atlases, to allow them to play animations at the same speed as the Game.
		For example, if the game has some slow-mo running, all atlas anims should also play in slow-mo
	**/
	public static function update(tmod:Float) {
		if( Game.exists() && Game.ME.isPaused() )
			tmod = 0;

		tiles.tmod = tmod;
		// <-- add other atlas TMOD updates here
	}

}