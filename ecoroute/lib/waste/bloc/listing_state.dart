import 'package:equatable/equatable.dart';

import '../models/waste_listing_model.dart';

sealed class ListingState extends Equatable {
  const ListingState();

  @override
  List<Object?> get props => [];
}

final class ListingInitial extends ListingState {
  const ListingInitial();
}

final class ListingLoading extends ListingState {
  const ListingLoading();
}

final class ListingLoaded extends ListingState {
  final List<WasteListingModel> listings;

  const ListingLoaded(this.listings);

  @override
  List<Object?> get props => [listings];
}

final class ListingDetailLoaded extends ListingState {
  final WasteListingModel listing;

  const ListingDetailLoaded(this.listing);

  @override
  List<Object?> get props => [listing];
}

final class ListingError extends ListingState {
  final String message;

  const ListingError(this.message);

  @override
  List<Object?> get props => [message];
}
