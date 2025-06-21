import '../../services/wikipedia_service.dart';

abstract class HomeState {
  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;
  
  @override
  int get hashCode => runtimeType.hashCode;
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<WikipediaEpisode> episodes;
  final List<WikipediaEpisode> savedEpisodes;
  final WikipediaEpisode? currentlyPlaying;
  final DateTime lastUpdated;
  
  HomeLoaded({
    required this.episodes,
    required this.savedEpisodes,
    this.currentlyPlaying,
    required this.lastUpdated,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HomeLoaded) return false;
    return episodes.length == other.episodes.length &&
           savedEpisodes.length == other.savedEpisodes.length &&
           currentlyPlaying?.title == other.currentlyPlaying?.title &&
           lastUpdated.millisecondsSinceEpoch == other.lastUpdated.millisecondsSinceEpoch;
  }

  @override
  int get hashCode => Object.hash(
    episodes.length,
    savedEpisodes.length,
    currentlyPlaying?.title,
    lastUpdated.millisecondsSinceEpoch,
  );

  HomeLoaded copyWith({
    List<WikipediaEpisode>? episodes,
    List<WikipediaEpisode>? savedEpisodes,
    WikipediaEpisode? currentlyPlaying,
    DateTime? lastUpdated,
  }) {
    return HomeLoaded(
      episodes: episodes ?? this.episodes,
      savedEpisodes: savedEpisodes ?? this.savedEpisodes,
      currentlyPlaying: currentlyPlaying ?? this.currentlyPlaying,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class HomeError extends HomeState {
  final String message;
  
  HomeError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HomeError) return false;
    return message == other.message;
  }

  @override
  int get hashCode => message.hashCode;
}

class HomeEpisodeAction extends HomeState {
  final String message;
  final HomeActionType actionType;
  final List<WikipediaEpisode> episodes;
  final List<WikipediaEpisode> savedEpisodes;
  final WikipediaEpisode? currentlyPlaying;
  final DateTime lastUpdated;
  
  HomeEpisodeAction(
    this.message,
    this.actionType, {
    required this.episodes,
    required this.savedEpisodes,
    this.currentlyPlaying,
    required this.lastUpdated,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HomeEpisodeAction) return false;
    return message == other.message &&
           actionType == other.actionType &&
           episodes.length == other.episodes.length &&
           savedEpisodes.length == other.savedEpisodes.length &&
           currentlyPlaying?.title == other.currentlyPlaying?.title &&
           lastUpdated.millisecondsSinceEpoch == other.lastUpdated.millisecondsSinceEpoch;
  }

  @override
  int get hashCode => Object.hash(
    message,
    actionType,
    episodes.length,
    savedEpisodes.length,
    currentlyPlaying?.title,
    lastUpdated.millisecondsSinceEpoch,
  );
}

enum HomeActionType {
  played,
  shared,
  saved,
  removed,
  refreshed,
}
