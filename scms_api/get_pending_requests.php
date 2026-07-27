<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }

require_once 'db.php';

$counselor_id = (int)($_GET['counselor_id'] ?? 0);

$sql = "
    SELECT
        r.id, r.description, r.priority, r.status, r.requested_at,
        r.appointment_time,
        u.name AS student_name,
        u.phone AS student_phone,
        u.department AS student_department,
        u.student_id AS student_number,
        u.intake AS student_intake,
        u.section AS student_section,
        c.name AS category
    FROM counseling_requests r
    JOIN users u ON r.student_id = u.id
    JOIN counseling_categories c ON r.category_id = c.id
    WHERE r.status = 'pending'
";

if ($counselor_id > 0) {
    $sql .= " AND (r.counselor_id = $counselor_id OR r.counselor_id IS NULL)";
}
$sql .= " ORDER BY r.priority DESC, r.requested_at ASC";

$result = $conn->query($sql);
$rows = [];
while ($row = $result->fetch_assoc()) {
    $rows[] = $row;
}

ob_end_clean();
echo json_encode(["success" => true, "requests" => $rows]);
$conn->close();
?>