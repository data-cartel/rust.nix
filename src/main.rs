use clap::Parser;

#[derive(Debug, Parser)]
struct Env {
    #[clap(long, env)]
    api_url: String,
    #[clap(long, env)]
    api_key: String,
    #[clap(short, long, env, default_value = "false")]
    verbose: bool,
    // eth_addr: Option<[u8; 20]>,
    // mode: Mode,
}

// #[derive(Debug)]
// enum Mode {
//     Dev,
//     Prod,
// }

fn main() {
    let env = Env::parse();
    println!("{:#?}", env);
}
