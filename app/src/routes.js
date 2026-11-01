const express = require('express');
const { pool } = require('./db');
const { calculatePercentage, LOW_THRESHOLD } = require('./percentage');
const { attendanceCounter } = require('./metrics');

const router = express.Router();
const VALID_STATUS = ['present', 'absent', 'late'];
const isDate = (s) => /^\d{4}-\d{2}-\d{2}$/.test(s || '');

// Wrap async handlers so errors reach the error middleware
const wrap = (fn) => (req, res, next) => fn(req, res, next).catch(next);

/* ---------- Students ---------- */
router.get('/students', wrap(async (req, res) => {
  const { rows } = await pool.query('SELECT * FROM students ORDER BY roll_no');
  res.json(rows);
}));

router.post('/students', wrap(async (req, res) => {
  const { roll_no, name, class_name = '' } = req.body || {};
  if (!roll_no || !name) return res.status(400).json({ error: 'roll_no and name required' });
  try {
    const { rows } = await pool.query(
      'INSERT INTO students (roll_no, name, class_name) VALUES ($1,$2,$3) RETURNING *',
      [roll_no.trim(), name.trim(), class_name.trim()]
    );
    res.status(201).json(rows[0]);
  } catch (e) {
    if (e.code === '23505') return res.status(409).json({ error: 'Roll number already exists' });
    throw e;
  }
}));

router.put('/students/:id', wrap(async (req, res) => {
  const { roll_no, name, class_name = '' } = req.body || {};
  if (!roll_no || !name) return res.status(400).json({ error: 'roll_no and name required' });
  const { rows } = await pool.query(
    'UPDATE students SET roll_no=$1, name=$2, class_name=$3 WHERE id=$4 RETURNING *',
    [roll_no.trim(), name.trim(), class_name.trim(), req.params.id]
  );
  if (!rows[0]) return res.status(404).json({ error: 'Student not found' });
  res.json(rows[0]);
}));

router.delete('/students/:id', wrap(async (req, res) => {
  const { rowCount } = await pool.query('DELETE FROM students WHERE id=$1', [req.params.id]);
  if (!rowCount) return res.status(404).json({ error: 'Student not found' });
  res.status(204).end();
}));

/* ---------- Subjects ---------- */
router.get('/subjects', wrap(async (req, res) => {
  const { rows } = await pool.query('SELECT * FROM subjects ORDER BY name');
  res.json(rows);
}));

router.post('/subjects', wrap(async (req, res) => {
  const { name } = req.body || {};
  if (!name) return res.status(400).json({ error: 'name required' });
  const { rows } = await pool.query(
    'INSERT INTO subjects (name, teacher_id) VALUES ($1,$2) RETURNING *',
    [name.trim(), req.teacher.id]
  );
  res.status(201).json(rows[0]);
}));

/* ---------- Attendance entry ---------- */
// All students with their status for one subject + date (null = not marked yet)
router.get('/attendance', wrap(async (req, res) => {
  const { subject_id, date } = req.query;
  if (!subject_id || !isDate(date)) return res.status(400).json({ error: 'subject_id and date (YYYY-MM-DD) required' });
  const { rows } = await pool.query(
    `SELECT s.id AS student_id, s.roll_no, s.name, s.class_name, a.status
       FROM students s
       LEFT JOIN attendance a ON a.student_id = s.id AND a.subject_id = $1 AND a.date = $2
      ORDER BY s.roll_no`,
    [subject_id, date]
  );
  res.json(rows);
}));

// Bulk save (insert or update) for one subject + date
router.post('/attendance', wrap(async (req, res) => {
  const { subject_id, date, records } = req.body || {};
  if (!subject_id || !isDate(date) || !Array.isArray(records) || records.length === 0) {
    return res.status(400).json({ error: 'subject_id, date and records[] required' });
  }
  if (records.some((r) => !r.student_id || !VALID_STATUS.includes(r.status))) {
    return res.status(400).json({ error: `status must be one of ${VALID_STATUS.join(', ')}` });
  }
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    for (const r of records) {
      await client.query(
        `INSERT INTO attendance (student_id, subject_id, date, status) VALUES ($1,$2,$3,$4)
         ON CONFLICT (student_id, subject_id, date) DO UPDATE SET status = EXCLUDED.status`,
        [r.student_id, subject_id, date, r.status]
      );
    }
    await client.query('COMMIT');
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
  attendanceCounter.inc(records.length);
  res.json({ saved: records.length });
}));

/* ---------- Reports ---------- */
async function buildReport({ subject_id, from, to }) {
  const { rows } = await pool.query(
    `SELECT s.id, s.roll_no, s.name, s.class_name,
            COUNT(*) FILTER (WHERE a.status = 'present') AS present,
            COUNT(*) FILTER (WHERE a.status = 'late')    AS late,
            COUNT(*) FILTER (WHERE a.status = 'absent')  AS absent
       FROM students s
       LEFT JOIN attendance a ON a.student_id = s.id
            AND ($1::int  IS NULL OR a.subject_id = $1)
            AND ($2::date IS NULL OR a.date >= $2)
            AND ($3::date IS NULL OR a.date <= $3)
      GROUP BY s.id
      ORDER BY s.roll_no`,
    [subject_id || null, from || null, to || null]
  );
  return rows.map((r) => {
    const counts = { present: Number(r.present), late: Number(r.late), absent: Number(r.absent) };
    return {
      id: r.id, roll_no: r.roll_no, name: r.name, class_name: r.class_name,
      ...counts, ...calculatePercentage(counts),
    };
  });
}

router.get('/reports/students', wrap(async (req, res) => {
  res.json({ threshold: LOW_THRESHOLD, students: await buildReport(req.query) });
}));

router.get('/reports/low-attendance', wrap(async (req, res) => {
  const report = await buildReport(req.query);
  res.json({ threshold: LOW_THRESHOLD, students: report.filter((s) => s.low) });
}));

router.get('/reports/export.csv', wrap(async (req, res) => {
  const report = await buildReport(req.query);
  const esc = (v) => `"${String(v ?? '').replace(/"/g, '""')}"`;
  const lines = ['Roll No,Name,Class,Present,Late,Absent,Total,Percentage,Low Attendance'];
  for (const s of report) {
    lines.push([s.roll_no, s.name, s.class_name, s.present, s.late, s.absent, s.total,
      s.percentage ?? 'N/A', s.low ? 'YES' : 'NO'].map(esc).join(','));
  }
  res.set('Content-Type', 'text/csv');
  res.set('Content-Disposition', 'attachment; filename="attendance-report.csv"');
  res.send(lines.join('\n'));
}));

module.exports = router;
