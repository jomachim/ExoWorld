#if hl
import hl.types.ObjectMap;
import haxe.Json;
import haxe.io.Bytes;
import sys.net.Host;
import sys.net.Socket;

class SocketClient extends sys.net.Socket {
	public var socket:sys.net.Socket;
	public var uid:Int;

	private var listeners:Array<Dynamic> = [];

	public function new() {
		super();
		if (socket == null) {
			socket = new sys.net.Socket();

			try {
				socket.connect(new Host('192.168.0.12'), 8080);
				socket.accept();
				//socket.setTimeout(0.1);
				socket.setBlocking(false);
				trace('creating new socket on port 8080');
			} catch (e:Dynamic) {
				trace(e + 'failed to connect');
				// socket.shutdown(true,true);
			}
		}
	}


	public function parseMessage(m:String) {
		var message:Dynamic= Json.parse(m);
		switch (message.type) {
			case "id":
				uid = message.id;
				trace("your id is " + uid);

			case "message":
				trace(message.who + " says:" + message.message);

			case "move":
				trace(message.who + ',' + message.x + ',' + message.y);

			default:
				trace('unknow command: ' + m);
		}
		return m;
	}

	public function sendMessage(texto:String) {
		var test = {who: uid, type: "message", message: texto};
		try {
			socket.output.write(Bytes.ofString(Json.stringify(test) ));//+ '\r\n'
		} catch (e:Dynamic) {
			//trace("echoue comme un merde "+e);
		}
	}

	public function update() {
        
		try {
			parseMessage(socket.input.readLine());
			//sendMessage('bien reçu');
			//trace(socket.input.readLine());
		} catch (e:Dynamic) {
			// trace('nothing to read ?'+e); // afficher 'BLOCKED'
		}
	}
}
#end