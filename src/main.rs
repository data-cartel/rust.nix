use clap::{Parser, ValueEnum};

#[derive(Debug, Parser)]
struct Env {
    #[clap(long, env)]
    api_url: String,
    #[clap(long, env)]
    api_key: String,
    #[clap(short, long = "debug", env = "DEBUG", default_value = "false")]
    verbose: bool,
    #[clap(short, long, env, default_value = "dev")]
    mode: Mode,
    // #[clap(long, env = "ETHEREUM_ADDRESS")]
    // eth_addr: Option<[u8; 20]>,
}

#[derive(Clone, Debug, ValueEnum)]
enum Mode {
    #[clap(name = "dev")]
    Development,
    #[clap(name = "prod")]
    Production,
}

fn main() {
    let env = Env::parse();
    println!("{:#?}", env);
}
