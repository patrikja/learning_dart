# learning_dart
Learning about the Dart language

Following the dart-irc-codelab instructions:
https://github.com/floitsch/dart-irc-codelab/blob/master/codelab.md

wget http://ngircd.barton.de/pub/ngircd/ngircd-22.1.tar.xz
...

main() {
  print("Hello world");
}

Step 2 done:
nc -l 6668 &
dart --checked main.dart
NICK p1738j
USER username 8 * :p1738j
JOIN ##dart-irc-codelab
PRIVMSG ##dart-irc-codelab :Szia vilag
QUIT

----------------

Step 3 started: sent "Szia vilag" (hello world in hungarian) to the IRC server.

Step 4 done: bot can be stopped by
p1738j: please stop
