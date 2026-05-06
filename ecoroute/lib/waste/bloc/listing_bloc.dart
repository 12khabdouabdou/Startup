import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/supabase_client.dart';
import '../repository/listing_repository.dart';
import '../models/waste_listing_model.dart';
import 'listing_event.dart';
import 'listing_state.dart';

class ListingBloc extends Bloc<ListingEvent, ListingState> {
  final ListingRepository _repository;

  ListingBloc(this._repository) : super(const ListingInitial()) {
    on<ListingLoadAll>(_onLoadAll);
    on<ListingLoadById>(_onLoadById);
    on<ListingCreate>(_onCreate);
    on<ListingUpdate>(_onUpdate);
    on<ListingDelete>(_onDelete);
  }

  Future<void> _onLoadAll(
    ListingLoadAll event,
    Emitter<ListingState> emit,
  ) async {
    try {
      emit(const ListingLoading());
      final listings = await _repository.getAllListings();
      emit(ListingLoaded(listings));
    } on Exception catch (e) {
      emit(ListingError(e.toString()));
    }
  }

  Future<void> _onLoadById(
    ListingLoadById event,
    Emitter<ListingState> emit,
  ) async {
    try {
      emit(const ListingLoading());
      final listing = await _repository.getListingById(event.listingId);
      if (listing != null) {
        emit(ListingDetailLoaded(listing));
      } else {
        emit(const ListingError('Listing not found'));
      }
    } on Exception catch (e) {
      emit(ListingError(e.toString()));
    }
  }

  Future<void> _onCreate(
    ListingCreate event,
    Emitter<ListingState> emit,
  ) async {
    try {
      emit(const ListingLoading());
      await _repository.createListing(event.listingData);
      add(const ListingLoadAll());
    } on Exception catch (e) {
      emit(ListingError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    ListingUpdate event,
    Emitter<ListingState> emit,
  ) async {
    try {
      await _repository.updateListing(event.listingId, event.updates);
      add(const ListingLoadAll());
    } on Exception catch (e) {
      emit(ListingError(e.toString()));
    }
  }

  Future<void> _onDelete(
    ListingDelete event,
    Emitter<ListingState> emit,
  ) async {
    try {
      await _repository.deleteListing(event.listingId);
      add(const ListingLoadAll());
    } on Exception catch (e) {
      emit(ListingError(e.toString()));
    }
  }
}
