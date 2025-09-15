const express = require('express');
const router = express.Router();
const { execFile } = require('child_process');
const path = require('path'); // Add this to handle file paths correctly

router.post('/', (req, res) => {
    const { path: devicePath, method } = req.body;

    // --- REAL WIPE PROCESS ---
    
    // Construct the full path to the executable
    // This assumes your 'backend' and 'rust_cli' folders are at the same level
    const rustEnginePath = path.join(__dirname, '..', '..', 'rust_cli', 'target', 'release', 'rust_cli.exe');

    console.log(`Attempting to run wipe engine from: ${rustEnginePath}`);

    const args = ['--path', devicePath, '--method', method];

    execFile(rustEnginePath, args, (error, stdout, stderr) => {
        if (error) {
            console.error(`Error executing Rust engine: ${stderr}`);
            return res.status(500).json({ 
                success: false, 
                message: 'Wiping failed. The engine returned an error.', 
                error: stderr 
            });
        }
        
        console.log(`Wipe engine output: ${stdout}`);
        res.status(200).json({ 
            success: true, 
            message: 'Device wiped successfully!', 
            log: stdout 
        });
    });
    // --- END OF REAL PROCESS ---
});

module.exports = router;