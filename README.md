# caps-esc

Tiny background utility for mapping <kbd>Esc</kbd> key to <kbd>CapsLock</kbd> key. Just like [xcape](https://github.com/alols/xcape) but for X11 and Wayland.

## Usage
```
caps-esc /dev/input/event<x>
```
where `x` corresponds to the keyboard device event input.

## Building and installation
```
sudo dnf install -y libevdev-devel
cd caps-esc
zig build -Drelease
sudo install -s ./zig-out/bin/caps-esc /usr/local/bin
```

Create systemd unit file `/etc/systemd/system/caps-esc@.service`
```
[Unit]
Description=Remap Esc key to CapsLock
#BindsTo=sys-devices-virtual-input-%i.device
#After=sys-devices-virtual-input-%i.device
StopWhenUnneeded=true

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/caps-esc /dev/input/%i
```

Create udev rules `/etc/udev/rules.d/99-caps-esc.rules`
```
ACTION=="add", KERNEL=="event*", SUBSYSTEM=="input", ENV{ID_INPUT_KEYBOARD}=="1", \
ENV{DEVPATH}!="/devices/virtual/input/*", ENV{SYSTEMD_ALIAS}+="/sys/devices/virtual/input/%k", \
OWNER="root", TAG+="systemd", ENV{SYSTEMD_WANTS}="caps-esc@$kernel.service"
```

Initialize and run
```
$ sudo systemctl daemon-reload 
$ sudo udevadm control --reload
$ sudo udevadm trigger --action=add
```

Check the status
```
$ systemctl status caps-esc@\*.service
```

Getting some device information
```
lsusb
udevadm info -a -n /dev/input/event<x>
```

## References
- http://blog.fraggod.net/2012/06/16/proper-ish-way-to-start-long-running-systemd-service-on-udev-event-device-hotplug.html
- https://www.freedesktop.org/software/systemd/man/udev.html
- https://www.freedesktop.org/software/libevdev/doc/latest/
- https://ziglang.org/

## Credits
Inspired by [osm](https://github.com/ursm/osm) and [xcape](https://github.com/alols/xcape) 
