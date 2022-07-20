part of 'scan_bloc.dart';

@freezed
class ScanState with _$ScanState {
  const factory ScanState.initial() = _InitialState;
  const factory ScanState.loading(final String info) = _LoadingState;
  const factory ScanState.progressLoading(
    final String info, {
    required final int count,
    required final int total,
  }) = _ProgressLoadingState;
  const factory ScanState.success(final List<FileCached> files) = _SuccessState;
  const factory ScanState.error(final String error) = _ErrorState;
}
