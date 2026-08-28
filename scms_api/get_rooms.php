<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }

require_once 'db.php';

$status_filter = trim($_GET['status'] ?? ''); // optional: ?status=available

$sql = "SELECT id, name, capacity, status FROM rooms";
if (!empty($status_filter)) {
    $sf = $conn->real_escape_string($status_filter);
    $sql .= " WHERE status = '$sf'";
}
$sql .= " ORDER BY name";

$result = $conn->query($sql);
$rooms = [];
while ($row = $result->fetch_assoc()) {
    $rooms[] = $row;
}

ob_end_clean();
echo json_encode(["success" => true, "rooms" => $rooms]);
$conn->close();
?>


