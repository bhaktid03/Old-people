import 'package:flutter/material.dart';

/// Token types for parsing text
enum _TokenType {
  word,        // Actual word content (letters, numbers, Hindi characters)
  punctuation, // Punctuation marks (.,!?:; etc.)
  space,       // Whitespace (spaces, tabs, newlines)
}

/// Represents a token in the text (word, punctuation, or space)
class _Token {
  final String text;
  final _TokenType type;
  final int startOffset; // Start position in original text
  final int endOffset;   // End position in original text
  final String normalizedWord; // Normalized word for matching (only for word tokens)

  _Token({
    required this.text,
    required this.type,
    required this.startOffset,
    required this.endOffset,
    required this.normalizedWord,
  });
}

/// Widget that displays text with word-level highlighting
/// Highlights the word currently being spoken by TTS
/// Properly handles punctuation and spaces - only highlights word content
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    this.highlightedWord,
    this.highlightStartOffset,
    this.highlightEndOffset,
    this.style,
    this.highlightColor,
    this.highlightTextColor,
    this.textAlign,
  });

  final String text;
  final String? highlightedWord;
  final int? highlightStartOffset;
  final int? highlightEndOffset;
  final TextStyle? style;
  final Color? highlightColor;
  final Color? highlightTextColor;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ?? Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
    final highlightBgColor = highlightColor ?? Colors.yellow.withOpacity(0.4);
    final highlightFgColor = highlightTextColor ?? defaultStyle.color;
    
    // If no highlight, just return regular text
    if ((highlightedWord == null || highlightedWord!.isEmpty) && 
        (highlightStartOffset == null || highlightEndOffset == null)) {
      return Text(
        text,
        style: defaultStyle,
        textAlign: textAlign,
      );
    }

    // Build text spans with proper word/punctuation separation
    final spans = <TextSpan>[];
    final tokens = _tokenizeText(text);

    for (final token in tokens) {
      final isHighlighted = _shouldHighlightToken(
        token: token,
        highlightedWord: highlightedWord,
        highlightStart: highlightStartOffset,
        highlightEnd: highlightEndOffset,
      );

      // Only apply highlight to word tokens, never to spaces or punctuation
      final shouldApplyHighlight = isHighlighted && token.type == _TokenType.word;

      spans.add(
        TextSpan(
          text: token.text,
          style: defaultStyle.copyWith(
            backgroundColor: shouldApplyHighlight 
                ? highlightBgColor 
                : Colors.transparent,
            color: shouldApplyHighlight 
                ? highlightFgColor 
                : defaultStyle.color,
            fontWeight: shouldApplyHighlight 
                ? FontWeight.w600 
                : defaultStyle.fontWeight,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: defaultStyle,
        children: spans,
      ),
      textAlign: textAlign ?? TextAlign.start,
    );
  }

  /// Tokenizes text into words, punctuation, and spaces
  /// This allows us to highlight only words, not punctuation or spaces
  List<_Token> _tokenizeText(String text) {
    if (text.isEmpty) return [];

    final tokens = <_Token>[];
    int currentOffset = 0;

    // Regex to match:
    // - Word characters (letters, digits, Hindi Devanagari script, underscores)
    // - Words with internal hyphens (like "non-payment", "well-known")
    // - Punctuation (common punctuation marks)
    // - Whitespace (spaces, tabs, newlines)
    // Note: Word pattern requires at least one word character, can contain hyphens internally
    final wordPattern = RegExp(r'[\w\u0900-\u097F]+(?:-[\w\u0900-\u097F]+)*', unicode: true);
    final punctuationPattern = RegExp(r'[.,!?;:()\[\]{}"\''`\-—–…]');
    final spacePattern = RegExp(r'\s+');

    while (currentOffset < text.length) {
      // Try to match a word first
      final wordMatch = wordPattern.matchAsPrefix(text, currentOffset);
      if (wordMatch != null) {
        final word = wordMatch.group(0)!;
        tokens.add(_Token(
          text: word,
          type: _TokenType.word,
          startOffset: currentOffset,
          endOffset: currentOffset + word.length,
          normalizedWord: _normalizeWord(word),
        ));
        currentOffset += word.length;
        continue;
      }

      // Try to match punctuation
      final punctMatch = punctuationPattern.matchAsPrefix(text, currentOffset);
      if (punctMatch != null) {
        final punct = punctMatch.group(0)!;
        tokens.add(_Token(
          text: punct,
          type: _TokenType.punctuation,
          startOffset: currentOffset,
          endOffset: currentOffset + punct.length,
          normalizedWord: '',
        ));
        currentOffset += punct.length;
        continue;
      }

      // Try to match whitespace
      final spaceMatch = spacePattern.matchAsPrefix(text, currentOffset);
      if (spaceMatch != null) {
        final space = spaceMatch.group(0)!;
        tokens.add(_Token(
          text: space,
          type: _TokenType.space,
          startOffset: currentOffset,
          endOffset: currentOffset + space.length,
          normalizedWord: '',
        ));
        currentOffset += space.length;
        continue;
      }

      // If nothing matches, skip one character (shouldn't happen with proper text)
      tokens.add(_Token(
        text: text[currentOffset],
        type: _TokenType.punctuation,
        startOffset: currentOffset,
        endOffset: currentOffset + 1,
        normalizedWord: '',
      ));
      currentOffset++;
    }

    return tokens;
  }

  /// Normalizes a word for comparison (lowercase, remove diacritics if needed)
  String _normalizeWord(String word) {
    // Convert to lowercase and keep only word characters and Hindi
    return word.toLowerCase().replaceAll(RegExp(r'[^\w\u0900-\u097F]', unicode: true), '');
  }

  /// Determines if a token should be highlighted
  bool _shouldHighlightToken({
    required _Token token,
    String? highlightedWord,
    int? highlightStart,
    int? highlightEnd,
  }) {
    // Never highlight spaces or punctuation - only words
    if (token.type != _TokenType.word) {
      return false;
    }

    // Must have a valid normalized word to highlight
    if (token.normalizedWord.isEmpty) {
      return false;
    }

    // PRIMARY: Use offset-based matching for precise position-based highlighting
    // This ensures only the word at the exact position being read is highlighted
    if (highlightStart != null && 
        highlightEnd != null && 
        highlightStart >= 0 && 
        highlightEnd > highlightStart) {
      // Check if this word token overlaps with the highlight range
      // Use a small margin to account for punctuation that might be included in TTS offsets
      final margin = 1; // Small margin for punctuation
      final adjustedStart = (highlightStart - margin).clamp(0, double.infinity).toInt();
      final adjustedEnd = highlightEnd + margin;
      
      // Check if token overlaps with the highlight range
      if (token.startOffset < adjustedEnd && token.endOffset > adjustedStart) {
        // Verify word content matches to avoid false positives
        if (highlightedWord != null && highlightedWord.isNotEmpty) {
          final normalizedHighlight = _normalizeWord(highlightedWord);
          // Word must match for highlighting
          if (normalizedHighlight.isNotEmpty && 
              token.normalizedWord == normalizedHighlight) {
            return true;
          }
        } else {
          // If no word provided, use offset matching only
          return true;
        }
      }
    }

    // SECONDARY: Fallback to word matching only if offsets are not available
    // This should rarely be used, as TTS should provide offsets
    if (highlightedWord != null && highlightedWord.isNotEmpty) {
      // Only use word matching if offsets are not provided
      if (highlightStart == null || highlightEnd == null) {
        final normalizedHighlight = _normalizeWord(highlightedWord);
        
        // Only match if normalized words are exactly equal
        if (normalizedHighlight.isNotEmpty && 
            token.normalizedWord == normalizedHighlight) {
          return true;
        }
      }
    }

    return false;
  }
}