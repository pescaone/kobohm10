# Connect kobo with XC-Soar to XC-Tracer over BLE
The project is about to equip a kobo reader with a HM-10/HM-11 module, and connect it to a XC-Tracer over bluetooth low energy BLE.

Hardware:

connect module to a UART interface on kobo board.

VCC kobo <-> VCC HM-10

TX  kobo <-> RX  HM-10

RX  kobo <-> TX  HM-10

GND kobo <-> GND HM-10

Software on kobo:

Install XC-Soar
https://www.xcsoar.org/download/

Configure module:

1. copy script HM10Init.sh to XCSoarData/kobo/scripts

2. restart kobo

3. power on XC-Tracer (config enable BLE string, driver LXWP0)

4. reset module (connect reset pin to GND or disconnect power of module)

5. choose "Tools" and execute HM10Init.sh

6. BLE pairing should be complete

7. choose "Fly", go to "Devices" and select ttymxc0/ttymxc1/ttymxc2 with 115200 baud, driver LXNAV

8. press "Monitor", data should come in now

9. if not, try again

Major Pitfalls:

- On the kobo aura, only one UART interface (ttymxc0) was working. If anything connected to the 2nd, the kobo won't boot.

- HM-10/HM-11 modules with software version below V605 won't work.

- The bootloader of the kobo runs on ttymxc0 with 115200 baud. At powerup, it generates enough traffic to confuse the HM-10/HM-11 module. It's necessary to reset the module after power up the kobo to configure it. Once the pairing is complete, this is no more necessary.
