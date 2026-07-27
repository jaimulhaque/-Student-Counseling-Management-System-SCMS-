<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { ob_end_clean(); http_response_code(405); echo json_encode(["success"=>false,"message"=>"Method not allowed"]); exit; }

require_once 'db.php';

$data           = json_decode(file_get_contents("php://input"), true) ?? [];
$appointment_id = (int)($data['appointment_id'] ?? 0);
$counselor_id   = (int)($data['counselor_id']   ?? 0);
$reason         = trim($data['reason']           ?? '');

if ($appointment_id <= 0 || $counselor_id <= 0) {
    ob_end_clean();
    echo json_encode(["success" => false, "message" => "Invalid appointment or counselor ID"]);
    exit;
}
if (empty($reason)) {
    ob_end_clean();
    echo json_encode(["success" => false, "message" => "Rejection reason is required"]);
    exit;
}

$conn->begin_transaction();

try {
    // 1. Fetch the appointment to validate + get slot/student info
    $fetch = $conn->prepare(
        "SELECT a.id, a.slot_id, a.student_id, a.date, a.counselor_id
         FROM appointments a
         WHERE a.id = ? AND a.counselor_id = ? AND a.status = 'booked'
         LIMIT 1"
    );
    $fetch->bind_param("ii", $appointment_id, $counselor_id);
    $fetch->execute();
    $appt = $fetch->get_result()->fetch_assoc();
    $fetch->close();

    if (!$appt) {
        $conn->rollback();
        ob_end_clean();
        echo json_encode(["success" => false, "message" => "Appointment not found or already processed"]);
        exit;
    }

    $slot_id    = (int)$appt['slot_id'];
    $student_id = (int)$appt['student_id'];
    $appt_date  = $appt['date'];

    // 2. Delete the appointment row (avoids UNIQUE KEY conflict on re-booking)
    $delAppt = $conn->prepare("UPDATE appointments SET status = 'cancelled' WHERE id = ?");
    $delAppt->bind_param("i", $appointment_id);
    $delAppt->execute();
    $delAppt->close();

    // 3. Update the linked counseling_request: mark rejected + save reason
    // Match by slot_id + student_id + counselor_id (reliable — appointment_time may be 0000-00-00)
    $updReq = $conn->prepare(
        "UPDATE counseling_requests
         SET status = 'rejected', rejection_reason = ?
         WHERE slot_id = ? AND student_id = ? AND counselor_id = ?
           AND status IN ('pending','approved')
         LIMIT 1"
    );
    $updReq->bind_param("siii", $reason, $slot_id, $student_id, $counselor_id);
    $updReq->execute();
    $updReq->close();

    // 4. Slot intentionally NOT freed — this was an approved appointment.
    //    Keeping status='cancelled' in appointments table blocks re-booking
    //    of this specific slot+date combination by any other student.

    // 5. Create a notification for the student
    $title   = "Appointment Rejected";
    $message = "Your appointment on $appt_date has been rejected by your counselor. Reason: $reason";
    $type    = "cancellation";

    $notif = $conn->prepare(
        "INSERT INTO notifications (user_id, sender_id, title, message, type, is_read)
         VALUES (?, ?, ?, ?, ?, 0)"
    );
    $notif->bind_param("iisss", $student_id, $counselor_id, $title, $message, $type);
    $notif->execute();
    $notif->close();

    $conn->commit();
    ob_end_clean();
    echo json_encode([
        "success" => true,
        "message" => "Appointment rejected, student notified"
    ]);

} catch (Exception $e) {
    $conn->rollback();
    ob_end_clean();
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}

$conn->close();
?>