# Student Attendance Management System

Web app for teachers to record daily attendance and generate student-wise reports.

**Stack:** Node.js + Express, PostgreSQL, Docker. Exposes `/health` and `/metrics` (Prometheus).

## Run locally
```bash
cp .env.example .env        # then edit the passwords and JWT_SECRET
docker compose up --build
```
Open http://localhost:3000 and log in with `ADMIN_EMAIL` / `ADMIN_PASSWORD` from your `.env`.

## Run unit tests
```bash
cd app && npm install && npm test
```

## Main API endpoints (JWT required except login)
| Method | Path | Purpose |
|---|---|---|
| POST | /api/auth/login | Get a token |
| GET/POST/PUT/DELETE | /api/students | Student list management |
| GET/POST | /api/subjects | Subjects |
| GET/POST | /api/attendance | Load / save attendance for a subject and date |
| GET | /api/reports/students | Percentages per student (filters: subject_id, from, to) |
| GET | /api/reports/low-attendance | Only students below the threshold |
| GET | /api/reports/export.csv | CSV export |
| GET | /health, /metrics | Health check and Prometheus metrics |
