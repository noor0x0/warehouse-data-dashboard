<?php
// تحديد نوع الرد ليكون JSON يدعم اللغة العربية
header('Content-Type: application/json; charset=utf-8');

$host = "localhost";
$dbname = "dw_project"; // تم التعديل هنا ليطابق الاسم في phpMyAdmin لديكِ; // اسم قاعدة البيانات المعتمدة بالسكيما
$username = "root";
$password = "";   // كلمة مرور MySQL الخاصة بكِ

// إنشاء الاتصال
$conn = new mysqli($host, $username, $password, $dbname);

// التحقق من الاتصال
if ($conn->connect_error) {
    die(json_encode([
        "status" => "error",
        "message" => "Connection failed: " . $conn->connect_error
    ]));
}

$conn->set_charset("utf8mb4");

// استقبال نوع البيانات المطلوب من الـ Dashboard
$queryType = isset($_GET['query']) ? $_GET['query'] : '';
$response = ["status" => "ok", "data" => []];

switch ($queryType) {
    case 'overview':
        // 1. الإحصائيات العامة للكروت الأربعة في الأعلى
        $sql = "SELECT 
                    (SELECT COUNT(*) FROM fact_visits) as total_visits,
                    (SELECT COUNT(DISTINCT user_id) FROM fact_visits) as total_users,
                    (SELECT COUNT(DISTINCT website_id) FROM fact_visits) as total_websites,
                    (SELECT COUNT(DISTINCT date_id) FROM fact_visits) as active_days";
        break;

    case 'top_sites':
        // 2. أكثر المواقع زيارة (متوافق مع رسم الـ Bar Chart والـ Dashboard)
        $sql = "SELECT
                    w.website_name,
                    COUNT(*) AS visits
                FROM fact_visits f
                JOIN dim_website w ON f.website_id = w.website_id
                GROUP BY w.website_id, w.website_name
                ORDER BY visits DESC
                LIMIT 5";
        break;

    case 'users':
        // 3. عدد الزيارات لكل مستخدم (متوافق مع رسم الـ Doughnut Chart)
        $sql = "SELECT
                    u.user_name,
                    COUNT(*) AS visits
                FROM fact_visits f
                JOIN dim_user u ON f.user_id = u.user_id
                GROUP BY u.user_id, u.user_name
                ORDER BY visits DESC";
        break;

    case 'monthly':
        // 4. منحنى الزيارات الشهري (متوافق مع رسم الـ Line Chart)
        $sql = "SELECT
                    d.month,
                    COUNT(*) AS visits
                FROM fact_visits f
                JOIN dim_date d ON f.date_id = d.date_id
                GROUP BY d.month, d.month_num
                ORDER BY d.month_num ASC";
        break;

    default:
        die(json_encode(["status" => "error", "message" => "Invalid query type"]));
}

// تنفيذ الاستعلام وجلب البيانات
$result = $conn->query($sql);

if ($result) {
    while($row = $result->fetch_assoc()) {
        $response['data'][] = $row;
    }
} else {
    $response['status'] = "error";
    $response['message'] = $conn->error;
}

// طباعة النتيجة النهائية للمتصفح
echo json_encode($response);
$conn->close();
?>