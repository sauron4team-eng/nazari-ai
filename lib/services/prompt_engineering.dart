/// Templates système et prompts structurés pour Gemma 4
/// Tous les prompts forcent une sortie JSON parsable par Flutter.

class PromptEngineering {
  static const String systemInstruction = '''
You are NazariAI, an expert academic assistant powered by Gemma 4.
You help students study offline by analyzing documents, answering questions,
generating quizzes, flashcards, and extracting key concepts.
Always respond in the same language as the user's query.
Be concise, accurate, and pedagogical.
''';

  static String summarizeDocument(String documentText, {String? title}) {
    final t = title ?? 'the uploaded document';
    return '''
Please provide a comprehensive summary of \$t.

Document content:
---
\$documentText
---

Respond with a clear, structured summary suitable for exam revision.
'''.trim();
  }

  static String generateQuiz(String content, {int questionCount = 10}) {
    return '''
Generate a multiple-choice quiz with exactly \$questionCount questions based on the following content.

Content:
---
\$content
---

Respond ONLY with a valid JSON object in this exact format (no markdown, no explanation):
{
  "title": "Quiz Title",
  "questions": [
    {
      "question": "Question text?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correct": 0,
      "explanation": "Why this answer is correct"
    }
  ]
}
The "correct" field is the zero-based index of the correct option.
'''.trim();
  }

  static String generateFlashcards(String content, {int cardCount = 20}) {
    return '''
Generate \$cardCount flashcards for active recall study based on the following content.

Content:
---
\$content
---

Respond ONLY with a valid JSON object in this exact format (no markdown, no explanation):
{
  "title": "Deck Title",
  "cards": [
    {
      "front": "Term or Question",
      "back": "Definition or Answer",
      "tag": "Optional category"
    }
  ]
}
'''.trim();
  }

  static String extractKeywords(String content, {int keywordCount = 15}) {
    return '''
Extract the \$keywordCount most important key concepts/terms from the following content.
For each term, provide a concise definition and the context in which it appears.

Content:
---
\$content
---

Respond ONLY with a valid JSON object in this exact format (no markdown, no explanation):
{
  "title": "Keywords from Document",
  "keywords": [
    {
      "term": "Key Term",
      "definition": "Short definition",
      "context": "Where/how it appears in the text"
    }
  ]
}
'''.trim();
  }

  static String answerQuestion(String question, {String? documentContext}) {
    final ctx = documentContext != null
        ? '\n\nRelevant document context:\n---\n\$documentContext\n---'
        : '';
    return '''
Answer the following student question accurately and pedagogically.\$ctx

Question: \$question

Provide a clear, well-structured answer. If the question relates to a previously uploaded document, reference it.
'''.trim();
  }

  static String generateTitle(String userMessage) {
    return '''
Generate a short, concise title (max 5 words) for a conversation that starts with this message:
"\$userMessage"

Respond with ONLY the title text, no quotes, no punctuation at the end.
'''.trim();
  }
}
