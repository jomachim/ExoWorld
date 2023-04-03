import h2d.Object;
/**
 *  A Achievement / save system
 */
class GameStats extends h2d.Object{
    public static var ALL:Array<Achievement>=[];
    public function registerState(a:Achievement):Dynamic{
        ALL.push(a);
        return a;
    }
    public function unregisterState(a:String):Void{
        for(ac in ALL){
            if(ac.name==a){
                ALL.remove(ac);
            }
        }
    }
    public function show(){
        for(a in ALL){
            trace(a.name,a.state,a.success());
        }
    }
    public function new(?ach:Achievement=null){
        super();
        if(ach!=null && !ALL.contains(ach)){
            registerState(ach);
        }
    }
    /**
     * Return TRUE if GameStats has allready registered Achievement (see firstRun);
     * @param s //The name of the achievement String;
     */
    public function has(s:String){
        for(a in ALL){
            if(a.name==s){
                return true;
            }
        }
        return false;
    }

    public function get(s:String){
        for(a in ALL){
            if(a.name==s){
                return a;
            }
        }
        return null;
    }

    public function updateAll(){
        for(a in ALL){
            if(a.success()==true && a.done==false){
                a.done=true;
                #if debug
               // trace("Le succés "+a.name+" a été achevé !");
                #end
                if(a.cb!=null){
                    a.cb();
                }
            }
        }
    }
}
class Achievement {
    public var name="";
    public var state="";
    public var success:()->Bool;
    public var cb:()->Void;
    public var data:Dynamic=null;
    public var marks:tools.MarkerMap<Types.LevelMark>;
    public var done:Bool=false; 
    public function new(_name:String,_state:String,_success:()->Bool,?_cb:()->Void,_data:Dynamic=null,_marks:tools.MarkerMap<Types.LevelMark>=null){
            name=_name;
            state=_state;
            success=_success;
            cb=_cb;
            data=_data;
            marks=_marks;
            done=false;
    }
}