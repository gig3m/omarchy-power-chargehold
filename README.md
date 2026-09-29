# Power with Charge Hold

Omarchy's built-in power widget, plus two things it doesn't have:

- **Charge hold** — a toggle that caps charging to protect battery health, by
  writing the kernel's charge-control attributes directly.
- **Power draw history** — a 10-minute watts sparkline.

## Why not just use UPower's charge threshold?

Because on some hardware it silently does nothing.

Desktop toggles for this usually call UPower's
`org.freedesktop.UPower.Device.EnableChargeThreshold`. That method hardcodes a
**75/80** start/stop pair. On the Dell XPS 13 9310 this was written against,
the EC accepts 75/80, stores it in BIOS NVRAM, reports it back correctly — and
then charges straight past 80% to full. A verified counter-example on the same
machine: **50/90 stops dead at 90%**, every time.

Measured, same laptop, same day, both cycles started below the start threshold:

| pair | fresh cycle from | result |
|---|---|---|
| 75/80 (UPower's) | 65% | charged past 80 → 93% |
| 50/90 | 69% | **stopped at 90%, 0.00 A** |

So this plugin skips UPower entirely and writes `charge_control_start_threshold`
/ `charge_control_end_threshold` plus `charge_types=Custom` itself, with values
you control.

There is a second, quieter UPower problem this fixes. Its
`ChargeStartThreshold` / `ChargeEndThreshold` properties report the values its
own limiter *would* apply — **not** what the firmware is set to — and it exposes
no property for the real hardware thresholds at all. A panel that reads them
shows `75-80%` while your firmware is on something else entirely. This plugin
reads sysfs, so the number displayed is the number in effect.

## Install

```bash
# 1. the widget
omarchy plugin add https://github.com/gig3m/omarchy-power-chargehold.git --enable

# 2. the root-owned helper it calls
git clone https://github.com/gig3m/omarchy-power-chargehold.git
cd omarchy-power-chargehold && ./install.sh
```

Step 2 installs `bin/omarchy-charge-hold` to `/usr/local/bin` (owned by root,
mode 0755), which `omarchy plugin add` can't do on its own. Read it first; it is
short. Nothing in sysfs is chmod'ed — writes happen only when the helper
runs as root.

## Configuration

Defaults to 50/90. Override in `/etc/omarchy-charge-hold.conf`:

```sh
START=60
END=80
```

The helper sources this file as root, so keep it root-owned and not writable
by anyone else.

Then verify it actually holds — see *Verifying* below, because a threshold your
firmware accepts is not the same as one it honors.

## Verifying

Firmware can accept a threshold and ignore it, so test rather than trust:

1. Discharge below your `START` value
2. Plug in
3. Confirm it stops at `END`

The EC only applies the stop threshold to a charge cycle that *begins* below the
start threshold. Changing the setting mid-charge does nothing until the next
cycle, so a test that skips step 1 proves nothing.

```bash
/usr/local/bin/omarchy-charge-hold status
```

## Requirements

- Omarchy with `omarchy-shell`
- A laptop exposing `charge_control_*_threshold` in sysfs (kernel 6.12+ for Dell)
- `sudo` or polkit for the helper — the toggle tries passwordless `sudo -n`
  first and falls back to a `pkexec` password prompt. To skip the prompt,
  allow just this helper, not a blanket rule (`sudo visudo -f
  /etc/sudoers.d/charge-hold`):

  ```
  %wheel ALL=(root) NOPASSWD: /usr/local/bin/omarchy-charge-hold on, /usr/local/bin/omarchy-charge-hold off
  ```

## Credit

`Panel.qml` and `Model.js` are forked from the `omarchy.power` widget in
[Omarchy](https://github.com/basecamp/omarchy) (MIT, Copyright (c) David
Heinemeier Hansson); its notice is carried in `LICENSE`. The drain-sparkline approach follows
[Better Battery](https://github.com/AROICE-HQ/omarchy-battery) by aryan-techie.

MIT licensed.
