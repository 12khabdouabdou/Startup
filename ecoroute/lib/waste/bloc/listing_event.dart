import 'package:equatable/equatable.dart';

abstract class ListingEvent extends Equatable {
  const ListingEvent();

  @override
  List<Object?> get props => [];
}

class ListingLoadAll extends ListingEvent {
  const ListingLoadAll();
}

class ListingLoadById extends ListingEvent {
  final String listingId;

  const ListingLoadById(this.listingId);

  @override
  List<Object?> get props => [listingId];
}

class ListingCreate extends ListingEvent {
  final Map<String, dynamic> listingData;

  const ListingCreate(this.listingData);

  @override
  List<Object?> get props => [listingData];
}

class ListingUpdate extends ListingEvent {
  final String listingId;
  final Map<String, dynamic> updates;

  const ListingUpdate(this.listingId, this.updates);

  @override
  List<Object?> get props => [listingId, updates];
}

class ListingDelete extends ListingEvent {
  final String listingId;

  const ListingDelete(this.listingId);

  @override
  List<Object?> get props => [listingId];
}

class ListingFilter extends ListingEvent {
  final String wasteType;

  const ListingFilter(this.wasteType);

  @override
  List<Object?> get props => [wasteType];
}
