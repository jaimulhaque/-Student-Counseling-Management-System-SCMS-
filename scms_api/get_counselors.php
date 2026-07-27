<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }

require_once 'db.php';

$department = trim($_GET['department'] ?? '');

// Valid departments — reject anything not in the list
$valid_depts = ['CSE','BBA','EEE','LLB','LLM','Textile','English','Economics','Civil'];

if (!empty($department)) {
    if (!in_array($department, $valid_depts)) {
        ob_end_clean();
        echo json_encode(['success' => false, 'message' => 'Invalid department', 'counselors' => []]);
        exit;
    }
    // Filter by department — student only sees counselors from their own dept
    $stmt = $conn->prepare("
        SELECT id, name, email, phone, department, designation, available_schedule
        FROM users
        WHERE role = 'counselor' AND department = ?
        ORDER BY name ASC
    ");
    $stmt->bind_param("s", $department);
} else {
    // No filter — return all (used by admin / counselor views)
    $stmt = $conn->prepare("
        SELECT id, name, email, phone, department, designation, available_schedule
        FROM users
        WHERE role = 'counselor'
        ORDER BY name ASC
    ");
}

$stmt->execute();
$result = $stmt->get_result();

$counselors = [];
while ($row = $result->fetch_assoc()) {
    $counselors[] = $row;
}

ob_end_clean();
echo json_encode(['success' => true, 'counselors' => $counselors]);
$conn->close();
?>