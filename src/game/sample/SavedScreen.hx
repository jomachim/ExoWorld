package sample;
import h2d.Layers;
class SavedScreen extends dn.Process{
    
    public static var ME:SavedScreen;

	/** Game controller (pad or keyboard) **/
	public var ca:ControllerAccess<GameAction>;
    public var tf:h2d.Text;
	public var savedLayer:h2d.Layers;
    public static function isGameControllerLocked() {
		return !exists() || ME.isPaused() || App.ME.anyInputHasFocus();
	}

	public static inline function exists() {
		return ME != null && !ME.destroyed;
	}
    public function new() {
        super(App.ME);
		trace('SavedScreen');
		ME = this;
		ca = App.ME.controller.createAccess();
		//ca.lockCondition = isGameControllerLocked;
		createRootInLayers(App.ME.root, Const.DP_UI);
		if(savedLayer==null)
			savedLayer=new h2d.Layers(root);
        tf=new h2d.Text(Assets.fontPixel);
		tf.filter=new dn.heaps.filter.PixelOutline();
        tf.x=320;
        tf.y=320;
        tf.text='Saved Game Screen';
		
		savedLayer.add(tf);
		root.under(tf);
    }
    /** Main loop **/
	override function update() {
		super.update();
		if (ca.isPressed(MoveDown) && !cd.has('select')) {
			cd.setS('select', 0.5);
			
		}
    }
}