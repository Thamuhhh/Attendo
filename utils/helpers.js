function todayStr() {
  return new Date().toISOString().split('T')[0];
}

function getMonthRange(year, month) {
  const start = `${year}-${String(month).padStart(2, '0')}-01`;
  const endDate = new Date(year, month, 0);
  const end = `${year}-${String(month).padStart(2, '0')}-${String(endDate.getDate()).padStart(2, '0')}`;
  return { start, end };
}

function instFilter(req, extra = {}) {
  const id = req.institution._id;
  const base = { institutionId: id };
  if (Object.keys(extra).length === 0) return base;
  return { $and: [base, extra] };
}

function parsePagination(query, defaults = {}) {
  const page = Math.max(1, parseInt(query.page, 10) || defaults.page || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit, 10) || defaults.limit || 20));
  const skip = (page - 1) * limit;
  const sortBy = query.sortBy || defaults.sortBy || 'name';
  const order = sortBy.startsWith('-') ? -1 : 1;
  const sortField = sortBy.replace(/^-/, '');
  return { page, limit, skip, sort: { [sortField]: order } };
}

function paginatedResponse(data, total, page, limit) {
  return {
    data,
    pagination: {
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      hasNext: page * limit < total,
      hasPrev: page > 1,
    },
  };
}

module.exports = { todayStr, getMonthRange, instFilter, parsePagination, paginatedResponse };
