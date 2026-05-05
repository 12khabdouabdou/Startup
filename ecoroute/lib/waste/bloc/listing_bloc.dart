import 'package:flutter_bloc/flutter_bloc.dart';
import 'listing_bloc.dart';
import 'listing_event.dart';
import 'listing_state.dart';

class ListingBloc extends Bloc<ListingEvent, ListingState> {
  ListingBloc() : super(const ListingInitial()) {
    on<ListingLoadAll>(_onLoadAll);
    on<ListingLoadById>(_onLoadById);
    on<ListingCreate>(_onCreate);
    on<ListingUpdate>(_onUpdate);
    on<ListingDelete>(_onDelete);
  }

  Future<void> _onLoadAll(ListingLoadAll event, Emitter<ListingState> emit) async {
    try {
      emit(const ListingLoading());
      // TODO: Implement actual Supabase fetch
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data for testing
      emit(const ListingLoaded([]));
    } catch (e) {
      emit(ListingError(e.toString()));
    }
  }

  Future<void> _onLoadById(ListingLoadById event, Emitter<ListingState> emit) async {
    try {
      emit(const ListingLoading());
      // TODO: Implement fetch by ID
      await Future.delayed(const Duration(milliseconds: 500));
      emit(const ListingError('Not implemented yet'));
    } catch (e) {
      emit(ListingError(e.toString()));
    }
  }

  Future<void> _onCreate(ListingCreate event, Emitter<ListingState> emit) async {
    try {
      emit(const ListingLoading());
      // TODO: Implement create in Supabase
      await Future.delayed(const Duration(seconds: 1));
      emit(const ListingLoaded([]));
    } catch (e) {
      emit(ListingError(e.toString()));
    }
  }

  Future<void> _onUpdate(ListingUpdate event, Emitter<ListingState> emit) async {
    try {
      // TODO: Implement update
      await Future.delayed(const Duration(milliseconds: 500));
      add(const ListingLoadAll());
    } catch (e) {
      emit(ListingError(e.toString()));
    }
  }

  Future<void> _onDelete(ListingDelete event, Emitter<ListingState> emit) async {
    try {
      // TODO: Implement delete
      await Future.delayed(const Duration(milliseconds: 500));
      add(const ListingLoadAll());
    } catch (e) {
      emit(ListingError(e.toString()));
    }
  }
}
