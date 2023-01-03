import h2d.Object;
/**
 *  A Achievement / save system
 */
 enum States{
        Rainning;
        Snowing;
        Sunny;
        Cloudy;
        Stormy;
        Night;
}
class Meteo extends h2d.Object{
   
    public function new(){
        super();
        state=Snowing;
    }
    /**
     * Return TRUE if Meteo has given state;
     * @param s //The name of the achievement String;
     */
    
    public var state:States=Sunny;
    public function has(s:States){
        return state==s;
    }
    public function changeTo(w:States){
        state=w;
    }
}
