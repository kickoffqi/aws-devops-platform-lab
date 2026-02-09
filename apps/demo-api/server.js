const http = require("http");

const port = process.env.PORT || 3000;
const version = process.env.APP_VERSION || "0.1.0";

const server = http.createServer((req, res) => {
    if (req.url === "/health") {
        res.writeHead(200, { "Content-Type": "text/plain" });
        res.end("OK");
        return;
    }

    if (req.url === "/") {
        res.writeHead(200, { "Content-Type": "text/plain" });
        res.end(`demo-api version ${version}`);
        return;
    }

    res.writeHead(404, { "Content-Type": "text/plain" });
    res.end("Not Found");
});

server.listen(port, () => {
    console.log(`demo-api listening on ${port}`);
});
