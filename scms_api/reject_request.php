<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { ob_end_clean(); http_response_code(405); echo json_encode(["success"=>false,"message"=>"Method not allowed"]); exit; }

require_once 'db.php';

$data       = json_decode(file_get_contents("php://input"), true) ?? [];
$request_id = (int)($data['request_id'] ?? 0);
$reason     = trim($data['reason'] ?? '');

if ($request_id <= 0) {
    ob_end_clean();
    echo json_encode(["success" => false, "message" => "Invalid request ID"]);
    exit;
}

$conn->begin_transaction();

try {
    // 1. Reject the counseling request
    $stmt = $conn->prepare("UPDATE counseling_requests SET status = 'rejected' WHERE id = ? AND status = 'pending'");
    $stmt->bind_param("i", $request_id);
    $stmt->execute();
    $affected = $stmt->affected_rows;
    $stmt->close();

    if ($affected <= 0) {
        $conn->rollback();
        ob_end_clean();
        echo json_encode(["success" => false, "message" => "Failed to reject (already processed)"]);
        exit;
    }

    // 2. Fetch request details to find linked appointment
    $fetch = $conn->prepare("SELECT student_id, counselor_id, appointment_time, slot_id FROM counseling_requests WHERE id = ?");
    $fetch->bind_param("i", $request_id);
    $fetch->execute();
    $reqRow = $fetch->get_result()->fetch_assoc();
    $fetch->close();

    if ($reqRow) {
        $studentId   = (int)$reqRow['student_id'];
        $counselorId = (int)$reqRow['counselor_id'];
        $apptTime    = $reqRow['appointment_time'];
        $slotId      = $reqRow['slot_id'] ? (int)$reqRow['slot_id'] : null;

        $apptSlotId = null;
        $apptId     = null;

        // Try matching by slot_id
        if ($slotId) {
            $aCheck = $conn->prepare(
                "SELECT id, slot_id FROM appointments
                 WHERE student_id = ? AND counselor_id = ? AND slot_id = ? AND status = 'booked' LIMIT 1"
            );
            $aCheck->bind_param("iii", $studentId, $counselorId, $slotId);
            $aCheck->execute();
            $aRow = $aCheck->get_result()->fetch_assoc();
            $aCheck->close();
            if ($aRow) { $apptId = (int)$aRow['id']; $apptSlotId = (int)$aRow['slot_id']; }
        }

        // Fallback: match by date from appointment_time
        if (!$apptId && $apptTime && $apptTime !== '0000-00-00 00:00:00') {
            $apptDate2 = date('Y-m-d', strtotime($apptTime));
            $aCheck2 = $conn->prepare(
                "SELECT id, slot_id FROM appointments
                 WHERE student_id = ? AND counselor_id = ? AND date = ? AND status = 'booked' LIMIT 1"
            );
            $aCheck2->bind_param("iis", $studentId, $counselorId, $apptDate2);
            $aCheck2->execute();
            $aRow2 = $aCheck2->get_result()->fetch_assoc();
            $aCheck2->close();
            if ($aRow2) { $apptId = (int)$aRow2['id']; $apptSlotId = (int)$aRow2['slot_id']; }
        }

        if ($apptId && $apptSlotId) {
            // DELETE the appointment row entirely so the UNIQUE KEY (slot_id, date)
            // does not block a future student from booking the same slot on the same date.
            $deleteAppt = $conn->prepare("DELETE FROM appointments WHERE id = ?");
            $deleteAppt->bind_param("i", $apptId);
            $deleteAppt->execute();
            $deleteAppt->close();

            // Also delete any associated session_notes for this appointment (cascade may handle it,
            // but be explicit for safety)
            $deleteNotes = $conn->prepare("DELETE FROM session_notes WHERE appointment_id = ?");
            $deleteNotes->bind_param("i", $apptId);
            $deleteNotes->execute();
            $deleteNotes->close();

            // Only free the slot if no other booked appointment still uses it
            $remaining = $conn->prepare(
                "SELECT COUNT(*) AS cnt FROM appointments WHERE slot_id = ? AND status = 'booked'"
            );
            $remaining->bind_param("i", $apptSlotId);
            $remaining->execute();
            $remRow = $remaining->get_result()->fetch_assoc();
            $remaining->close();

            if ((int)$remRow['cnt'] === 0) {
                $freeSlot = $conn->prepare("UPDATE counselor_schedule_slots SET is_booked = 0 WHERE id = ?");
                $freeSlot->bind_param("i", $apptSlotId);
                $freeSlot->execute();
                $freeSlot->close();
            }
        }
    }

    $conn->commit();
    ob_end_clean();
    echo json_encode(["success" => true, "message" => "Request rejected and time slot released"]);

} catch (Exception $e) {
    $conn->rollback();
    ob_end_clean();
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}

$conn->close();
?>