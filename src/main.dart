import 'dart:io';
import 'dart:convert';

/// Given a connected [socket] runs the IRC bot.
void handleIrcSocket(Socket socket) {
  final nick = "p1738j";

  void authenticate() {
    socket.write('NICK $nick\r\n');
    socket.write('USER username 8 * :$nick\r\n');
  }

  /// Sends a message to the IRC server.
  ///
  /// The message is automatically terminated with a `\r\n`.
  void writeln(String message) {
    socket.write('$message\r\n');
  }

  final RegExp ircMessageRegExp =
      new RegExp(r":([^!]+)!([^ ]+) PRIVMSG ([^ ]+) :(.*)");

  void handleMessage(String msgNick,
                     String server,
                     String channel,
                     String msg) {
    if (msg.startsWith("$nick:")) {
      // Direct message to us.
      var text = msg.substring(msg.indexOf(":") + 1).trim();
      if (text == "please stop") {
        print("Leaving by request of $msgNick");
        writeln("QUIT");
        return;
      }
    }
    print("$msgNick: $msg");
  }

  void handleServerLine(String line) {
    if (line.startsWith("PING")) {
      writeln("PONG ${line.substring("PING ".length)}");
      return;
    }
    var match = ircMessageRegExp.firstMatch(line);
    if (match != null) {
      handleMessage(match[1], match[2], match[3], match[4]);
      return;
    }
    print("from server: $line");
  }

  socket
      .transform(UTF8.decoder)
      .transform(new LineSplitter())
      .listen(handleServerLine,
              onDone: socket.close);


  authenticate();
  writeln('JOIN ##dart-irc-codelab');
  writeln('PRIVMSG ##dart-irc-codelab :Szia világ! ∀ ε ∃ δ trying out unicode');
  // writeln('QUIT');
  // no destroy?
}

void runIrcBot() {
  Socket.connect("chat.freenode.net", 6667)
//  Socket.connect("localhost", 6668)
      .then(handleIrcSocket);
}


class SentenceGenerator {
  final _db = new Map<String, Set<String>>();

  void addBook(String fileName) {
    var content = new File(fileName).readAsStringSync();

    // Make sure the content terminates with a ".".
    if (!content.endsWith(".")) content += ".";

    var words = content
        .replaceAll("\n", " ") // Treat new lines as if they were spaces.
        .replaceAll("\r", "")  // Discard "\r".
        .replaceAll(".", " .") // Add space before ".", to simplify splitting.
        .split(" ")
        .where((String word) => word != "");

    var preprevious = null;
    var previous = null;
    for (String current in words) {
      if (preprevious != null) {
        // We have a trigram.
        // Concatenate the first two words and use it as a key. If this key
        // doesn't have a corresponding set yet, create it. Then add the
        // third word into the set.
        _db.putIfAbsent("$preprevious $previous", () => new Set())
            .add(current);
      }

      preprevious = previous;
      previous = current;
    }
  }
}

void main(arguments) {
  var generator = new SentenceGenerator();
  arguments.forEach(generator.addBook);
}
