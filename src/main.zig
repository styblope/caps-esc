const std = @import("std");
const c = @cImport({
    @cInclude("libevdev/libevdev.h");
    @cInclude("libevdev/libevdev-uinput.h");
});

const FROM_KEY = c.KEY_CAPSLOCK;
const TO_KEY = c.KEY_ESC;

pub fn main() anyerror!void {
    var input_device: []u8 = undefined;
    if (std.os.argv.len == 1) {
        std.debug.print("Usage: {s} /dev/input/event<x>\n", .{std.os.argv[0]});
        std.os.exit(1);
    }
    input_device = std.mem.span(std.os.argv[1]);

    const fd = try std.os.open(input_device, std.os.linux.O.RDWR, std.os.linux.S.IRWXU | std.os.linux.S.IRWXG | std.os.linux.S.IRWXO);
    defer std.os.close(fd);

    var dev: ?*c.libevdev = undefined;
    if (c.libevdev_new_from_fd(fd, &dev) != 0) return error.EvdevError;
    defer c.libevdev_free(dev);

    if (c.libevdev_grab(dev, c.LIBEVDEV_GRAB) != 0) return error.EvdevGrabError;

    std.log.info("Re-mapping keys on {s}, {s}", .{ input_device, c.libevdev_get_name(dev) });

    var uidev: ?*c.libevdev_uinput = undefined;
    if (c.libevdev_uinput_create_from_device(dev, c.LIBEVDEV_UINPUT_OPEN_MANAGED, &uidev) != 0) return error.UInputError;
    defer c.libevdev_uinput_destroy(uidev);

    std.log.info("Sending via {s}", .{c.libevdev_uinput_get_syspath(uidev)});

    var hold: bool = false;
    var ie: c.input_event = undefined;
    while (true) {
        if (c.libevdev_next_event(dev, c.LIBEVDEV_READ_FLAG_NORMAL, &ie) != 0) continue;
        // re-map keys and write event to uinput
        if (ie.type == c.EV_KEY) {
            if (ie.code == FROM_KEY) {
                switch (ie.value) {
                    1 => hold = true,
                    0 => if (hold) {
                        // release original key
                        try write_event(uidev, ie.type, ie.code, 0);
                        // re-mapped key down
                        try write_event(uidev, ie.type, TO_KEY, 1);
                        // re-mapped key up
                        try write_event(uidev, ie.type, TO_KEY, 0);
                    },
                    else => hold = false,
                }
            } else hold = false;
        }
        if (c.libevdev_uinput_write_event(uidev, ie.type, ie.code, ie.value) != 0) return error.UInputEventWriteError;
    }
}

fn write_event(uinput_dev: ?*c.libevdev_uinput, ev_type: c_uint, ev_code: c_uint, ev_value: c_int) anyerror!void {
    if (c.libevdev_uinput_write_event(uinput_dev, ev_type, ev_code, ev_value) != 0) return error.UInputEventWriteError;
    if (c.libevdev_uinput_write_event(uinput_dev, c.EV_SYN, c.SYN_REPORT, 0) != 0) return error.UInputEventWriteError;
}
