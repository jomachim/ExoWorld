import h2d.Text;
class Chrono extends Entity{
    public var elapsedTime:Float = 0;
    public var tf:h2d.Text;
    public function new(?x=0,?y=0){
        super(x,y);
        elapsedTime = 0;
        tf=new h2d.Text(Assets.fontPixel);
		tf.textAlign=Align.Left;
		tf.filter=new dn.heaps.filter.PixelOutline();
        tf.x=32;
        tf.y=32;
        tf.text=''+elapsedTime;
        spr.set('empty');
        
    }
    override function fixedUpdate() {
        super.fixedUpdate();
        elapsedTime += utmod;
        tf.text=''+elapsedTime;
    }
    override function dispose() {
		super.dispose();
	}
}