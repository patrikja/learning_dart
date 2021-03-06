// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import 'dart:math';

final RegExp ircMessageRegExp =
    new RegExp(r":([^!]+)!([^ ]+) PRIVMSG ([^ ]+) :(.*)");

void handleIrcSocket(Socket socket, SentenceGenerator sentenceGenerator) {
  final nick = "p1738j";

  /// Sends a message to the IRC server.
  ///
  /// The message is automatically terminated with a `\r\n`.
  void writeln(String message) {
    socket.write('$message\r\n');
  }

  void authenticate() {
    writeln('NICK $nick');
    writeln('USER username 8 * :$nick');
  }

  void say(String message) {
    if (message.length > 120) {
      // IRC doesn't like it when lines are too long.
      message = message.substring(0, 120);
    }
    writeln('PRIVMSG ##dart-irc-codelab :$message');
  }

  void handleMessage(String msgNick,
                     String server,
                     String channel,
                     String msg) {
    if (msg.startsWith("$nick:")) {
      // Direct message to us.
      var text = msg.substring(msg.indexOf(":") + 1).trim();
      switch (text) {
        case "please leave":
          print("Leaving by request of $msgNick");
          writeln("QUIT");
          return;
        case "talk to me":
          say(sentenceGenerator.generateRandomSentence());
          return;
        default:
          if (text.startsWith("finish: ")) {
            var start = text.substring("finish: ".length);
            var sentence = sentenceGenerator.finishSentence(start);
            say(sentence == null ? "Unable to comply." : sentence);
            return;
          }
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
  say('Szia világ! ∀ ε ∃ δ');
}

void runIrcBot(SentenceGenerator generator) {
  Socket.connect("chat.freenode.net", 6667)
//  Socket.connect("localhost", 6668)
      .then((socket) => handleIrcSocket(socket, generator));
}

class SentenceGenerator {
  final _db = new Map<String, Set<String>>();
  final rng = new Random();

  void addBook(String fileName) {
    var content = new File(fileName).readAsStringSync();

    // Make sure the content terminates with a ".".
    if (!content.endsWith(".")) content += ".";

    var words = content
        .replaceAll("\n", " ") // Treat new lines as if they were spaces.
        .replaceAll("\r", "")  // Discard "\r".
        .replaceAll(".", " .") // Add space before "." to simplify splitting.
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

  int get keyCount => _db.length;

  String pickRandomPair() => _db.keys.elementAt(rng.nextInt(keyCount));

  String pickRandomThirdWord(String firstWord, String secondWord) {
    var key = "$firstWord $secondWord";
    var possibleSequences = _db[key];
    return possibleSequences.elementAt(rng.nextInt(possibleSequences.length));
  }

  /// Finishes a sentence with the given [start].
  ///
  /// If for the given [start] no completion can be found, the function drops
  /// the last words and tries again until it either finds a completion or
  /// too few words are left.
  ///
  /// Returns null, if no completion can be found.
  String finishSentence(String start) {
    // This function has local types, to show the differences between List and
    // Iterable.

    List words = start.split(" ");
    // By reversing the list we don't need to deal with the length that much.
    // It also allows to show a few more Iterable functions.
    Iterable reversedRemaining = words.reversed;
    while (reversedRemaining.length >= 2) {
      String secondToLast = reversedRemaining.elementAt(1);
      String last = reversedRemaining.first;
      String leadPair = "$secondToLast $last";
      if (_db.containsKey(leadPair)) {
        // If the leadPair is in the database, it means that we have data to
        // continue from these two words.
        String beginning = reversedRemaining
            .skip(2)    // 'last' and 'secondToLast' are already handled.
            .toList()   // Iterable does not have `reversed`.
            .reversed   // These are the remaining words.
            .join(" "); // Join them to have the beginning of the sentence.
        String end = generateSentenceStartingWith(secondToLast, last);
        return "$beginning $end";
      }
      // We weren't able to continue from the last two words. Drop one, and try
      // again.
      reversedRemaining = reversedRemaining.skip(1);
    }
    return null;
  }

  String generateRandomSentence() {
    var start = pickRandomPair();
    var startingWords = start.split(" ");
    return generateSentenceStartingWith(startingWords[0], startingWords[1]);
  }

  String generateSentenceStartingWith(String preprevious, String previous) {
    var sentence = [preprevious, previous];
    var current;
    do {
      current = pickRandomThirdWord(preprevious, previous);
      sentence.add(current);
      preprevious = previous;
      previous = current;
    } while (current != ".");
    return sentence.join(" ");
  }
}

void main(arguments) {
  var generator = new SentenceGenerator();
  arguments.forEach(generator.addBook);
  runIrcBot(generator);
}
