const util = require('util');
const Net = require('net');

// The port on which the server is listening.
const port = 8080;

// Use net.createServer() in your code. This is just for illustration purpose.
// Create a new TCP server.
const server = new Net.Server();
// The server listens to a socket for a client to make a connection request.
// Think of a socket as an end point.
server.listen(port, function() {
    console.log(`Server listening for connection requests on socket localhost:${port}`);
});


let sockets = [];
let it = setInterval(function() {
    if (sockets.length > 0) {
        console.log('sending bird greetings');
        sockets.forEach((soc) => {
            soc.write(JSON.stringify({ who: 0, type: "message", message: "coucou" }) + '\r\n');
        });
    }
}, 2500)
var UIDS = 1;
// When a client requests a connection with the server, the server creates a new
// socket dedicated to that client.
function getSocket(id) {
    let so = sockets.filter(soc => soc.UIDS == id)[0];
    if (!so) return "anonymous"
    return so
}
server.on('connection', function(socket) {
    console.log('A new connection has been established.');
    socket.UIDS = ++UIDS;
    socket.name = 'player_' + socket.UIDS;
    sockets.push(socket);
    // Now that a TCP connection has been established, the server can send data to
    // the client by writing to its socket.
    var message = { who: 0, type: "id", id: socket.UIDS, name: socket.name }
    socket.write(JSON.stringify(message) + '\r\n');

    // The server can also receive data from the client by reading from its socket.
    socket.on('data', function(chunk) {
        console.log(chunk.toString());
        var newdata = "" + chunk;
        var newdatachunks = newdata.split("\r\n");
        for (var i = 0; i < (newdatachunks.length - 1); i++) { console.log("real data is :" + newdatachunks[i]); }

        var message = JSON.parse(chunk);
        console.log(message);
        switch (message.type) {
            case "move":
                console.log(message.x + "," + message.y + "," + message.who);
                break
            case "message":
                console.log(getSocket(message.who).name + " dit :" + message.message);
                break
            default:
                console.log("chelou le message");

        }
        console.log(`Data received from client: ${message.type}`);
        console.log(util.inspect(message, false, null, true /* enable colors */ ))
        socket.writableCorked = true;


    });

    // When the client requests to end the TCP connection with the server, the server
    // ends the connection.
    socket.on('end', function() {
        console.log('Closing connection with the client');
    });

    // Don't forget to catch error, for your own sake.
    socket.on('error', function(err) {
        console.log(`Error: ${err}`);
    });
});