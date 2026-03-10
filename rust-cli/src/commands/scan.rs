use clap::Args;
use std::path::PathBuf;

#[derive(Args)]
pub struct ScanArgs {
    /// Project directory to scan
    pub dir: Option<String>,
    /// Additional glob patterns to exclude
    #[arg(long, num_args = 1..)]
    pub exclude: Vec<String>,
    /// Output machine-readable JSON
    #[arg(long)]
    pub json: bool,
}

pub fn run(args: ScanArgs) {
    let dir = args.dir.unwrap_or_else(|| ".".to_string());
    let root = PathBuf::from(&dir);
    let root = match root.canonicalize() {
        Ok(p) => p,
        Err(e) => {
            eprintln!("Error: cannot resolve directory '{}': {}", dir, e);
            std::process::exit(1);
        }
    };

    if !args.json {
        println!("Scanning {}...", root.display());
    }

    match crate::scanner::scan_and_save(&root, &args.exclude) {
        Ok(graph) => {
            let codemap_dir = root.join(".codemap");
            // 生成 slices/（与 Node.js scan 行为一致）
            if let Err(e) = crate::slicer::save_slices(&codemap_dir, &graph) {
                eprintln!("Warning: failed to save slices: {}", e);
            }
            if args.json {
                let payload = serde_json::json!({
                    "project": graph.project,
                    "scannedAt": graph.scanned_at,
                    "commitHash": graph.commit_hash,
                    "summary": graph.summary,
                    "outputDir": codemap_dir,
                });
                match serde_json::to_string_pretty(&payload) {
                    Ok(json) => println!("{}", json),
                    Err(e) => {
                        eprintln!("Serialization error: {}", e);
                        std::process::exit(1);
                    }
                }
            } else {
                println!("Scan complete.");
                println!("  Files:     {}", graph.summary.total_files);
                println!("  Functions: {}", graph.summary.total_functions);
                println!("  Modules:   {}", graph.summary.modules.join(", "));
                println!("  Output:    {}", codemap_dir.display());
            }
        }
        Err(e) => {
            eprintln!("Scan failed: {}", e);
            std::process::exit(1);
        }
    }
}
