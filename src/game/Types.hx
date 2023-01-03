/**	This abstract enum is used by the Controller class to bind general game actions to actual keyboard keys or gamepad buttons. **/
enum abstract GameAction(Int) to Int {
	var MoveLeft;
	var MoveRight;
	var MoveUp;
	var MoveDown;

	var Jump;
	var Attack;
	var Action;
	var SuperAttack;
	var Restart;

	var MenuCancel;
	var Pause;

	var ToggleDebugDrone;
	var DebugDroneZoomIn;
	var DebugDroneZoomOut;
	var DebugTurbo;
	var DebugSlowMo;
	var ScreenshotMode;
}

/** Entity state machine. Each entity can only have 1 active State at a time. **/
enum abstract State(Int) {
	var Normal;
	var UnderControl;
}


/** Entity Affects have a limited duration in time and you can stack different affects. **/
/**/
enum abstract Affect(Int) to Int{
	var Stun;
	var Death;
	var Speedup;
}

enum LevelMark{
	Visited;
	Breaks;
	None;
}

enum abstract LevelSubMark(Int) to Int {
	var None; // 0
}

enum abstract Types(Int) to Int {
	var Solid;
	var Sayer;
	var Spike;
	var SlopRight;
	var SlopLeft;
}

enum abstract Loot(Int) {
	var Key;
	var Money;
	var Weapon;
	var Food;
	var IdCard;
}