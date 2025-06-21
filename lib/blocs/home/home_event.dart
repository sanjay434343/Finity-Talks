import '../../services/wikipedia_service.dart';

abstract class HomeEvent {}

class HomeInitialized extends HomeEvent {}

class HomeEpisodesRequested extends HomeEvent {}

class HomeEpisodeSelected extends HomeEvent {
  final WikipediaEpisode episode;
  
  HomeEpisodeSelected(this.episode);
}

class HomeEpisodeShared extends HomeEvent {
  final WikipediaEpisode episode;
  
  HomeEpisodeShared(this.episode);
}

class HomeEpisodeSaved extends HomeEvent {
  final WikipediaEpisode episode;
  
  HomeEpisodeSaved(this.episode);
}

class HomeForceRefresh extends HomeEvent {}
