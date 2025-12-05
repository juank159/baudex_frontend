class CustomerQueryModel {
  final int page;
  final int limit;
  final String? search;
  final String? status;
  final String? documentType;
  final String? city;
  final String? state;
  final String? sortBy;
  final String? sortOrder;

  const CustomerQueryModel({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.status,
    this.documentType,
    this.city,
    this.state,
    this.sortBy,
    this.sortOrder,
  });

  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> params = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search?.isNotEmpty == true) params['search'] = search!;
    if (status?.isNotEmpty == true) params['status'] = status!;
    if (documentType?.isNotEmpty == true) {
      params['documentType'] = documentType!;
    }
    if (city?.isNotEmpty == true) params['city'] = city!;
    if (state?.isNotEmpty == true) params['state'] = state!;
    if (sortBy?.isNotEmpty == true) params['sortBy'] = sortBy!;
    if (sortOrder?.isNotEmpty == true) params['sortOrder'] = sortOrder!;

    return params;
  }
}
