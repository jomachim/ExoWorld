package assets;

/**
	Access to slice names present in Aseprite files (eg. `trace( tiles.fxStar )` ).
	This class only provides access to *names* (ie. String). To get actual h2d.Tile, use Assets class.

	Examples:
	```haxe
	Assets.tiles.getTile( AssetsDictionaries.tiles.mySlice );
	Assets.tiles.getTile( D.tiles.mySlice ); // uses "D" alias defined in "import.hx" file
	```
**/
class AssetsDictionaries {
	public static var tiles = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.tiles );
	public static var hero = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.hero );
	public static var slime = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.slime );
	public static var door = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.door );
	public static var elevator = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.elevator );
	public static var computer = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.computer );
	public static var chest = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.chest );
	public static var light = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.light );
	public static var menu = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.menu );
	public static var gametitle = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.gametitle );
	public static var rigids = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.rigids );
	public static var boom = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.boom );
}