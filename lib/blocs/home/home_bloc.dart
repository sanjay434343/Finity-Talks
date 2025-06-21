import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../services/wikipedia_service.dart';
import '../../services/local_database_service.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final WikipediaService _wikipediaService = WikipediaService();
  final LocalDatabaseService _localDb = LocalDatabaseService();
  
  // Add state preservation
  HomeLoaded? _lastValidState;
  
  HomeBloc() : super(HomeInitial()) {
    on<HomeInitialized>(_onHomeInitialized);
    on<HomeEpisodesRequested>(_onHomeEpisodesRequested);
    on<HomeEpisodeSelected>(_onHomeEpisodeSelected);
    on<HomeEpisodeShared>(_onHomeEpisodeShared);
    on<HomeEpisodeSaved>(_onHomeEpisodeSaved);
    on<HomeForceRefresh>(_onHomeForceRefresh);
  }

  Future<void> _onHomeInitialized(
    HomeInitialized event,
    Emitter<HomeState> emit,
  ) async {
    // If we have a valid previous state, emit it immediately to avoid loading
    if (_lastValidState != null) {
      if (state != _lastValidState) { // Only emit if state actually changed
        emit(_lastValidState!);
      }
      return;
    }
    
    // Only emit loading if we're not already in a loaded state
    if (state is! HomeLoaded) {
      emit(HomeLoading());
    }
    
    try {
      // Check cache status for debugging
      if (kDebugMode) {
        final cacheInfo = await _localDb.getCacheInfo();
        print('Cache info on home init: $cacheInfo');
      }
      
      // Get episodes (will use cache if valid, otherwise fetch fresh)
      final episodes = await _wikipediaService.getDailyEpisodes();
      
      final loadedState = HomeLoaded(
        episodes: episodes,
        savedEpisodes: [], // TODO: Implement saved episodes
        currentlyPlaying: null,
        lastUpdated: DateTime.now(),
      );
      
      _lastValidState = loadedState;
      emit(loadedState);
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing home: $e');
      }
      emit(HomeError('Failed to load episodes. Please try again.'));
    }
  }

  Future<void> _onHomeEpisodesRequested(
    HomeEpisodesRequested event,
    Emitter<HomeState> emit,
  ) async {
    // Always preserve current state if we have episodes
    if (_lastValidState != null) {
      emit(_lastValidState!);
    } else if (state is! HomeLoaded) {
      emit(HomeLoading());
    }
    
    try {
      final episodes = await _wikipediaService.getDailyEpisodes();
      
      final currentState = state;
      final loadedState = HomeLoaded(
        episodes: episodes,
        savedEpisodes: currentState is HomeLoaded ? currentState.savedEpisodes : [],
        currentlyPlaying: currentState is HomeLoaded ? currentState.currentlyPlaying : null,
        lastUpdated: DateTime.now(),
      );
      
      _lastValidState = loadedState;
      emit(loadedState);
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting episodes: $e');
      }
      // Don't emit error if we have a valid previous state
      if (_lastValidState == null) {
        emit(HomeError('Failed to load episodes. Please try again.'));
      }
    }
  }

  Future<void> _onHomeForceRefresh(
    HomeForceRefresh event,
    Emitter<HomeState> emit,
  ) async {
    // Only show loading for force refresh
    emit(HomeLoading());
    
    try {
      // Force refresh episodes (ignore cache)
      final episodes = await _wikipediaService.forceRefreshEpisodes();
      
      final loadedState = HomeLoaded(
        episodes: episodes,
        savedEpisodes: [], // Reset saved episodes on force refresh
        currentlyPlaying: null,
        lastUpdated: DateTime.now(),
      );
      
      _lastValidState = loadedState;
      emit(loadedState);
      
      // Emit a temporary action state to show success message
      emit(HomeEpisodeAction(
        'Episodes refreshed successfully!',
        HomeActionType.refreshed,
        episodes: episodes,
        savedEpisodes: [],
        currentlyPlaying: null,
        lastUpdated: DateTime.now(),
      ));
      
      // Return to loaded state
      await Future.delayed(const Duration(milliseconds: 100));
      emit(loadedState);
    } catch (e) {
      if (kDebugMode) {
        print('Error force refreshing episodes: $e');
      }
      emit(HomeError('Failed to refresh episodes. Please try again.'));
    }
  }

  void _onHomeEpisodeSelected(
    HomeEpisodeSelected event,
    Emitter<HomeState> emit,
  ) {
    final currentState = state;
    if (currentState is HomeLoaded) {
      final loadedState = HomeLoaded(
        episodes: currentState.episodes,
        savedEpisodes: currentState.savedEpisodes,
        currentlyPlaying: event.episode,
        lastUpdated: currentState.lastUpdated,
      );
      
      _lastValidState = loadedState;
      emit(loadedState);
    }
  }

  void _onHomeEpisodeShared(
    HomeEpisodeShared event,
    Emitter<HomeState> emit,
  ) {
    final currentState = state;
    if (currentState is HomeLoaded) {
      // Show temporary action state
      emit(HomeEpisodeAction(
        'Episode shared successfully!',
        HomeActionType.shared,
        episodes: currentState.episodes,
        savedEpisodes: currentState.savedEpisodes,
        currentlyPlaying: currentState.currentlyPlaying,
        lastUpdated: currentState.lastUpdated,
      ));
      
      // Return to loaded state
      Future.delayed(const Duration(milliseconds: 100)).then((_) {
        if (!isClosed) {
          _lastValidState = HomeLoaded(
            episodes: currentState.episodes,
            savedEpisodes: currentState.savedEpisodes,
            currentlyPlaying: currentState.currentlyPlaying,
            lastUpdated: currentState.lastUpdated,
          );
          emit(_lastValidState!);
        }
      });
    }
  }

  void _onHomeEpisodeSaved(
    HomeEpisodeSaved event,
    Emitter<HomeState> emit,
  ) {
    final currentState = state;
    if (currentState is HomeLoaded) {
      List<WikipediaEpisode> updatedSavedEpisodes = List.from(currentState.savedEpisodes);
      String message;
      HomeActionType actionType;
      
      // Check if episode is already saved
      final isAlreadySaved = updatedSavedEpisodes.any((ep) => ep.title == event.episode.title);
      
      if (isAlreadySaved) {
        // Remove from saved
        updatedSavedEpisodes.removeWhere((ep) => ep.title == event.episode.title);
        message = 'Episode removed from saved!';
        actionType = HomeActionType.removed;
      } else {
        // Add to saved
        updatedSavedEpisodes.add(event.episode);
        message = 'Episode saved successfully!';
        actionType = HomeActionType.saved;
      }
      
      final updatedState = HomeLoaded(
        episodes: currentState.episodes,
        savedEpisodes: updatedSavedEpisodes,
        currentlyPlaying: currentState.currentlyPlaying,
        lastUpdated: currentState.lastUpdated,
      );
      
      // Show temporary action state
      emit(HomeEpisodeAction(
        message,
        actionType,
        episodes: currentState.episodes,
        savedEpisodes: updatedSavedEpisodes,
        currentlyPlaying: currentState.currentlyPlaying,
        lastUpdated: currentState.lastUpdated,
      ));
      
      // Return to loaded state with updated saved episodes
      Future.delayed(const Duration(milliseconds: 100)).then((_) {
        if (!isClosed) {
          _lastValidState = updatedState;
          emit(updatedState);
        }
      });
    }
  }
}
