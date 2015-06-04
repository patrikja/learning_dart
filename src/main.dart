import 'dart:io';
import 'dart:convert';

/// Given a connected [socket] runs the IRC bot.
void handleIrcSocket(Socket socket) {

  void authenticate() {
    var nick = "p1738j";
    socket.write('NICK $nick\r\n');
    socket.write('USER username 8 * :$nick\r\n');
  }

/// Sends a message to the IRC server.
///
/// The message is automatically terminated with a `\r\n`.
void writeln(String message) {
  socket.write('$message\r\n');
}

void handleServerLine(String line) {
  print("from server: $line");
  if (line.startsWith("PING")) {
    writeln("PONG ${line.substring("PING ".length)}");
  }
}

socket
    .transform(UTF8.decoder)
    .transform(new LineSplitter())
    .listen(handleServerLine,
            onDone: socket.close);

authenticate();
writeln('JOIN ##dart-irc-codelab');
writeln('PRIVMSG ##dart-irc-codelab :Szia vilag');
writeln('QUIT');
// no destroy?
}

void main() {
  Socket.connect("chat.freenode.net", 6667)
//  Socket.connect("localhost", 6668)
      .then(handleIrcSocket);
}
