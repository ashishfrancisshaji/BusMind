import 'package:hive/hive.dart';
import 'flashcard_provider.dart';

/// ADAPTER: Teaches Hive how to save and load Flashcard objects
/// 
/// Think of this as a translator between your Flashcard class and Hive's storage.
/// 
/// When you save a flashcard:
/// write() breaks it into simple pieces → Hive stores them
/// 
/// When you load a flashcard:
/// Hive retrieves pieces → read() rebuilds your Flashcard object

class FlashcardAdapter extends TypeAdapter<Flashcard> {
  @override
  final int typeId = 0; // Unique ID - use 0 if no other adapters exist
  
  /// READ: Rebuilds a Flashcard from stored data
  @override
  Flashcard read(BinaryReader reader) {
    return Flashcard(
      id: reader.readString(),           // Read piece 1: id
      question: reader.readString(),     // Read piece 2: question
      answer: reader.readString(),       // Read piece 3: answer
      category: reader.readString(),     // Read piece 4: category
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()), // Piece 5
      reviewCount: reader.readInt(),     // Read piece 6: review count
      difficulty: reader.readDouble(),   // Read piece 7: difficulty
      lastReviewed: reader.readBool()    // Check if lastReviewed exists
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
          : null,
    );
  }

  /// WRITE: Breaks down a Flashcard into simple pieces for storage
  @override
  void write(BinaryWriter writer, Flashcard obj) {
    writer.writeString(obj.id);        // Store piece 1
    writer.writeString(obj.question);  // Store piece 2
    writer.writeString(obj.answer);    // Store piece 3
    writer.writeString(obj.category);  // Store piece 4
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch); // Store piece 5
    writer.writeInt(obj.reviewCount);  // Store piece 6
    writer.writeDouble(obj.difficulty); // Store piece 7
    
    // Handle nullable lastReviewed field
    writer.writeBool(obj.lastReviewed != null);
    if (obj.lastReviewed != null) {
      writer.writeInt(obj.lastReviewed!.millisecondsSinceEpoch);
    }
  }
}