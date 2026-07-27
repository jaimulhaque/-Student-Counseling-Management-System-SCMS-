<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { ob_end_clean(); http_response_code(405); echo json_encode(["success"=>false,"message"=>"Method not allowed"]); exit; }

require_once 'db.php';

$data        = json_decode(file_get_contents("php://input"), true) ?? [];
$student_id  = (int)($data['student_id']  ?? 0);
$category_id = (int)($data['category_id'] ?? 0);
$description = trim($data['description']  ?? '');
$priority    = ($data['priority'] ?? 'normal') === 'emergency' ? 'emergency' : 'normal';
$counselor_id = (int)($data['counselor_id'] ?? 0); // optional: pre-select a counselor from profile page

if ($student_id <= 0 || $category_id <= 0 || empty($description)) {
    ob_end_clean();
    echo json_encode(["success" => false, "message" => "Student ID, category, and description are required"]);
    exit;
}

// Verify student exists
$check = $conn->prepare("SELECT id FROM users WHERE id = ? AND role = 'student'");
$check->bind_param("i", $student_id);
$check->execute();
$check->store_result();
if ($check->num_rows === 0) {
    ob_end_clean();
    echo json_encode(["success" => false, "message" => "Student not found"]);
    exit;
}

// Check for duplicate pending request from same student with same category (avoid spam)
$dup = $conn->prepare("SELECT id FROM counseling_requests WHERE student_id = ? AND category_id = ? AND status = 'pending' LIMIT 1");
$dup->bind_param("ii", $student_id, $category_id);
$dup->execute();
$dup->store_result();
if ($dup->num_rows > 0) {
    ob_end_clean();
    echo json_encode(["success" => false, "message" => "You already have a pending request in this category. Please wait for it to be processed."]);
    exit;
}

// Insert - include counselor_id if provided
if ($counselor_id > 0) {
    $stmt = $conn->prepare("INSERT INTO counseling_requests (student_id, category_id, description, priority, counselor_id) VALUES (?, ?, ?, ?, ?)");
    $stmt->bind_param("iissi", $student_id, $category_id, $description, $priority, $counselor_id);
} else {
    $stmt = $conn->prepare("INSERT INTO counseling_requests (student_id, category_id, description, priority) VALUES (?, ?, ?, ?)");
    $stmt->bind_param("iiss", $student_id, $category_id, $description, $priority);
}

if ($stmt->execute()) {
    $new_id = $conn->insert_id;
    ob_end_clean();
    echo json_encode([
        "success"    => true,
        "message"    => "Request submitted successfully. You will be notified once approved.",
        "request_id" => $new_id
    ]);
} else {
    ob_end_clean();
    echo json_encode(["success" => false, "message" => "Failed to submit request: " . $stmt->error]);
}
$conn->close();
?>
