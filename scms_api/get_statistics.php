<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }

require_once 'db.php';

$counselor_id = isset($_GET['counselor_id']) ? intval($_GET['counselor_id']) : 0;

if ($counselor_id <= 0) {
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'counselor_id required']);
    exit;
}

// ── 1. Overall request counts ──────────────────────────────────
$row = $conn->query("
    SELECT
        COUNT(*)                                          AS total_requests,
        SUM(status = 'pending')                           AS pending,
        SUM(status = 'approved')                          AS approved,
        SUM(status = 'rejected')                          AS rejected
    FROM counseling_requests
    WHERE counselor_id = $counselor_id
")->fetch_assoc();

$total_requests = (int)($row['total_requests'] ?? 0);
$pending        = (int)($row['pending']        ?? 0);
$approved       = (int)($row['approved']       ?? 0);
$rejected       = (int)($row['rejected']       ?? 0);

// ── 2. Completed sessions (approved appointments whose date+time has passed) ──
$completedRow = $conn->query("
    SELECT COUNT(*) AS cnt
    FROM appointments a
    JOIN counseling_requests r
        ON r.slot_id      = a.slot_id
        AND r.student_id   = a.student_id
        AND r.counselor_id = a.counselor_id
        AND r.status       = 'approved'
    JOIN counselor_schedule_slots s ON a.slot_id = s.id
    WHERE a.counselor_id = $counselor_id
      AND a.status       = 'booked'
      AND CONCAT(a.date, ' ', s.end_time) < NOW()
")->fetch_assoc();
$completed = (int)($completedRow['cnt'] ?? 0);

// ── 3. Today's appointments ────────────────────────────────────
$todayRow = $conn->query("
    SELECT COUNT(*) AS cnt
    FROM appointments a
    JOIN counseling_requests r
        ON r.slot_id      = a.slot_id
        AND r.student_id   = a.student_id
        AND r.counselor_id = a.counselor_id
        AND r.status       = 'approved'
    WHERE a.counselor_id = $counselor_id
      AND a.status       = 'booked'
      AND a.date         = CURDATE()
")->fetch_assoc();
$today = (int)($todayRow['cnt'] ?? 0);

// ── 4. This week's appointments (Mon–Sun) ──────────────────────
$weekRow = $conn->query("
    SELECT COUNT(*) AS cnt
    FROM appointments a
    JOIN counseling_requests r
        ON r.slot_id      = a.slot_id
        AND r.student_id   = a.student_id
        AND r.counselor_id = a.counselor_id
        AND r.status       = 'approved'
    WHERE a.counselor_id = $counselor_id
      AND a.status       = 'booked'
      AND YEARWEEK(a.date, 1) = YEARWEEK(CURDATE(), 1)
")->fetch_assoc();
$this_week = (int)($weekRow['cnt'] ?? 0);

// ── 5. Category-wise breakdown ────────────────────────────────
$catResult = $conn->query("
    SELECT c.name AS category, COUNT(*) AS cnt
    FROM counseling_requests r
    JOIN counseling_categories c ON r.category_id = c.id
    WHERE r.counselor_id = $counselor_id
    GROUP BY c.id, c.name
    ORDER BY cnt DESC
");
$categories = [];
while ($c = $catResult->fetch_assoc()) {
    $categories[] = ['name' => $c['category'], 'count' => (int)$c['cnt']];
}

// ── 6. Daily counts for this week (Mon=0 … Sun=6) ─────────────
$dailyResult = $conn->query("
    SELECT DAYOFWEEK(a.date) AS dow, COUNT(*) AS cnt
    FROM appointments a
    JOIN counseling_requests r
        ON r.slot_id      = a.slot_id
        AND r.student_id   = a.student_id
        AND r.counselor_id = a.counselor_id
        AND r.status       = 'approved'
    WHERE a.counselor_id = $counselor_id
      AND a.status       = 'booked'
      AND YEARWEEK(a.date, 1) = YEARWEEK(CURDATE(), 1)
    GROUP BY DAYOFWEEK(a.date)
");
// DAYOFWEEK: 1=Sun,2=Mon,...,7=Sat  →  map to index 0=Mon…6=Sun
$daily = [0, 0, 0, 0, 0, 0, 0];
while ($d = $dailyResult->fetch_assoc()) {
    $idx = ((int)$d['dow'] + 5) % 7; // convert to Mon=0…Sun=6
    $daily[$idx] = (int)$d['cnt'];
}

// ── 7. Most booked time slots ─────────────────────────────────
$slotResult = $conn->query("
    SELECT TIME_FORMAT(s.start_time,'%H:%i') AS start_time,
           TIME_FORMAT(s.end_time,  '%H:%i') AS end_time,
           COUNT(*) AS cnt
    FROM appointments a
    JOIN counselor_schedule_slots s ON a.slot_id = s.id
    WHERE a.counselor_id = $counselor_id
      AND a.status       = 'booked'
    GROUP BY a.slot_id
    ORDER BY cnt DESC
    LIMIT 5
");
$top_slots = [];
while ($s = $slotResult->fetch_assoc()) {
    $top_slots[] = [
        'time'  => $s['start_time'] . ' – ' . $s['end_time'],
        'count' => (int)$s['cnt'],
    ];
}

// ── 8. Most active students ───────────────────────────────────
$studentResult = $conn->query("
    SELECT u.name, COUNT(*) AS cnt
    FROM appointments a
    JOIN users u ON a.student_id = u.id
    WHERE a.counselor_id = $counselor_id
      AND a.status       = 'booked'
    GROUP BY a.student_id
    ORDER BY cnt DESC
    LIMIT 5
");
$top_students = [];
while ($s = $studentResult->fetch_assoc()) {
    $top_students[] = ['name' => $s['name'], 'count' => (int)$s['cnt']];
}

// ── 9. Recent approved appointments ──────────────────────────
$recentResult = $conn->query("
    SELECT u.name AS student_name,
           c.name AS category,
           a.date,
           TIME_FORMAT(s.start_time,'%H:%i') AS start_time
    FROM appointments a
    JOIN users u ON a.student_id = u.id
    JOIN counselor_schedule_slots s ON a.slot_id = s.id
    JOIN counseling_requests r
        ON r.slot_id      = a.slot_id
        AND r.student_id   = a.student_id
        AND r.counselor_id = a.counselor_id
        AND r.status       = 'approved'
    LEFT JOIN counseling_categories c ON r.category_id = c.id
    WHERE a.counselor_id = $counselor_id
      AND a.status       = 'booked'
    ORDER BY a.date DESC
    LIMIT 5
");
$recent = [];
while ($r = $recentResult->fetch_assoc()) {
    $recent[] = $r;
}

ob_end_clean();
echo json_encode([
    'success'        => true,
    'total_requests' => $total_requests,
    'pending'        => $pending,
    'approved'       => $approved,
    'rejected'       => $rejected,
    'completed'      => $completed,
    'today'          => $today,
    'this_week'      => $this_week,
    'categories'     => $categories,
    'daily_this_week'=> $daily,
    'top_slots'      => $top_slots,
    'top_students'   => $top_students,
    'recent'         => $recent,
]);

$conn->close();
?>
