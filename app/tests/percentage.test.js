const test = require('node:test');
const assert = require('node:assert');
const { calculatePercentage } = require('../src/percentage');

test('all present gives 100%', () => {
  const r = calculatePercentage({ present: 20 });
  assert.strictEqual(r.percentage, 100);
  assert.strictEqual(r.low, false);
});

test('late counts as attended', () => {
  const r = calculatePercentage({ present: 8, late: 2, absent: 0 });
  assert.strictEqual(r.attended, 10);
  assert.strictEqual(r.percentage, 100);
});

test('rounds to two decimals', () => {
  const r = calculatePercentage({ present: 2, absent: 1 });
  assert.strictEqual(r.percentage, 66.67);
});

test('below 75% is flagged low', () => {
  const r = calculatePercentage({ present: 7, absent: 3 });
  assert.strictEqual(r.percentage, 70);
  assert.strictEqual(r.low, true);
});

test('exactly 75% is not low', () => {
  const r = calculatePercentage({ present: 3, absent: 1 });
  assert.strictEqual(r.percentage, 75);
  assert.strictEqual(r.low, false);
});

test('no records returns null percentage and not low', () => {
  const r = calculatePercentage({});
  assert.strictEqual(r.total, 0);
  assert.strictEqual(r.percentage, null);
  assert.strictEqual(r.low, false);
});

test('custom threshold is respected', () => {
  const r = calculatePercentage({ present: 8, absent: 2 }, 85);
  assert.strictEqual(r.low, true);
});
