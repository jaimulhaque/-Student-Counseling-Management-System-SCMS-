<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }

require_once 'db.php';

$data = json_decode(file_get_contents("php://input"), true);

$counselor_id = isset($data['counselor_id']) ? intval($data['counselor_id'])  : 0;
$day          = isset($data['day'])          ? trim($data['day'])             : '';
$start_time   = isset($data['start_time'])   ? trim($data['start_time'])      : '';
$end_time     = isset($data['end_time'])     ? trim($data['end_time'])        : '';
$room_number  = isset($data['room_number'])  ? trim($data['room_number'])     : '';

if ($counselor_id <= 0 || empty($day) || empty($start_time) || empty($end_time)) {
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'All fields are required']);
    exit;
}

$valid_days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
if (!in_array($day, $valid_days)) {
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'Invalid day']);
    exit;
}

if ($start_time >= $end_time) {
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'End time must be after start time']);
    exit;
}

// Check overlap
$check = $conn->prepare(
    "SELECT id FROM counselor_schedule_slots
     WHERE counselor_id = ? AND day = ?
       AND NOT (end_time <= ? OR start_time >= ?)
     LIMIT 1"
);
$check->bind_param("isss", $counselor_id, $day, $start_time, $end_time);
$check->execute();
$check->store_result();
if ($check->num_rows > 0) {
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'This slot overlaps with an existing slot on ' . $day]);
    exit;
}
$check->close();

// Check if room_number column exists
$cols = $conn->query("SHOW COLUMNS FROM counselor_schedule_slots LIKE 'room_number'");
$hasRoomNumber = ($cols && $cols->num_rows > 0);

if ($hasRoomNumber) {
    $stmt = $conn->prepare(
        "INSERT INTO counselor_schedule_slots (counselor_id, day, start_time, end_time, room_number) VALUES (?, ?, ?, ?, ?)"
    );
    $stmt->bind_param("issss", $counselor_id, $day, $start_time, $end_time, $room_number);
} else {
    $stmt = $conn->prepare(
        "INSERT INTO counselor_schedule_slots (counselor_id, day, start_time, end_time) VALUES (?, ?, ?, ?)"
    );
    $stmt->bind_param("isss", $counselor_id, $day, $start_time, $end_time);
}

if ($stmt->execute()) {
    ob_end_clean();
    echo json_encode(['success' => true, 'message' => 'Slot added successfully', 'slot_id' => $conn->insert_id]);
} else {
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $stmt->error]);
}
$conn->close();
?>
