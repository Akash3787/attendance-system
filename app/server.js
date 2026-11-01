const express = require('express');
const path = require('path');
const { pool, init } = require('./src/db');
const { seedTeacher, login, requireAuth } = require('./src/auth');
const { client, metricsMiddleware } = require('./src/metrics');
const routes = require('./src/routes');

const app = express();
app.use(express.json());
app.use(metricsMiddleware);
app.use(express.static(path.join(__dirname, 'public')));

// Public endpoints
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok' });
  } catch {
    res.status(503).json({ status: 'db_unreachable' });
  }
});
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});
app.post('/api/auth/login', (req, res, next) => login(req, res).catch(next));

// Protected API
app.use('/api', requireAuth, routes);

// Central error handler
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 3000;
if (require.main === module) {
  init()
    .then(seedTeacher)
    .then(() => app.listen(PORT, () => console.log(`Listening on ${PORT}`)))
    .catch((e) => { console.error(e); process.exit(1); });
}

module.exports = app;
