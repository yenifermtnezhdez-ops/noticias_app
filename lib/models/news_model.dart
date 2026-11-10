
class NewsModel {
  final int id;
  final String title;
  final String content;
  final String date;
  final String link;

  const NewsModel({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.link,
  });

  
  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: (json['id'] as num).toInt(),
      title: json['title']['rendered'] as String,
      content: json['content']['rendered'] as String,
      date: json['date'] as String,
      link: json['link'] as String,
    );
  }


  factory NewsModel.fromCacheJson(
    Map<String, dynamic> json,
  ) {
    return NewsModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      date: json['date'] as String? ?? '',
      link: json['link'] as String? ?? '',
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date,
      'link': link,
    };
  }
}
