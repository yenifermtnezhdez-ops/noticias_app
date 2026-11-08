
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final int newsId;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommentModel({
    required this.id,
    required this.newsId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

 
  factory CommentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return CommentModel(
      id: document.id,
      newsId: (data['newsId'] as num?)?.toInt() ?? 0,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Usuario',
      content: data['content'] as String? ?? '',
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }


  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Map<String, dynamic> toMap() {
    return {
      'newsId': newsId,
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  
  CommentModel copyWith({
    String? content,
    String? userName,
    DateTime? updatedAt,
  }) {
    return CommentModel(
      id: id,
      newsId: newsId,
      userId: userId,
      userName: userName ?? this.userName,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
