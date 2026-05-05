import 'package:equatable/equatable.dart';
import '../models/waste_listing_model.dart';

abstract class ListingState extends Equatable {
  const ListingState();

  @override
  List<Object?> get props => [];
}

class ListingInitial extends ListingState {
  const ListingInitial();
}

class ListingLoading extends ListingState {
  const ListingLoading();
}

class ListingLoaded extends ListingState {
  final List<WasteListingModel> listings;

  const ListingLoaded(this.listings);

  @override
  List<Object?> get props => [listings];
}

class ListingDetailLoaded extends ListingState {
  final WasteListingModel listing;

  const ListingDetailLoaded(this.listing);

  @override
  List<Object?> get props => [listing];
}

class ListingError extends ListingState {
  final String message;

  const ListingError(this.message);

  @override
  List<Object?> get props => [message];
}
