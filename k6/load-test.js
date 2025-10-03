import http from "k6/http";
import { check, sleep, group } from "k6";
import { Trend, Rate, Counter } from "k6/metrics";
import { textSummary } from "https://jslib.k6.io/k6-summary/0.0.2/index.js";

const BASE_URL = "https://api.springsnap.com";
const WEB_URL = "https://springsnap.com";

const errorRate = new Rate("error_rate");
const apiLatency = new Trend("api_latency_ms");
const webAppLatency = new Trend("web_app_latency_ms");
const cloudfrontCacheHit = new Rate("cloudfront_cache_hits");

const options = {
    scenarios: {
        smoke_test: {
            executor: "per-vu-iterations",
            vus: 1,
            iterations: 1,
            exec: "mainTestFlow",
            startTime: "0s",
            gracefulStop: "10s",
        },
        average_load_test: {
            executor: "ramping-vus",
            stages: [
                { duration: "2m", target: 50 },
                { duration: "5m", target: 50 },
                { duration: "1m", target: 0 },
            ],
            exec: "mainTestFlow",
            startTime: "0s",
            gracefulRampDown: "30s",
        },
        stress_test: {
            executor: "ramping-vus",
            stages: [
                { duration: "2m", target: 100 },
                { duration: "5m", target: 100 },
                { duration: "2m", target: 200 },
                { duration: "5m", target: 200 },
                { duration: "2m", target: 300 },
                { duration: "5m", target: 300 },
                { duration: "5m", target: 0 },
            ],
            exec: "mainTestFlow",
            startTime: "0s",
            gracefulRampDown: "1m",
        },
        spike_test: {
            executor: "ramping-vus",
            stages: [
                { duration: "1m", target: 200 },
                { duration: "30s", target: 500 },
                { duration: "2m", target: 500 },
                { duration: "30s", target: 20 },
                { duration: "2m", target: 20 },
                { duration: "1m", target: 0 },
            ],
            exec: "mainTestFlow",
            startTime: "0s",
            gracefulRampDown: "30s",
        },
    },
    thresholds: {
        http_req_failed: ["rate<0.05"],
        "http_req_duration{scenario:average_load_test}": ["p(95)<1500"],
        "http_req_duration{scenario:stress_test}": ["p(95)<4000"],
        "http_req_duration{scenario:spike_test}": ["p(95)<8000"],
        error_rate: ["rate<0.05"],
    },
};

const setup = () => {
    const res = http.get(`${BASE_URL}/health`);

    if (res.status !== 200) {
        throw new Error(`Health check failed with status ${res.status}. Aborting the testing now`);
    }
};

const teardown = (data) => {
    console.log(data)
}

const mainTestFlow = () => {
    group("1. Visit springsnap.com & load its assets", () => {
        loadWebApp();
    });

    sleep(Math.random() * 4);

    group("2. User authentication", () => {
        authenticateUser();
    });

    sleep(Math.random() * 4);

    group("3. Core API operations", () => {
        browseCoreApi();
    });

    sleep(Math.random() * 4);

    group("4. File upload & download", () => {
        if (Math.random() < 0.25) {
            fileOperations();
        }
    });
};

const loadWebApp = () => {
    const res = http.get(WEB_URL, {
        tags: { name: "WebAppHomepage" },
        headers: { "Accept-Encoding": "gzip, deflate, br" },
    });

    const success = check(res, {
        "WebApp: Status is 200": (r) => r.status === 200,
        "WebApp: Contains expected content": (r) => r.body.includes("</head>"),
        "WebApp: Response time is acceptable": (r) => r.timings.duration < 3000,
        "Infra: Cloudflare header is present": (r) => r.headers["Cf-Ray"] !== null,
        "Infra: CloudFront header is present": (
            (r) => r.headers["X-Amz-Cf-Id"] !== null ||
                r.headers["Via"] !== null
        ),
    });

    webAppLatency.add(res.timings.duration);
    errorRate.add(!success);

    if (res.headers["X-Cache"] && res.headers["X-Cache"].includes("Hit from AWS CloudFront")) {
        cloudfrontCacheHit.add(1);
    }
};

const authenticateUser = () => {
    const first_name = "Hudson";
    const username = `testuser_${__VU}_${__ITER}`;
    const password = "Password$123!";
    const email = "hudson@springsnap.com"

    const registerRes = http.post(
        `${BASE_URL}/api/v1/auth/signup`,
        JSON.stringify({ first_name, username, password, email }), {
            tags: { name: "API-Register" },
            headers: {
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
        },
    );

    const registerSuccess = check(registerRes, {
        "Auth: Register status is 201": (r) => r.status === 201,
        "Auth: Register response time is acceptable": (r) => r.timings.duration < 2000,
    });

    apiLatency.add(registerRes.timings.duration);
    errorRate.add(!registerSuccess);

    if (registerSuccess) {
        sleep(1);

        const loginRes = http.post(
            `${BASE_URL}/api/v1/auth/login`,
            JSON.stringify({ username, password }), {
                tags: { name: "API-Login" },
                headers: {
                    "Content-Type": "application/json",
                    "Accept": "application/json",
                },
            },
        );

        const loginSuccess = check(loginRes, {
            "Auth: Login status is 200": (r) => r.status === 200,
            "Auth: Login returns access token": (r) => r.json("access_token") !== null,
        });

        apiLatency.add(loginRes.timings.duration);
        errorRate.add(!loginSuccess);
    }
}

const browseCoreApi = () => {
    const endpoints = ["/api/v1/snap/all", "/api/v1/user/details", "/health"];
    
    for (const endpoint of endpoints) {
        const res = http.get(`${BASE_URL}${endpoint}`, {
            tags: { name: `API-Get-${endpoint}` },
            headers: { "Accept": "application/json" },
        });

        const success = check(res, {
            "API: Status is 200": (r) => r.status === 200,
            "API: Response time is acceptable": (r) => r.timings.duration < 1000,
            "Infra: API Gateway Request ID is present": (r) => r.headers["X-Amzn-Requestid"] !== null,
        });

        apiLatency.add(res.timings.duration);
        errorRate.add(!success);
        sleep(0.5);
    }
};

const fileOperations = () => {
    const testFileData = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/wcAAwAB/epv2AAAAABJRU5ErkJggg==";
    const fileBytes = new Uint8Array(testFileData.split("").map(c => c.charCodeAt(0))).buffer;

    const data = {
        img_file: http.file(fileBytes, "test-image.png", "image/png"),
    };

    const uploadRes = http.post(`${BASE_URL}/api/v1/snap/upload`, data, {
        tags: { name: "API-FileUpload" },
    });

    const uploadSuccess = check(uploadRes, {
        "File: Upload status is 201": (r) => r.status === 201,
        "File: Upload response time is acceptable": (r) => r.timings.duration < 5000,
    });

    apiLatency.add(uploadRes.timings.duration);
    errorRate.add(!uploadSuccess);
}

const handleSummary = (data) => {
    return {
        "stdout": textSummary(data, { indent: " ", enableColors: true }),
    }
}

export {
    options,
    setup,
    teardown,
    mainTestFlow,
    handleSummary,
};
