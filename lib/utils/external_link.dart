/// Appends `?user=` to external notification links when needed.
Uri appendUserQuery(String url, String userToken) {
  final base = Uri.parse(url);
  final params = Map<String, String>.from(base.queryParameters);
  params['user'] = userToken;
  return base.replace(queryParameters: params);
}
