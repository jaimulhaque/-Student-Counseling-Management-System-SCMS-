

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { ob_end_clean(); http_response_code(405); echo json_encode(["success"=>false,"message"=>"Method not allowed"]); exit; }

require_once 'db.php';

$data       = json_decode(file_get_contents("php://input"), true) ?? [];
$name       = trim($data['name']       ?? '');
$email      = trim($data['email']      ?? '');
$password   = $data['password']        ?? '';
$role       = trim($data['role']       ?? 'student');
$student_id = trim($data['student_id'] ?? '');
$department = trim($data['department'] ?? '');
$intake     = trim($data['intake']     ?? '');
$section    = trim($data['section']    ?? '');
$phone      = trim($data['phone']      ?? '');

if (empty($name) || empty($email) || empty($password)) {
    ob_end_clean();
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Name, email, and password are required"]);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    ob_end_clean();
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Invalid email format"]);
    exit;
}

if (!in_array($role, ['student', 'counselor', 'admin'])) {
    ob_end_clean();
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Invalid role"]);
    exit;
}

// Check duplicate email
$check = $conn->prepare("SELECT id FROM users WHERE email = ?");
$check->bind_param("s", $email);
$check->execute();
$check->store_result();
if ($check->num_rows > 0) {
    ob_end_clean();
    http_response_code(409);
    echo json_encode(["success" => false, "message" => "Email already registered"]);
    exit;
}

$hashed = password_hash($password, PASSWORD_DEFAULT);

$stmt = $conn->prepare("INSERT INTO users (name, email, password, role, phone, student_id, department, intake, section) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
$stmt->bind_param("sssssssss", $name, $email, $hashed, $role, $phone, $student_id, $department, $intake, $section);

if ($stmt->execute()) {
    ob_end_clean();
    http_response_code(201);
    echo json_encode(["success" => true, "message" => "Registered successfully. Please login."]);
} else {
    ob_end_clean();
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Registration failed: " . $stmt->error]);
}
$conn->close();
?>
