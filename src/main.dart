import 'dart:io';

void main() {
  var future = Socket.connect("localhost", 6667);
  // Now register a callback:
  future.then((socket) { // start of a one-argument closure
    // The socket is now available.
    print("Connected");
    socket.destroy();  // Shuts down the socket in both directions.
  });
  print("Callback has been registered, but hasn't been called yet");
}
