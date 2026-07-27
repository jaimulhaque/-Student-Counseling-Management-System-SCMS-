<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }

require_once 'db.php';

$result = $conn->query("SELECT id, name FROM counseling_categories ORDER BY id");
$categories = [];
while ($row = $result->fetch_assoc()) {
    $categories[] = $row;
}

ob_end_clean();
echo json_encode(["success" => true, "categories" => $categories]);
$conn->close();
?>
