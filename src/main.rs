mod dev;
mod fsops;
mod keymap;
mod state;
mod text_io;
mod ui;

fn main() {
    let options = dev::DevOptions::from_args();
    if let Some((op, dir)) = &options.trash_cmd {
        dev::run_trash_command(op, dir);
        return;
    }
    ui::run(options);
}
