class MusicTrack {
  final int trackId;
  final String trackName;
  final String artistName;
  final String albumName;
  final String artworkUrl100;
  final String artworkUrl600;
  final String previewUrl;
  final int trackTimeMillis;
  final String genre;
  final DateTime releaseDate;
  final String country;
  final double trackPrice;
  final String currency;

  MusicTrack({
    required this.trackId,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    required this.artworkUrl100,
    required this.artworkUrl600,
    required this.previewUrl,
    required this.trackTimeMillis,
    required this.genre,
    required this.releaseDate,
    required this.country,
    required this.trackPrice,
    required this.currency,
  });

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      trackId: json['trackId'] ?? 0,
      trackName: json['trackName'] ?? 'Unknown Track',
      artistName: json['artistName'] ?? 'Unknown Artist',
      albumName: json['collectionName'] ?? 'Unknown Album',
      artworkUrl100: json['artworkUrl100'] ?? '',
      artworkUrl600: json['artworkUrl100']?.replaceAll('100x100', '600x600') ?? '',
      previewUrl: json['previewUrl'] ?? '',
      trackTimeMillis: json['trackTimeMillis'] ?? 0,
      genre: json['primaryGenreName'] ?? 'Unknown',
      releaseDate: DateTime.tryParse(json['releaseDate'] ?? '') ?? DateTime.now(),
      country: json['country'] ?? 'US',
      trackPrice: (json['trackPrice'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
    );
  }

  String get formattedDuration {
    final duration = Duration(milliseconds: trackTimeMillis);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedPrice {
    if (trackPrice == 0.0) return 'Free Preview';
    return '$currency ${trackPrice.toStringAsFixed(2)}';
  }
}

class MusicSearchResponse {
  final int resultCount;
  final List<MusicTrack> results;

  MusicSearchResponse({
    required this.resultCount,
    required this.results,
  });

  factory MusicSearchResponse.fromJson(Map<String, dynamic> json) {
    return MusicSearchResponse(
      resultCount: json['resultCount'] ?? 0,
      results: (json['results'] as List? ?? [])
          .map((track) => MusicTrack.fromJson(track))
          .where((track) => track.previewUrl.isNotEmpty) // Only include tracks with preview URLs
          .toList(),
    );
  }
}
