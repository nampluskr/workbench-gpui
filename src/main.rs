mod dev;
mod ui;

fn main() {
    ui::run(dev::DevOptions::from_args());
}
