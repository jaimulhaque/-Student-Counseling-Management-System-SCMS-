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

// Check if room_number column exists in slots
$cols = $conn->query("SHOW COLUMNS FROM counselor_schedule_slots LIKE 'room_number'");
$hasRoomNumber = ($cols && $cols->num_rows > 0);
$roomSelect = $hasRoomNumber ? "IFNULL(rm.name, '') AS room_name" : "'' AS room_name";

$stmt = $conn->prepare("
    SELECT 
        r.id, r.description, r.priority, r.status, r.requested_at, r.appointment_time,
        r.rejection_reason,
        c.name AS category,
        u.name AS counselor_name,
        rm.name AS room_name
    FROM counseling_requests r
    JOIN counseling_categories c ON r.category_id = c.id
    LEFT JOIN users u ON r.counselor_id = u.id
    LEFT JOIN rooms rm ON r.room_id = rm.id
    WHERE r.student_id = ?
      AND r.status IN ('pending', 'rejected')
    ORDER BY r.requested_at DESC
");
$stmt->bind_param("i", $student_id);
$stmt->execute();
$result = $stmt->get_result();

$requests = [];
while ($row = $result->fetch_assoc()) {
    $requests[] = $row;
}

ob_end_clean();
echo json_encode(["success" => true, "requests" => $requests]);
$conn->close();
?>