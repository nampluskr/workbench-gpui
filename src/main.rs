mod dev;
mod keymap;
mod state;
mod ui;

fn main() {
    ui::run(dev::DevOptions::from_args());
}
