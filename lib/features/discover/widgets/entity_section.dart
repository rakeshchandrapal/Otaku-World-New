import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:otaku_world/bloc/paginated_data/paginated_data_bloc.dart';
import 'package:otaku_world/features/discover/widgets/entity_card.dart';
import 'package:otaku_world/graphql/__generated/graphql/fragments.graphql.dart';
import 'package:otaku_world/theme/colors.dart';

import '../../../bloc/graphql_client/graphql_client_cubit.dart';
import '../../../core/ui/error_text.dart';
import '../../../core/ui/list_progress_indicator.dart';
import '../../../core/ui/media_section/scroll_to_left_button.dart';
import '../../../core/ui/shimmers/shimmer_loader_list.dart';
import '../../../utils/ui_utils.dart';

class EntitySection<B extends PaginatedDataBloc, E> extends HookWidget {
  const EntitySection({
    super.key,
    required this.label,
    this.leftPadding = 15,
    required this.heroTag,
    required this.onViewAll,
  });

  final String label;
  final double leftPadding;
  final String heroTag;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    useAutomaticKeepAlive();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final scrollController = useScrollController();

    useEffect(() {
      scrollController.addListener(() {
        final maxScroll = scrollController.position.maxScrollExtent;
        final currentScroll = scrollController.position.pixels;

        if (currentScroll == maxScroll) {
          final bloc = context.read<B>();
          final hasNextPage = (bloc.state as PaginatedDataLoaded).hasNextPage;
          if (hasNextPage) {
            final client = (context.read<GraphqlClientCubit>().state
                    as GraphqlClientInitialized)
                .client;
            bloc.add(LoadData(client));
          }
        }
      });
      return null;
    }, const []);

    return Padding(
      padding: EdgeInsets.only(
        left: leftPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontFamily: 'Roboto-Condensed',
                      fontWeight: FontWeight.w500,
                    ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  'View All',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontFamily: 'Roboto-Condensed',
                        color: AppColors.sunsetOrange,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          // Media list
          BlocBuilder<B, PaginatedDataState>(
            builder: (context, state) {
              if (state is PaginatedDataInitial) {
                final client = (context.read<GraphqlClientCubit>().state
                        as GraphqlClientInitialized)
                    .client;
                context.read<B>().add(LoadData(client));
                return ShimmerLoaderList(
                  widgetWidth: UIUtils.getWidgetWidth(
                    targetWidgetWidth: 115,
                    screenWidth: screenWidth,
                  ),
                  widgetHeight: UIUtils.getWidgetHeight(
                    targetWidgetHeight: 169,
                    screenHeight: screenHeight,
                  ),
                  height: UIUtils.getWidgetHeight(
                    targetWidgetHeight: 169,
                    screenHeight: screenHeight,
                  ),
                  widgetBorder: 10,
                  direction: Axis.horizontal,
                );
              } else if (state is PaginatedDataLoading) {
                return ShimmerLoaderList(
                  widgetWidth: UIUtils.getWidgetWidth(
                    targetWidgetWidth: 115,
                    screenWidth: screenWidth,
                  ),
                  widgetHeight: UIUtils.getWidgetHeight(
                    targetWidgetHeight: 169,
                    screenHeight: screenHeight,
                  ),
                  height: UIUtils.getWidgetHeight(
                    targetWidgetHeight: 169,
                    screenHeight: screenHeight,
                  ),
                  widgetBorder: 10,
                  direction: Axis.horizontal,
                );
              } else if (state is PaginatedDataLoaded) {
                return _buildEntityList(
                  state.list as List<E?>,
                  state.hasNextPage,
                  scrollController,
                );
              } else if (state is PaginatedDataError) {
                return ErrorText(
                  message: state.message,
                  onTryAgain: () {
                    final client = (context.read<GraphqlClientCubit>().state
                            as GraphqlClientInitialized)
                        .client;
                    context.read<B>().add(LoadData(client));
                  },
                );
              } else {
                return const Text('Unknown State');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEntityList(
    List<E?> list,
    bool hasNextPage,
    ScrollController controller,
  ) {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          CustomScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            controller: controller,
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (list[index] == null) return const SizedBox();

                    if (E == Fragment$CharacterShort) {
                      final character = list[index] as Fragment$CharacterShort;
                      return EntityCard(
                        title: character.name?.userPreferred ?? ' - - ',
                        imageUrl: character.image?.large,
                        favorites: character.favourites,
                        rightMargin: 10,
                      );
                    } else if (E == Fragment$StaffShort) {
                      final staff = list[index] as Fragment$StaffShort;
                      return EntityCard(
                        title: staff.name?.userPreferred ?? ' - - ',
                        imageUrl: staff.image?.large,
                        favorites: staff.favourites,
                        rightMargin: 10,
                      );
                    } else {
                      return const SizedBox();
                    }
                  },
                  childCount: list.length,
                ),
              ),
              if (hasNextPage)
                const SliverToBoxAdapter(
                  child: ListProgressIndicator(),
                ),
            ],
          ),
          ScrollToLeftFAB(controller: controller, tag: heroTag),
        ],
      ),
    );
  }
}