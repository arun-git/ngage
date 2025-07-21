import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/post_providers.dart';
import 'widgets/create_post_widget.dart';

/// Main social feed screen showing posts from user's groups
class SocialFeedScreen extends ConsumerStatefulWidget {
  final String memberId;
  final String? groupId; // Optional: filter by specific group

  const SocialFeedScreen({
    super.key,
    required this.memberId,
    this.groupId,
  });

  @override
  ConsumerState<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends ConsumerState<SocialFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  
  // Pagination state
  int _currentOffset = 0;
  final int _pageSize = 20;
  bool _isLoadingMore = false;
  final List<Post> _allPosts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupId != null ? 'Group Feed' : 'Social Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshFeed(),
            tooltip: 'Refresh Feed',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Feed'),
            Tab(icon: Icon(Icons.trending_up), text: 'Trending'),
            Tab(icon: Icon(Icons.person), text: 'My Posts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Main feed
          _buildMainFeed(),
          
          // Trending posts
          _buildTrendingFeed(),
          
          // User's posts
          _buildMyPosts(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(),
        tooltip: 'Create Post',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMainFeed() {
    if (widget.groupId != null) {
      // Group-specific feed
      final groupPostsRequest = GroupPostsRequest(
        groupId: widget.groupId!,
        memberId: widget.memberId,
        limit: _pageSize,
        offset: _currentOffset,
      );
      
      final postsAsync = ref.watch(groupPostsProvider(groupPostsRequest));
      
      return postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(error),
        data: (posts) => _buildPostsList(posts),
      );
    } else {
      // Social feed from all groups
      final feedRequest = SocialFeedRequest(
        memberId: widget.memberId,
        limit: _pageSize,
        offset: _currentOffset,
      );
      
      final feedAsync = ref.watch(socialFeedProvider(feedRequest));
      
      return feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(error),
        data: (posts) => _buildPostsList(posts),
      );
    }
  }

  Widget _buildTrendingFeed() {
    final trendingRequest = TrendingPostsRequest(
      groupId: widget.groupId,
      timeWindow: const Duration(days: 7),
      limit: 50,
    );
    
    final trendingAsync = ref.watch(trendingPostsProvider(trendingRequest));
    
    return trendingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error),
      data: (posts) => TrendingPostsWidget(
        posts: posts,
        memberId: widget.memberId,
      ),
    );
  }

  Widget _buildMyPosts() {
    final myPostsRequest = MemberPostsRequest(
      memberId: widget.memberId,
      groupId: widget.groupId,
      limit: 50,
    );
    
    final myPostsAsync = ref.watch(memberPostsProvider(myPostsRequest));
    
    return myPostsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error),
      data: (posts) => _buildPostsList(posts, showCreatePrompt: true),
    );
  }

  Widget _buildPostsList(List<Post> posts, {bool showCreatePrompt = false}) {
    if (posts.isEmpty) {
      return _buildEmptyState(showCreatePrompt);
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshFeed(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: posts.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == posts.length) {
            // Loading indicator at bottom
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          
          final post = posts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PostCardWidget(
              post: post,
              currentMemberId: widget.memberId,
              onPostUpdated: () => _refreshFeed(),
              onPostDeleted: () => _refreshFeed(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool showCreatePrompt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            showCreatePrompt ? 'No posts yet' : 'No posts to show',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            showCreatePrompt 
                ? 'Share your first post with the community!'
                : 'Check back later for new content.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (showCreatePrompt) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreatePostDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create Post'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading posts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _refreshFeed(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showCreatePostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: CreatePostWidget(
          authorId: widget.memberId,
          groupId: widget.groupId ?? '', // This would need proper group selection
          onPostCreated: (post) {
            Navigator.of(context).pop();
            _refreshFeed();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Post created successfully!')),
            );
          },
        ),
      ),
    );
  }

  void _refreshFeed() {
    setState(() {
      _currentOffset = 0;
      _allPosts.clear();
    });
    
    // Invalidate providers to force refresh
    if (widget.groupId != null) {
      ref.invalidate(groupPostsProvider);
    } else {
      ref.invalidate(socialFeedProvider);
    }
    ref.invalidate(trendingPostsProvider);
    ref.invalidate(memberPostsProvider);
  }

  void _loadMorePosts() {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
      _currentOffset += _pageSize;
    });
    
    // This would trigger loading more posts
    // In a real implementation, you'd need to handle pagination properly
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    });
  }
}