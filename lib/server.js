const express = require('express');

// 서버용 인스턴스 생성
const app = express();

// GET '/'(루트) 접근 시 동작
app.get('/', (req, res) => {
    res.status(200).send('hello world\n');
});


// GET '/user/:id'와 일치하는 GET의 동작
app.get('/user/:gemini_ai', (req, res) => {
    res.status(200).send(req.params.id);
});

// 포트 3000번에서 서버를 기동
app.listen(3000, () => {
    // 서버 기동 후에 호출되는 콜백
    console.log('start listening');
});
