<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }

require_once 'db.php';

$data         = json_decode(file_get_contents("php://input"), true);
$student_id   = isset($data['student_id'])   ? intval($data['student_id'])   : 0;
$counselor_id = isset($data['counselor_id']) ? intval($data['counselor_id']) : 0;
$slot_id      = isset($data['slot_id'])      ? intval($data['slot_id'])      : 0;
$date         = isset($data['date'])         ? trim($data['date'])           : '';
$category_id  = isset($data['category_id'])  ? intval($data['category_id'])  : 1;
$description  = isset($data['description'])  ? trim($data['description'])    : 'Appointment booking';
$priority     = 'normal'; // always normal, student does not choose priority

if ($student_id <= 0 || $counselor_id <= 0 || $slot_id <= 0 || empty($date)) {
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'All fields are required']);
    exit;
}

$dateObj = DateTime::createFromFormat('Y-m-d', $date);
if (!$dateObj || $dateObj < new DateTime('today')) {
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'Invalid or past date']);
    exit;
}

// Verify slot belongs to counselor and get room_number
$slotCheck = $conn->prepare(
    "SELECT id, day, room_number,
            TIME_FORMAT(start_time,'%H:%i') AS start_time,
            TIME_FORMAT(end_time,'%H:%i') AS end_time
     FROM counselor_schedule_slots WHERE id = ? AND counselor_id = ?"
);
$slotCheck->bind_param("ii", $slot_id, $counselor_id);
$slotCheck->execute();
$slotResult = $slotCheck->get_result()->fetch_assoc();
if (!$slotResult) {
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'Invalid slot for this counselor']);
    exit;
}

$dayName = $dateObj->format('l');
if ($dayName !== $slotResult['day']) {
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => "Slot is for {$slotResult['day']}s but selected date is a {$dayName}"]);
    exit;
}

// Student already booked same counselor same date?
$studentCheck = $conn->prepare(
    "SELECT id FROM appointments WHERE student_id = ? AND counselor_id = ? AND date = ? AND status = 'booked'"
);
$studentCheck->bind_param("iis", $student_id, $counselor_id, $date);
$studentCheck->execute();
$studentCheck->store_result();
if ($studentCheck->num_rows > 0) {
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'You already have an appointment with this counselor on this date']);
    exit;
}
$studentCheck->close();

// Slot already taken?
$conflict = $conn->prepare(
    "SELECT id FROM appointments WHERE slot_id = ? AND date = ? AND status = 'booked'"
);
$conflict->bind_param("is", $slot_id, $date);
$conflict->execute();
$conflict->store_result();
if ($conflict->num_rows > 0) {
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'This slot was just booked by another student. Please choose a different slot.']);
    exit;
}
$conflict->close();

// Build appointment datetime
$appointmentDateTime = $date . ' ' . $slotResult['start_time'] . ':00';

// === SINGLE TRANSACTION: save everything together ===
$conn->begin_transaction();

try {
    // Use advisory lock to prevent race condition where two students book
    // the same slot at the exact same millisecond (bypassing the booked check above)
    $lockName = "slot_lock_{$slot_id}_{$date}";
    $lockResult = $conn->query("SELECT GET_LOCK('" . $conn->real_escape_string($lockName) . "', 5)");
    $lockRow = $lockResult->fetch_row();
    if (!$lockRow || $lockRow[0] != 1) {
        $conn->rollback();
        ob_end_clean();
        echo json_encode(['success' => false, 'message' => 'Could not acquire booking lock. Please try again.']);
        exit;
    }

    // 1a. Re-check slot availability inside the lock (prevents race condition)
    $recheck = $conn->prepare(
        "SELECT id FROM appointments WHERE slot_id = ? AND date = ? AND status = 'booked' LIMIT 1"
    );
    $recheck->bind_param("is", $slot_id, $date);
    $recheck->execute();
    $recheck->store_result();
    if ($recheck->num_rows > 0) {
        $recheck->close();
        $conn->query("SELECT RELEASE_LOCK('" . $conn->real_escape_string($lockName) . "')");
        $conn->rollback();
        ob_end_clean();
        echo json_encode(['success' => false, 'message' => 'This slot was just booked by another student. Please choose a different slot.']);
        exit;
    }
    $recheck->close();

    // 1b. Remove any leftover cancelled/rejected rows for this slot+date
    //     The unique key (slot_id, date) blocks re-booking even after cancellation
    //     without this cleanup step.
    $cleanOld = $conn->prepare(
        "DELETE FROM appointments WHERE slot_id = ? AND date = ? AND status IN ('cancelled')"
    );
    $cleanOld->bind_param("is", $slot_id, $date);
    $cleanOld->execute();
    $cleanOld->close();

    // 1. Insert into appointments
    $stmt1 = $conn->prepare(
        "INSERT INTO appointments (student_id, counselor_id, slot_id, date, status) VALUES (?, ?, ?, ?, 'booked')"
    );
    $stmt1->bind_param("iiis", $student_id, $counselor_id, $slot_id, $date);
    $stmt1->execute();
    $appointmentId = $conn->insert_id;

    // 2. Insert into counseling_requests with slot_id saved so reject can match it later
    $stmt2 = $conn->prepare(
        "INSERT INTO counseling_requests
         (student_id, category_id, description, priority, counselor_id, slot_id, appointment_time, status)
         VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')"
    );
    $stmt2->bind_param("iisssis", $student_id, $category_id, $description, $priority, $counselor_id, $slot_id, $appointmentDateTime);
    $stmt2->execute();
    $requestId = $conn->insert_id;

    $conn->commit();

    // Release the advisory lock after successful commit
    $conn->query("SELECT RELEASE_LOCK('" . $conn->real_escape_string($lockName) . "')");

    ob_end_clean();
    echo json_encode([
        'success'        => true,
        'message'        => 'Appointment confirmed! Waiting for counselor approval.',
        'appointment_id' => $appointmentId,
        'request_id'     => $requestId,
        'date'           => $date,
        'day'            => $dayName,
        'start_time'     => $slotResult['start_time'],
        'end_time'       => $slotResult['end_time'],
        'room_number'    => $slotResult['room_number'] ?? '',
    ]);
} catch (Exception $e) {
    $conn->rollback();
    // Release lock on failure too (if it was acquired)
    if (isset($lockName)) {
        $conn->query("SELECT RELEASE_LOCK('" . $conn->real_escape_string($lockName) . "')");
    }
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'Booking failed: ' . $e->getMessage()]);
}

$conn->close();
?>