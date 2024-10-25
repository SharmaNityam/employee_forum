import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/post.dart';
import '../../repository/post_repository.dart';

abstract class PostEvent {}

class LoadPosts extends PostEvent {}
class LoadMorePosts extends PostEvent {}
class ToggleLikePost extends PostEvent {
  final Post post;
  ToggleLikePost(this.post);
}
class ToggleSavePost extends PostEvent {
  final Post post;
  ToggleSavePost(this.post);
}

// States
abstract class PostState {}

class PostInitial extends PostState {}
class PostLoading extends PostState {}
class PostLoaded extends PostState {
  final List<Post> posts;
  final bool hasReachedMax;
  
  PostLoaded({
    required this.posts,
    this.hasReachedMax = false,
  });
  PostLoaded copyWith({
    List<Post>? posts,
    bool? hasReachedMax,
  }) {
    return PostLoaded(
      posts: posts ?? this.posts,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}
class PostError extends PostState {
  final String message;
  PostError(this.message);
}

class PostBloc extends Bloc<PostEvent, PostState> {
  final PostRepository repository;
  int currentPage = 1;
  
  PostBloc({required this.repository}) : super(PostInitial()) {
    on<LoadPosts>(_onLoadPosts);
    on<LoadMorePosts>(_onLoadMorePosts);
    on<ToggleLikePost>(_onToggleLikePost);
    on<ToggleSavePost>(_onToggleSavePost);
  }

  Future<void> _onLoadPosts(LoadPosts event, Emitter<PostState> emit) async {
    try {
      emit(PostLoading());
      final posts = await repository.getPosts(page: 1);
      emit(PostLoaded(posts: posts));
    } catch (e) {
      emit(PostError(e.toString()));
    }
  }

  Future<void> _onLoadMorePosts(LoadMorePosts event, Emitter<PostState> emit) async {
    try {
      if (state is PostLoaded) {
        final currentState = state as PostLoaded;
        final morePosts = await repository.getPosts(page: currentPage + 1);
        
        if (morePosts.isEmpty) {
          emit(currentState.copyWith(hasReachedMax: true));
        } else {
          currentPage++;
          emit(PostLoaded(
            posts: [...currentState.posts, ...morePosts],
            hasReachedMax: false,
          ));
        }
      }
    } catch (e) {
      emit(PostError(e.toString()));
    }
  }

  Future<void> _onToggleLikePost(ToggleLikePost event, Emitter<PostState> emit) async {
    if (state is PostLoaded) {
      final currentState = state as PostLoaded;
      final updatedPosts = currentState.posts.map((post) {
        if (post.id == event.post.id) {
          final updatedPost = post.copyWith(isLiked: !post.isLiked);
          repository.updateLocalPost(updatedPost);
          return updatedPost;
        }
        return post;
      }).toList();
      
      emit(PostLoaded(posts: updatedPosts));
    }
  }

  Future<void> _onToggleSavePost(ToggleSavePost event, Emitter<PostState> emit) async {
    if (state is PostLoaded) {
      final currentState = state as PostLoaded;
      final updatedPosts = currentState.posts.map((post) {
        if (post.id == event.post.id) {
          final updatedPost = post.copyWith(isSaved: !post.isSaved);
          repository.updateLocalPost(updatedPost);
          return updatedPost;
        }
        return post;
      }).toList();
      
      emit(PostLoaded(posts: updatedPosts));
    }
  }
}