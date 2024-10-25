  import 'package:flutter_bloc/flutter_bloc.dart';
  import '../../repository/post_repository.dart';
  import '../../models/post.dart';

  abstract class SearchEvent {}

  class SearchPosts extends SearchEvent {
    final String query;
    SearchPosts({required this.query});
  }

  abstract class SearchState {}

  class SearchInitial extends SearchState {}
  class SearchLoading extends SearchState {}
  class SearchLoaded extends SearchState {
    final List<Post> posts;
    SearchLoaded({required this.posts});
  }
  class SearchError extends SearchState {
    final String message;
    SearchError({required this.message});
  }

  class SearchBloc extends Bloc<SearchEvent, SearchState> {
    final PostRepository repository;

    SearchBloc({required this.repository}) : super(SearchInitial()) {
      on<SearchPosts>(_onSearchPosts);
    }

    Future<void> _onSearchPosts(SearchPosts event, Emitter<SearchState> emit) async {
      if (event.query.isEmpty) {
        emit(SearchInitial());
        return;
      }

      try {
        emit(SearchLoading());
        final posts = await repository.searchPosts(query: event.query);
        emit(SearchLoaded(posts: posts));
      } catch (e) {
        emit(SearchError(message: e.toString()));
      }
    }
  }