// Pure function: easy to unit test. "late" counts as attended.
const LOW_THRESHOLD = Number(process.env.LOW_ATTENDANCE_THRESHOLD || 75);

function calculatePercentage({ present = 0, late = 0, absent = 0 }, threshold = LOW_THRESHOLD) {
  const total = present + late + absent;
  const attended = present + late;
  if (total === 0) return { total, attended, percentage: null, low: false };
  const percentage = Math.round((attended / total) * 10000) / 100; // 2 decimals
  return { total, attended, percentage, low: percentage < threshold };
}

module.exports = { calculatePercentage, LOW_THRESHOLD };
