<?php
$host = "localhost";
$dbname = "browsing_dw"; // اسم قاعدة البيانات المعتمدة بالسكيما
$username = "root";
$password = "";   // جربي تغييرها لـ "12345678" بسرعة بدلاً من "root"

$conn = new mysqli($host, $username, $password, $dbname);

if ($conn->connect_error) {
    die(json_encode([
        "status" => "error",
        "message" => $conn->connect_error
    ]));
}

$conn->set_charset("utf8mb4");
?>