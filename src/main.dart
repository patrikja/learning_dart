import 'dart:io';

/// Given a connected [socket] runs the IRC bot.
void handleIrcSocket(Socket socket) {

  void authenticate() {
    var nick = "p1738j";  // <=== Replace with your bot name. Try to be unique.
    socket.write('NICK $nick\r\n');
    socket.write('USER username 8 * :$nick\r\n');
  }

  authenticate();
  socket.write('JOIN ##dart-irc-codelab\r\n');
  socket.write('PRIVMSG ##dart-irc-codelab :Szia vilag\r\n');
  socket.write('QUIT\r\n');
  socket.destroy();
}

void main() {
//  Socket.connect("chat.freenode.net", 6667)  // No need for the temporary variable.
  Socket.connect("localhost", 6668)  // No need for the temporary variable.
      .then(handleIrcSocket);
}
