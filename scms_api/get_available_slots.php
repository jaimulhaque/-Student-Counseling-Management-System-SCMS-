<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }

require_once 'db.php';

$counselor_id = isset($_GET['counselor_id']) ? intval($_GET['counselor_id']) : 0;
$date         = isset($_GET['date'])         ? trim($_GET['date'])           : '';

if ($counselor_id <= 0 || empty($date)) {
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'counselor_id and date are required', 'available_slots' => []]);
    exit;
}

$dateObj = DateTime::createFromFormat('Y-m-d', $date);
if (!$dateObj) {
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'Invalid date format (use YYYY-MM-DD)', 'available_slots' => []]);
    exit;
}

if ($dateObj < new DateTime('today')) {
    ob_end_clean();
    echo json_encode(['success' => false, 'available_slots' => [], 'message' => 'Cannot book past dates']);
    exit;
}

$day_name = $dateObj->format('l'); // e.g. "Wednesday"

// Safe: check if room_number column exists
$cols = $conn->query("SHOW COLUMNS FROM counselor_schedule_slots LIKE 'room_number'");
$hasRoomNumber = ($cols && $cols->num_rows > 0);
$roomSelect = $hasRoomNumber ? "IFNULL(s.room_number, '') AS room_number" : "'' AS room_number";

$stmt = $conn->prepare(
    "SELECT s.id, s.day,
            TIME_FORMAT(s.start_time, '%H:%i') AS start_time,
            TIME_FORMAT(s.end_time,   '%H:%i') AS end_time,
            $roomSelect
     FROM counselor_schedule_slots s
     WHERE s.counselor_id = ?
       AND s.day = ?
       AND s.id NOT IN (
           SELECT slot_id FROM appointments
           WHERE counselor_id = ? AND date = ? AND status = 'booked'
       )
     ORDER BY s.start_time"
);
$stmt->bind_param("isis", $counselor_id, $day_name, $counselor_id, $date);
$stmt->execute();
$result = $stmt->get_result();

$available_slots = [];
while ($row = $result->fetch_assoc()) {
    $available_slots[] = $row;
}

ob_end_clean();
echo json_encode([
    'success'         => true,
    'date'            => $date,
    'day'             => $day_name,
    'available_slots' => $available_slots,
    'total_available' => count($available_slots)
]);
$conn->close();
?>
