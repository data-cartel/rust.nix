use clap::Parser;
use tracing::*;

#[derive(Debug, Parser)]
struct Env {
    #[clap(long, env, default_value = "INFO")]
    log_level: Level,
}

fn main() {
    let env = Env::parse();
    tracing_subscriber::fmt()
        .with_max_level(env.log_level)
        .finish();

    info!("{env:#?}");
}
