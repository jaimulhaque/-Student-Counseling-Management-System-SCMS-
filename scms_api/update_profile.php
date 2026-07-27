<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }

require_once 'db.php';

$data        = json_decode(file_get_contents('php://input'), true) ?? [];
$user_id     = (int)($data['user_id']     ?? 0);
$name        = trim($data['name']        ?? '');
$email       = trim($data['email']       ?? '');
$phone       = trim($data['phone']       ?? '');
$department  = trim($data['department']  ?? '');
$intake      = trim($data['intake']      ?? '');
$section     = trim($data['section']     ?? '');
$student_id  = trim($data['student_id']  ?? '');
$designation = trim($data['designation'] ?? '');

if ($user_id <= 0) {
    ob_end_clean();
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid user ID']);
    exit;
}

// Validate email format if provided
if (!empty($email) && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'Invalid email address format']);
    exit;
}

// Check email uniqueness — only if email is being changed
if (!empty($email)) {
    $emailCheck = $conn->prepare("SELECT id FROM users WHERE email = ? AND id != ?");
    $emailCheck->bind_param("si", $email, $user_id);
    $emailCheck->execute();
    $emailCheck->store_result();
    if ($emailCheck->num_rows > 0) {
        ob_end_clean();
        echo json_encode(['success' => false, 'message' => 'This email is already used by another account']);
        exit;
    }
    $emailCheck->close();
}

// Build update — always update name; only update email if provided
if (!empty($email)) {
    $stmt = $conn->prepare("
        UPDATE users
        SET name = ?, email = ?, phone = ?, department = ?, intake = ?, section = ?, student_id = ?, designation = ?
        WHERE id = ?
    ");
    $stmt->bind_param("ssssssssi", $name, $email, $phone, $department, $intake, $section, $student_id, $designation, $user_id);
} else {
    // Email not provided — don't overwrite it
    $stmt = $conn->prepare("
        UPDATE users
        SET name = ?, phone = ?, department = ?, intake = ?, section = ?, student_id = ?, designation = ?
        WHERE id = ?
    ");
    $stmt->bind_param("sssssssi", $name, $phone, $department, $intake, $section, $student_id, $designation, $user_id);
}

if ($stmt->execute()) {
    // Return updated user profile
    $fetch = $conn->prepare("SELECT id, name, email, phone, role, department, student_id, intake, section, designation FROM users WHERE id = ?");
    $fetch->bind_param("i", $user_id);
    $fetch->execute();
    $updated = $fetch->get_result()->fetch_assoc();
    ob_end_clean();
    echo json_encode(['success' => true, 'message' => 'Profile updated successfully', 'user' => $updated]);
} else {
    ob_end_clean();
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Update failed: ' . $stmt->error]);
}
$conn->close();
?>