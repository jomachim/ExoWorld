import h2d.TileGroup;
import h2d.filter.Bloom;
import h2d.filter.Glow;
import dn.heaps.TiledTexture;
import h2d.Layers;

class Level extends GameProcess {
	/** Level grid-based width**/
	public var cWid(get,never) : Int; inline function get_cWid() return data.l_Collisions.cWid;

	/** Level grid-based height **/
	public var cHei(get,never) : Int; inline function get_cHei() return data.l_Collisions.cHei;

	/** Level pixel width**/
	public var pxWid(get,never) : Int; inline function get_pxWid() return cWid*Const.GRID;

	/** Level pixel height**/
	public var pxHei(get,never) : Int; inline function get_pxHei() return cHei*Const.GRID;

	public var data : World_Level;

	public var visited:Bool=false;
	var tilesetSource : h2d.Tile;
	public var backTilesLayer:h2d.Layers;
	public var decorationLayer:h2d.Layers;
	public var collisionLayer:h2d.Layers;
	public var forgroundTilesLayer: h2d.Layers;
	public var warFogTilesLayer: h2d.Layers;
	//public var bgtg : h2d.TileGroup;
	//public var bgtg_texture:h3d.mat.Texture;
	public var marks : tools.MarkerMap<Types.LevelMark>;
	var invalidated = true;
	public var breakables:tools.MarkerMap<Types.LevelMark>;
	//public var collType:{ contains : Null<Int> -> Bool };
	public function new(ldtkLevel:World.World_Level) {
		super();
		Game.ME.backgroundLayer.removeChildren();
		Game.ME.forgroundLayer.removeChildren();
		
		createRootInLayers(Game.ME.scroller, Const.DP_MAIN);

		
		
		data = ldtkLevel;
		
		tilesetSource = hxd.Res.levels.sampleWorldTiles.toAseprite().toTile();
		marks = new MarkerMap(cWid, cHei);
		breakables = new MarkerMap(cWid,cHei);
	}

	override function onDispose() {
		super.onDispose();
		data = null;
		tilesetSource = null;
		breakables.dispose();
		breakables = null;
		marks.dispose();
		marks = null;
	}

	/** TRUE if given coords are in level bounds **/
	public inline function isValid(cx,cy) return cx>=0 && cx<cWid && cy>=0 && cy<cHei;

	/** Gets the integer ID of a given level grid coord **/
	public inline function coordId(cx,cy) return cx + cy*cWid;

	/** Ask for a level render that will only happen at the end of the current frame. **/
	public inline function invalidate() {
		invalidated = true;
	}
	public inline function hasBreakable(cx,cy):Bool{
		return breakables.has(Breaks,cx,cy);
	}
	/** Return TRUE if "Collisions" layer contains a collision value **/
	public inline function hasForground(cx,cy,dist):Bool{
		return !isValid(cx,cy) ? true : data.l_Forground.getInt(cx,cy)!=0;
	}
	public inline function hasForgroundType(cx,cy,dist):Int{
		return !isValid(cx,cy) ? -1 : data.l_Forground.getInt(cx,cy);
	}
	public inline function hasCollision(cx,cy) : Bool {
		return !isValid(cx,cy) ? true : (data.l_Collisions.getInt(cx,cy)==1 || hasBreakable(cx,cy)==true);
	}

	public inline function hasLadder(cx,cy):Bool{
		return !isValid(cx,cy) ? true : data.l_Collisions.getInt(cx,cy)==2;
	}

	public inline function hasOneWay(cx,cy):Bool{
		return !isValid(cx,cy) ? true : data.l_Collisions.getInt(cx,cy)==3;
	}

	public inline function hasCollTypes(cx,cy,collType):Bool{
		if(collType==null) collType=[1];
		return !isValid(cx,cy) ? false : collType.contains(data.l_Collisions.getInt(cx,cy))==true;
	}
	/** Render current level**/
	function render() {
		// Placeholder level render
		root.removeChildren();
		Game.ME.backgroundLayer.removeChildren();
		Game.ME.forgroundLayer.removeChildren();
		//Game.ME.scroller.removeChildren();
		if(collisionLayer!=null) collisionLayer.removeChildren();
		if(forgroundTilesLayer!=null) forgroundTilesLayer.removeChildren();
		backTilesLayer=new h2d.Layers(Game.ME.backgroundLayer);
		decorationLayer=new h2d.Layers(root);
		collisionLayer=new h2d.Layers(root);
		forgroundTilesLayer=new h2d.Layers(Game.ME.forgroundLayer);//root.parent
		warFogTilesLayer=new h2d.Layers(Game.ME.warFogLayer);//root.parent

		var bgtg = new h2d.TileGroup(tilesetSource,backTilesLayer);
		var dg = new h2d.TileGroup(tilesetSource, decorationLayer);
		var tg = new h2d.TileGroup(tilesetSource, collisionLayer);
		var fg = new h2d.TileGroup(tilesetSource,forgroundTilesLayer);
		var wfg:TileGroup = new h2d.TileGroup(tilesetSource,warFogTilesLayer);
		//bgtg_texture=bgtg.tile.getTexture();
/**/

		var bgLayer = data.l_Backgrounds;
		for( autoTile in bgLayer.autoTiles) {
			var tile = bgLayer.tileset.getAutoLayerTile(autoTile);
			#if hl
			bgtg.add(autoTile.renderX, autoTile.renderY, tile);// comment for speed/perf
			#end
		}

		//,new h2d.filter.Glow(0x0000f0,0.5,64,1.1,1)
		backTilesLayer.scale(1);
		backTilesLayer.filter = new h2d.filter.Group([game.disp,new h2d.filter.Bloom(2,10,16,2,1)]);

		var decoLayer = data.l_Deco;
		for( cx in 0...decoLayer.cWid ) {
			for( cy in 0...decoLayer.cHei ) {	
				if(decoLayer.hasAnyTileAt(cx,cy)){
					for(i in 0...decoLayer.getTileStackAt(cx,cy).length){
						var tile =decoLayer.getTileStackAt(cx,cy)[i];
						dg.add(cx*16,cy*16, decoLayer.tileset.getTile(tile.tileId,tile.flipBits));
					}
					
				}
			}
		}

		var layer = data.l_Collisions;
		
		for( autoTile in layer.autoTiles ) {
			var tile = layer.tileset.getAutoLayerTile(autoTile);
			tg.add(autoTile.renderX, autoTile.renderY, tile);
		}

		var layer = data.l_Forground;
		for( autoTile in layer.autoTiles ) {
			var tile = layer.tileset.getAutoLayerTile(autoTile);
			fg.add(autoTile.renderX, autoTile.renderY, tile);
		}
		
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}
	}
}