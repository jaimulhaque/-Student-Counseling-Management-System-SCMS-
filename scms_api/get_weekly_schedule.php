<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }

require_once 'db.php';

$counselor_id = (int)($_GET['counselor_id'] ?? 0);

if ($counselor_id <= 0) {
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'counselor_id required', 'appointments' => []]);
    exit;
}

$stmt = $conn->prepare("
    SELECT
        a.id            AS appointment_id,
        a.date,
        a.status        AS appointment_status,
        s.day,
        TIME_FORMAT(s.start_time, '%H:%i') AS start_time,
        TIME_FORMAT(s.end_time,   '%H:%i') AS end_time,
        IFNULL(s.room_number, '')          AS room_number,
        s.id                               AS slot_id,
        u.id            AS student_id,
        u.name          AS student_name,
        u.phone         AS student_phone,
        u.department    AS student_department,
        u.student_id    AS student_number,
        u.intake        AS student_intake,
        u.section       AS student_section,
        r.id            AS request_id,
        r.description,
        r.priority,
        r.status        AS request_status,
        r.rejection_reason,
        c.name          AS category
    FROM appointments a
    JOIN counselor_schedule_slots s ON a.slot_id = s.id
    JOIN users u ON a.student_id = u.id
    INNER JOIN counseling_requests r
        ON r.slot_id      = a.slot_id
        AND r.student_id   = a.student_id
        AND r.counselor_id = a.counselor_id
        AND r.id = (
            SELECT MIN(r2.id) FROM counseling_requests r2
            WHERE r2.slot_id      = a.slot_id
              AND r2.student_id   = a.student_id
              AND r2.counselor_id = a.counselor_id
              AND r2.status       = 'approved'
        )
    LEFT JOIN counseling_categories c ON r.category_id = c.id
    WHERE a.counselor_id = ?
      AND a.status       = 'booked'
      AND r.status       = 'approved'
      AND a.date         >= CURDATE()
    ORDER BY a.date ASC, s.start_time ASC
");
$stmt->bind_param("i", $counselor_id);
$stmt->execute();
$result = $stmt->get_result();

$appointments = [];
while ($row = $result->fetch_assoc()) {
    $appointments[] = $row;
}

ob_end_clean();
echo json_encode(['success' => true, 'appointments' => $appointments]);
$conn->close();
?>