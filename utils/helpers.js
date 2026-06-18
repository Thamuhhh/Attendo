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
  const id = req.institution._id.toString();
  const base = { institutionId: id };
  if (Object.keys(extra).length === 0) return base;
  return { $and: [base, extra] };
}

module.exports = { todayStr, getMonthRange, instFilter };
