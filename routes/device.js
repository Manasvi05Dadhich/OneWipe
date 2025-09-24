const express = require('express');
const router = express.Router();

// This handles GET requests to /api/device
router.get('/', (req, res) => {

    // This is sample data. Later, this could come from the Rust engine.
    const sampleDeviceInfo = {
        deviceName: "Sample NVMe SSD",
        size: "512 GB",
        partitions: 2,
        status: "Healthy",
        isWipeable: true
    };

    // Send the device info as a JSON response
    res.status(200).json(sampleDeviceInfo);
});

module.exports = router;