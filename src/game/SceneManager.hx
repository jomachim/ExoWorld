class SceneManager extends  h2d.Object{
    public static var SCENES:Array<dn.Process>=[];
	var currentScene:dn.Process;
	var lastScene:dn.Process;


    public function new(){
        super();
    }
    
    public function changeTo(scene:dn.Process){
        lastScene=currentScene;
        currentScene=scene;
    }

}