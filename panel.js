const express = require('express');
const basicAuth = require('express-basic-auth');
const os = require('os');
const { exec } = require('child_process');
const fs = require('fs');

const app = express();
const config = JSON.parse(fs.readFileSync('config.json', 'utf8'));

// 配置基本认证
app.use(basicAuth({
    users: { [config.username]: config.password },
    challenge: true,
    unauthorizedResponse: 'Unauthorized'
}));

// 获取系统信息
function getSystemInfo() {
    const totalMem = os.totalmem() / (1024 * 1024 * 1024); // GB
    const freeMem = os.freemem() / (1024 * 1024 * 1024); // GB
    const usedMem = totalMem - freeMem;
    const cpuCount = os.cpus().length;
    const loadAvg = os.loadavg();

    return new Promise((resolve) => {
        exec('df -h /', (err, stdout) => {
            if (err) {
                resolve({
                    cpu: cpuCount,
                    memory: { total: totalMem.toFixed(2), used: usedMem.toFixed(2), free: freeMem.toFixed(2) },
                    disk: '无法获取',
                    load: loadAvg
                });
            } else {
                const diskInfo = stdout.split('\n')[1].split(/\s+/);
                resolve({
                    cpu: cpuCount,
                    memory: { total: totalMem.toFixed(2), used: usedMem.toFixed(2), free: freeMem.toFixed(2) },
                    disk: { total: diskInfo[1], used: diskInfo[2], free: diskInfo[3] },
                    load: loadAvg
                });
            }
        });
    });
}

// 主页路由
app.get('/', async (req, res) => {
    const info = await getSystemInfo();
    res.send(`
        <html>
        <head>
            <title>LNMP Management Panel</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                h1 { color: #333; }
                .info { margin: 10px 0; }
            </style>
        </head>
        <body>
            <h1>LNMP Management Panel</h1>
            <div class="info"><strong>CPU核心数:</strong> ${info.cpu}</div>
            <div class="info"><strong>内存 (GB):</strong> 已用 ${info.memory.used} / 总数 ${info.memory.total} (空闲 ${info.memory.free})</div>
            <div class="info"><strong>硬盘:</strong> 已用 ${info.disk.used} / 总数 ${info.disk.total} (空闲 ${info.disk.free})</div>
            <div class="info"><strong>负载 (1/5/15分钟):</strong> ${info.load[0].toFixed(2)}, ${info.load[1].toFixed(2)}, ${info.load[2].toFixed(2)}</div>
        </body>
        </html>
    `);
});

app.listen(config.port, () => {
    console.log(`管理面板运行在端口 ${config.port}`);
});
