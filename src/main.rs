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
    #[clap(long, env = "ETHEREUM_ADDRESS", value_parser = EthAddr::parse)]
    eth_addr: Option<EthAddr>,
    // #[arg(short, long, action = clap::ArgAction::Count)]
    // verbose: u8,
}

#[derive(Clone)]
struct EthAddr([u8; 20]);

impl std::fmt::Debug for EthAddr {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let mut hex = [0u8; 40];
        hex::encode_to_slice(&self.0, &mut hex).unwrap();
        write!(f, "0x{}", String::from_utf8_lossy(&hex))
    }
}

impl EthAddr {
    fn parse(s: &str) -> Result<Self, String> {
        if s.len() == 42 {
            return Self::parse(s.trim_start_matches("0x"));
        }

        match hex::decode(s) {
            Err(err) => Err(format!("Invalid Ethereum address hex: {}", err)),
            Ok(bytes) => bytes
                .try_into()
                .map(EthAddr)
                .map_err(|_| "Invalid Ethereum address length".to_string()),
        }
    }
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
