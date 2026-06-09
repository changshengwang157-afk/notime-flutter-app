/// Appends `?user=` for Scratchify deep links (same behaviour as notification detail).
Uri appendUserQuery(String url, String userToken) {
  final base = Uri.parse(url);
  final params = Map<String, String>.from(base.queryParameters);
  params['user'] = userToken;
  return base.replace(queryParameters: params);
}
