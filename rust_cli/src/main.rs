use clap::Parser;
use serde::Serialize;
use std::fs::{self, OpenOptions};
use std::io::{Seek, SeekFrom, Write};
use std::path::PathBuf;
use chrono::Utc;
use rand::{rng, RngCore};  // rng() replaces thread_rng()


/// CLI arguments
#[derive(Parser, Debug)]
#[command(name = "onewipe-cli")]
#[command(about = "Rust Wipe CLI (SIH Demo)", long_about = None)]
struct Args {
    /// Folder path to scan and wipe
    #[arg(short, long)]
    target: PathBuf,

    /// Output log file path
    #[arg(short, long, default_value = "logs/wipe_log.json")]
    output: PathBuf,
}

/// File info struct for JSON
#[derive(Serialize)]
struct FileLog {
    name: String,
    size_bytes: u64,
    path: String,
    passes: Vec<String>,
    status: String,
}

/// Log struct
#[derive(Serialize)]
struct WipeLog {
    folder: String,
    wiped_at: String,
    files: Vec<FileLog>,
}

/// Overwrite a file with multiple passes
fn overwrite_file(path: &PathBuf) -> std::io::Result<Vec<String>> {
    let metadata = fs::metadata(path)?;
    let size = metadata.len();
    let mut passes_done = Vec::new();

    // Open file for write
    let mut file = OpenOptions::new().write(true).open(path)?;

    // Pass 1: all zeros
    let zeros = vec![0u8; 4096];
    for _ in 0..(size / 4096 + 1) {
        file.write_all(&zeros)?;
    }
    file.seek(SeekFrom::Start(0))?;
    passes_done.push("Pass 1: zeros".to_string());

    // Pass 2: all ones (0xFF)
    let ones = vec![0xFFu8; 4096];
    for _ in 0..(size / 4096 + 1) {
        file.write_all(&ones)?;
    }
    file.seek(SeekFrom::Start(0))?;
    passes_done.push("Pass 2: ones".to_string());

    // Pass 3: random bytes (new API)
    let mut rng = rng(); // ✅ replaces thread_rng()
    let mut random_data = vec![0u8; 4096];
    for _ in 0..(size / 4096 + 1) {
        rng.fill_bytes(&mut random_data);
        file.write_all(&random_data)?;
    }
    passes_done.push("Pass 3: random".to_string());

    Ok(passes_done)
}


fn main() -> std::io::Result<()> {
    let args = Args::parse();

    // Create logs folder if it doesn’t exist
    if let Some(parent) = args.output.parent() {
        fs::create_dir_all(parent)?;
    }

    let mut file_logs: Vec<FileLog> = Vec::new();

    // Read the directory
    for entry in fs::read_dir(&args.target)? {
        let entry = entry?;
        let metadata = entry.metadata()?;

        if metadata.is_file() {
            let passes_done = match overwrite_file(&entry.path()) {
                Ok(passes) => passes,
                Err(_) => vec!["Error overwriting file".to_string()],
            };

            let file_log = FileLog {
                name: entry.file_name().to_string_lossy().to_string(),
                size_bytes: metadata.len(),
                path: entry.path().display().to_string(),
                passes: passes_done,
                status: "completed".to_string(),
            };
            file_logs.push(file_log);
        }
    }

    // Build final log
    let log = WipeLog {
        folder: args.target.display().to_string(),
        wiped_at: Utc::now().to_rfc3339(),
        files: file_logs,
    };

    // Serialize to JSON
    let json_data = serde_json::to_string_pretty(&log).unwrap();

    // Write to file
    fs::write(&args.output, json_data)?;

    println!("✅ Wipe complete. Log saved at {:?}", args.output);

    Ok(())
}
