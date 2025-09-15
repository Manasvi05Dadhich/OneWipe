const express = require('express');
const router = express.Router();
const PDFDocument = require('pdfkit');
const fs = require('fs');

// The path is now '/generate' because '/api/certificate' will be in server.js
router.post('/generate', (req, res) => {
    console.log('Received certificate generation request via cert.js:', req.body);
    const { deviceModel, wipeMethod, timestamp } = req.body;

    const doc = new PDFDocument({ size: 'A4', margin: 50 });
    const fileName = `Wipe-Certificate-${Date.now()}.pdf`;

    doc.pipe(fs.createWriteStream(fileName));
    // (Add your PDF content here as before)
    doc.fontSize(25).text('Certificate of Data Destruction', { align: 'center' });
    doc.moveDown(2);
    doc.fontSize(16).text('This is to certify that the data on the following device has been securely and irreversibly destroyed.');
    doc.moveDown();
    doc.fontSize(14).text(`Device Model:`, { continued: true }).font('Helvetica-Bold').text(` ${deviceModel || 'N/A'}`);
    doc.font('Helvetica').text(`Wipe Method:`, { continued: true }).font('Helvetica-Bold').text(` ${wipeMethod || 'N/A'}`);
    doc.font('Helvetica').text(`Completion Date:`, { continued: true }).font('Helvetica-Bold').text(` ${new Date(timestamp || Date.now()).toLocaleString()}`);

    doc.end();

    res.status(200).json({ success: true, message: 'Certificate generated successfully!', file: fileName });
});

module.exports = router; // Export the router