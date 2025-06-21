import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GitHubService {
  static const String _baseUrl = 'https://api.github.com';
  static const String username = 'sanjay434343';

  // Fetch user profile data
  static Future<GitHubProfile?> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$username'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return GitHubProfile.fromJson(data);
      } else {
        if (kDebugMode) {
          print('Failed to load GitHub profile: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching GitHub profile: $e');
      }
      return null;
    }
  }

  // Fetch user repositories
  static Future<List<GitHubRepo>> getUserRepos() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$username/repos?sort=updated&per_page=10'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((repo) => GitHubRepo.fromJson(repo)).toList();
      } else {
        if (kDebugMode) {
          print('Failed to load repositories: ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching repositories: $e');
      }
      return [];
    }
  }

  // Fetch user events/activity
  static Future<List<GitHubEvent>> getUserEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$username/events/public?per_page=5'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((event) => GitHubEvent.fromJson(event)).toList();
      } else {
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching events: $e');
      }
      return [];
    }
  }
}

class GitHubProfile {
  final String login;
  final String name;
  final String? bio;
  final String avatarUrl;
  final int publicRepos;
  final int followers;
  final int following;
  final String? location;
  final String? company;
  final String? blog;
  final DateTime createdAt;
  final DateTime updatedAt;

  GitHubProfile({
    required this.login,
    required this.name,
    this.bio,
    required this.avatarUrl,
    required this.publicRepos,
    required this.followers,
    required this.following,
    this.location,
    this.company,
    this.blog,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GitHubProfile.fromJson(Map<String, dynamic> json) {
    return GitHubProfile(
      login: json['login'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'],
      avatarUrl: json['avatar_url'] ?? '',
      publicRepos: json['public_repos'] ?? 0,
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      location: json['location'],
      company: json['company'],
      blog: json['blog'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class GitHubRepo {
  final String name;
  final String? description;
  final String language;
  final int stargazersCount;
  final int forksCount;
  final DateTime updatedAt;
  final String htmlUrl;
  final bool fork;

  GitHubRepo({
    required this.name,
    this.description,
    required this.language,
    required this.stargazersCount,
    required this.forksCount,
    required this.updatedAt,
    required this.htmlUrl,
    required this.fork,
  });

  factory GitHubRepo.fromJson(Map<String, dynamic> json) {
    return GitHubRepo(
      name: json['name'] ?? '',
      description: json['description'],
      language: json['language'] ?? 'Unknown',
      stargazersCount: json['stargazers_count'] ?? 0,
      forksCount: json['forks_count'] ?? 0,
      updatedAt: DateTime.parse(json['updated_at']),
      htmlUrl: json['html_url'] ?? '',
      fork: json['fork'] ?? false,
    );
  }
}

class GitHubEvent {
  final String type;
  final String repoName;
  final DateTime createdAt;

  GitHubEvent({
    required this.type,
    required this.repoName,
    required this.createdAt,
  });

  factory GitHubEvent.fromJson(Map<String, dynamic> json) {
    return GitHubEvent(
      type: json['type'] ?? '',
      repoName: json['repo']?['name'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get displayType {
    switch (type) {
      case 'PushEvent':
        return 'Pushed code';
      case 'CreateEvent':
        return 'Created';
      case 'WatchEvent':
        return 'Starred';
      case 'ForkEvent':
        return 'Forked';
      case 'IssuesEvent':
        return 'Issue activity';
      case 'PullRequestEvent':
        return 'Pull request';
      default:
        return type;
    }
  }
}