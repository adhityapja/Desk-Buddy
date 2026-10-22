enum BuddyMode {
  friend,
  study,
}

enum BuddyExpression {
  happy,
  thinking,
  talking,
  studyFocused,
  excited,
  sleepy,
  surprised,
  cool,
  listening,
}

extension BuddyExpressionExtension on BuddyExpression {
  String get code {
    switch (this) {
      case BuddyExpression.happy:
        return 'HAPPY';
      case BuddyExpression.thinking:
        return 'THINKING';
      case BuddyExpression.talking:
        return 'TALKING';
      case BuddyExpression.studyFocused:
        return 'FOCUSED';
      case BuddyExpression.excited:
        return 'EXCITED';
      case BuddyExpression.sleepy:
        return 'SLEEPY';
      case BuddyExpression.surprised:
        return 'SURPRISED';
      case BuddyExpression.cool:
        return 'COOL';
      case BuddyExpression.listening:
        return 'LISTENING';
    }
  }

  String get label {
    switch (this) {
      case BuddyExpression.happy:
        return 'Happy 😊';
      case BuddyExpression.thinking:
        return 'Thinking 🤔';
      case BuddyExpression.talking:
        return 'Speaking 💬';
      case BuddyExpression.studyFocused:
        return 'Study Focus 👓';
      case BuddyExpression.excited:
        return 'Hyped! ⚡';
      case BuddyExpression.sleepy:
        return 'Dozing Zzz';
      case BuddyExpression.surprised:
        return 'Surprised 😲';
      case BuddyExpression.cool:
        return 'Chill & Cool 😎';
      case BuddyExpression.listening:
        return 'Listening 🎙️';
    }
  }
}
