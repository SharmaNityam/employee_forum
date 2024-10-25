import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/post_bloc.dart';
import 'post_card.dart';

enum PostListType { feed, liked, saved }

class PostList extends StatefulWidget {
  final PostListType type;

  const PostList({Key? key, required this.type}) : super(key: key);

  @override
  State<PostList> createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PostBloc>().add(LoadMorePosts());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostBloc, PostState>(
      builder: (context, state) {
        if (state is PostInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PostError) {
          return Center(child: Text(state.message));
        }

        if (state is PostLoaded) {
          var posts = state.posts;
          if (widget.type == PostListType.liked) {
            posts = posts.where((post) => post.isLiked).toList();
          } else if (widget.type == PostListType.saved) {
            posts = posts.where((post) => post.isSaved).toList();
          }

          if (posts.isEmpty) {
            return const Center(
              child: Text('No posts available'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<PostBloc>().add(LoadPosts());
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: posts.length + (state.hasReachedMax ? 0 : 1),
              itemBuilder: (context, index) {
                if (index >= posts.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return PostCard(post: posts[index]);
              },
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}