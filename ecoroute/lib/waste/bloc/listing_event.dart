import 'package:equatable/equatable.dart';

sealed class ListingEvent extends Equatable {
  const ListingEvent();

  @override
  List<Object?> get props => [];
}

final class ListingLoadAll extends ListingEvent {
  const ListingLoadAll();
}

final class ListingLoadById extends ListingEvent {
  final String listingId;

  const ListingLoadById(this.listingId);

  @override
  List<Object?> get props => [listingId];
}

final class ListingCreate extends ListingEvent {
  final Map<String, dynamic> listingData;

  const ListingCreate(this.listingData);

  @override
  List<Object?> get props => [listingData];
}

final class ListingUpdate extends ListingEvent {
  final String listingId;
  final Map<String, dynamic> updates;

  const ListingUpdate(this.listingId, this.updates);

  @override
  List<Object?> get props => [listingId, updates];
}

final class ListingDelete extends ListingEvent {
  final String listingId;

  const ListingDelete(this.listingId);

  @override
  List<Object?> get props => [listingId];
}
