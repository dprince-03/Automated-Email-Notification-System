require('dotenv').config();
const express = require('express');

const app = express();
const port = process.env.PORT || 5000;

app.use(express.json());

app.get('/', (req, res) => {
    return res.status(200).json({
        success: true,
        message: 'Root endpoint is working fine bro!',
    });
});

const startServer = async () => {
    
    const server = app.listen(port, () => {
        console.log(`Server is running on port: ${port}`);
        console.log(`Api url: http://localhost:${port}`);
    });
};

startServer();

module.exports = app;