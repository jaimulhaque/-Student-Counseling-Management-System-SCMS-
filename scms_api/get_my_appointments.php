<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }

require_once 'db.php';

$student_id = (int)($_GET['student_id'] ?? 0);

if ($student_id <= 0) {
    ob_end_clean();
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "student_id is required"]);
    exit;
}

// Auto-mark past booked appointments as completed
$conn->query("
    UPDATE appointments
    SET status = 'completed'
    WHERE student_id = $student_id
      AND status = 'booked'
      AND date < CURDATE()
");

// Fetch all appointments (upcoming booked + completed)
$stmt = $conn->prepare("
    SELECT
        a.id            AS appointment_id,
        a.date,
        a.status        AS appointment_status,
        a.created_at,
        s.day,
        TIME_FORMAT(s.start_time, '%H:%i') AS start_time,
        TIME_FORMAT(s.end_time,   '%H:%i') AS end_time,
        IFNULL(s.room_number, '')          AS room_number,
        uc.id           AS counselor_id,
        uc.name         AS counselor_name,
        uc.email        AS counselor_email,
        uc.phone        AS counselor_phone,
        uc.department   AS counselor_department,
        uc.designation  AS counselor_designation,
        IFNULL(c.name, 'General')          AS category,
        IFNULL(r.description, '')          AS description
    FROM appointments a
    JOIN counselor_schedule_slots s  ON a.slot_id      = s.id
    JOIN users uc                    ON a.counselor_id  = uc.id
    LEFT JOIN counseling_requests r
        ON  r.slot_id      = a.slot_id
        AND r.student_id   = a.student_id
        AND r.counselor_id = a.counselor_id
        AND r.id = (
            SELECT MIN(r2.id) FROM counseling_requests r2
            WHERE r2.slot_id      = a.slot_id
              AND r2.student_id   = a.student_id
              AND r2.counselor_id = a.counselor_id
        )
    LEFT JOIN counseling_categories c ON r.category_id = c.id
    WHERE a.student_id = ?
      AND a.status IN ('booked', 'completed')
    ORDER BY a.date ASC, s.start_time ASC
");
$stmt->bind_param("i", $student_id);
$stmt->execute();
$result = $stmt->get_result();

$upcoming  = [];
$completed = [];
$today     = date('Y-m-d');

while ($row = $result->fetch_assoc()) {
    if ($row['appointment_status'] === 'completed' || $row['date'] < $today) {
        $row['display_status'] = 'completed';
        $completed[] = $row;
    } else {
        $row['display_status'] = 'upcoming';
        $upcoming[] = $row;
    }
}

ob_end_clean();
echo json_encode([
    "success"   => true,
    "upcoming"  => $upcoming,
    "completed" => $completed,
]);
$conn->close();
?>