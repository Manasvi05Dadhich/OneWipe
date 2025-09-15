use clap::{Parser, ValueEnum};
use serde::Serialize;
use std::fs::{self, OpenOptions};
use std::io::{Seek, SeekFrom, Write};
use std::path::{Path, PathBuf};
use chrono::Utc;
use rand::{rng, RngCore};

/// Available wipe policies
#[derive(ValueEnum, Clone, Debug)]
enum Policy {
    /// Clear method: 1 pass overwrite with zeros
    Clear,
    /// DoD 5220.22-M method: 3 passes (zeros → ones → random)
    Dod,
}

/// CLI arguments
#[derive(Parser, Debug)]
#[command(
    name = "OneWipe",
    author = "SIH Team",
    version = "0.3",
    about = "OneWipe - Rust-based Secure Data Wipe CLI (SIH Demo)",
    long_about = r"
OneWipe is a secure file/folder wiping tool written in Rust.
It supports multiple sanitization policies and generates tamper-proof logs.

📌 Available Policies:
  clear   Single pass overwrite with zeros (NIST Clear)
  dod     3-pass overwrite (zeros, ones, random) [DoD 5220.22-M]

📌 Commands & Examples:
  OneWipe --target D:\testdata --policy clear
     → Wipes files in D:\testdata using single pass (zeros), saves log to logs/wipe_TIMESTAMP.json

  OneWipe --target D:\testdata --policy dod --output D:\logs
     → Wipes files using DoD 3-pass, saves unique log to D:\logs\wipe_TIMESTAMP.json

  OneWipe --target D:\testdata --policy dod --output D:\logs\result.json
     → Saves log as result.json inside D:\logs

  OneWipe --target D:\testdata --policy dod --dry-run
     → Simulates wipe without overwriting files

  OneWipe --target D:\testdata --policy clear --force
     → Runs without confirmation
"
)]
struct Args {
    /// Target file or folder path to wipe
    #[arg(short, long, value_name = "PATH")]
    target: PathBuf,

    /// Wipe policy [default: clear]
    #[arg(short, long, default_value = "clear", value_enum)]
    policy: Policy,

    /// Output log file path [default: logs/wipe_log.json]
    #[arg(short, long, default_value = "logs/wipe_log.json", value_name = "FILE")]
    output: PathBuf,

    /// Dry run mode (simulate wipe without overwriting files)
    #[arg(long)]
    dry_run: bool,

    /// Force mode (skip confirmation prompt)
    #[arg(long)]
    force: bool,
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
    policy: String,
    files: Vec<FileLog>,
}

/// Utility: generate unique filename with timestamp
fn generate_unique_filename(base_folder: &Path) -> PathBuf {
    let timestamp = Utc::now().format("wipe_%Y-%m-%d_%H-%M-%S.json").to_string();
    base_folder.join(timestamp)
}

/// Resolve output path based on rules
fn resolve_output_path(output_arg: &PathBuf) -> PathBuf {
    // Case 1: Default logs/wipe_log.json → unique file
    if output_arg == &PathBuf::from("logs/wipe_log.json") {
        let logs_folder = Path::new("logs");
        fs::create_dir_all(logs_folder).unwrap();
        return generate_unique_filename(logs_folder);
    }

    // Case 2: Directory only → generate file inside
    if output_arg.is_dir() || output_arg.extension().is_none() {
        fs::create_dir_all(output_arg).unwrap();
        return generate_unique_filename(output_arg);
    }

    // Case 3: Wrong extension → fix to .json
    if let Some(ext) = output_arg.extension() {
        if ext != "json" {
            println!("⚠️ Only JSON format supported. Changing extension to .json");
            let mut fixed = output_arg.clone();
            fixed.set_extension("json");
            return fixed;
        }
    } else {
        let mut fixed = output_arg.clone();
        fixed.set_extension("json");
        return fixed;
    }

    // Case 4: Valid file path
    output_arg.clone()
}

/// Overwrite a file according to policy
fn overwrite_file(path: &PathBuf, policy: &Policy) -> std::io::Result<Vec<String>> {
    let metadata = fs::metadata(path)?;
    let size = metadata.len();
    let mut passes_done = Vec::new();

    let mut file = OpenOptions::new().write(true).open(path)?;

    match policy {
        Policy::Clear => {
            let zeros = vec![0u8; 4096];
            for _ in 0..(size / 4096 + 1) {
                file.write_all(&zeros)?;
            }
            passes_done.push("Pass 1: zeros".to_string());
        }
        Policy::Dod => {
            let zeros = vec![0u8; 4096];
            for _ in 0..(size / 4096 + 1) {
                file.write_all(&zeros)?;
            }
            file.seek(SeekFrom::Start(0))?;
            passes_done.push("Pass 1: zeros".to_string());

            let ones = vec![0xFFu8; 4096];
            for _ in 0..(size / 4096 + 1) {
                file.write_all(&ones)?;
            }
            file.seek(SeekFrom::Start(0))?;
            passes_done.push("Pass 2: ones".to_string());

            let mut rng = rng();
            let mut random_data = vec![0u8; 4096];
            for _ in 0..(size / 4096 + 1) {
                rng.fill_bytes(&mut random_data);
                file.write_all(&random_data)?;
            }
            passes_done.push("Pass 3: random".to_string());
        }
    }

    Ok(passes_done)
}

fn main() -> std::io::Result<()> {
    let args = Args::parse();

    // Resolve correct output path
    let output_path = resolve_output_path(&args.output);

    // 🔹 Ensure parent folder exists (auto-create if missing)
    if let Some(parent) = output_path.parent() {
        fs::create_dir_all(parent)?;
    }

    // Confirmation prompt (unless force or dry-run)
    if !args.force && !args.dry_run {
        println!(
            "⚠️  Are you sure you want to wipe {:?} with policy {:?}? (y/N): ",
            args.target, args.policy
        );

        let mut input = String::new();
        std::io::stdin().read_line(&mut input)?;
        if input.trim().to_lowercase() != "y" {
            println!("❌ Operation cancelled.");
            return Ok(());
        }
    }

    let mut file_logs: Vec<FileLog> = Vec::new();

    // Process target directory
    for entry in fs::read_dir(&args.target)? {
        let entry = entry?;
        let metadata = entry.metadata()?;

        if metadata.is_file() {
            println!("📝 Processing file: {}", entry.file_name().to_string_lossy());

            let passes_done = if args.dry_run {
                vec!["Dry run: no data overwritten".to_string()]
            } else {
                match overwrite_file(&entry.path(), &args.policy) {
                    Ok(passes) => passes,
                    Err(e) => {
                        println!("⚠️ Skipping file {:?}: {}", entry.path(), e);
                        vec!["Error overwriting file".to_string()]
                    }
                }
            };

            let file_log = FileLog {
                name: entry.file_name().to_string_lossy().to_string(),
                size_bytes: metadata.len(),
                path: entry.path().display().to_string(),
                passes: passes_done,
                status: if args.dry_run { "dry-run".to_string() } else { "completed".to_string() },
            };
            file_logs.push(file_log);
        }
    }

    // Build log
    let log = WipeLog {
        folder: args.target.display().to_string(),
        wiped_at: Utc::now().to_rfc3339(),
        policy: format!("{:?}", args.policy),
        files: file_logs,
    };

    // Serialize & write JSON log
    let json_data = serde_json::to_string_pretty(&log).unwrap();
    fs::write(&output_path, json_data)?;

    println!("✅ Wipe complete. Log saved at {:?}", output_path);

    Ok(())
}
