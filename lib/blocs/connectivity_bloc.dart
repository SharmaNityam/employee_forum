import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectivityEvent {}

class ConnectivityStatusChanged extends ConnectivityEvent {
  final List<ConnectivityResult> connectivityResults;
  ConnectivityStatusChanged(this.connectivityResults);
}

abstract class ConnectivityState {}

class ConnectivityInitial extends ConnectivityState {}
class ConnectivityConnected extends ConnectivityState {}
class ConnectivityDisconnected extends ConnectivityState {}

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final Connectivity connectivity;
  StreamSubscription? connectivitySubscription;

  ConnectivityBloc({required this.connectivity}) : super(ConnectivityInitial()) {
    on<ConnectivityStatusChanged>(_onConnectivityStatusChanged);

    connectivitySubscription = connectivity.onConnectivityChanged.listen((results) {
      add(ConnectivityStatusChanged(results));
    });
  }

  void _onConnectivityStatusChanged(
    ConnectivityStatusChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    final hasConnection = event.connectivityResults.any((result) => result != ConnectivityResult.none);
    
    if (hasConnection) {
      emit(ConnectivityConnected());
    } else {
      emit(ConnectivityDisconnected());
    }
  }

  @override
  Future<void> close() {
    connectivitySubscription?.cancel();
    return super.close();
  }
}