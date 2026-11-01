const client = require('prom-client');

client.collectDefaultMetrics(); // CPU, memory, event loop of the Node process

const httpDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.01, 0.05, 0.1, 0.3, 0.5, 1, 2, 5],
});

const attendanceCounter = new client.Counter({
  name: 'attendance_records_total',
  help: 'Total attendance records saved',
});

function metricsMiddleware(req, res, next) {
  const end = httpDuration.startTimer();
  res.on('finish', () => {
    const route = req.route ? req.baseUrl + req.route.path : req.path.startsWith('/api') ? '/api/*' : req.path;
    end({ method: req.method, route, status: res.statusCode });
  });
  next();
}

module.exports = { client, metricsMiddleware, attendanceCounter };
