#!/bin/sh
# TP-Link TL-WN722N v2/v3 en EasyOS. Interfaz usada: wlan0.
set -eu
IFACE=${1:-wlan0}
fail() { printf '%s\n' "$*" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || fail 'Ejecuta este script como root.'
for cmd in ip iw nmcli; do
    command -v "$cmd" >/dev/null 2>&1 || fail "Falta el comando: $cmd"
done
iw dev "$IFACE" info >/dev/null 2>&1 || fail "No existe la interfaz wifi $IFACE. Comprueba: iw dev"
if iw dev "$IFACE" info | awk '$1 == "type" {print $2}' | grep -qx monitor; then
    printf '%s\n' "$IFACE ya está en modo monitor."
    exit 0
fi
# Si falla el cambio, intenta dejar de nuevo disponible la conexión normal.
rollback() {
    trap - EXIT HUP INT TERM
    ip link set dev "$IFACE" down || true
    iw dev "$IFACE" set type managed || true
    ip link set dev "$IFACE" up || true
    nmcli device set "$IFACE" managed yes || true
    printf '%s\n' 'No se pudo activar el modo monitor; se ha intentado recuperar el modo normal.' >&2
}
trap rollback EXIT
trap 'exit 1' HUP INT TERM
nmcli device set "$IFACE" managed no
ip link set dev "$IFACE" down
iw dev "$IFACE" set type monitor
ip link set dev "$IFACE" up
TYPE=$(iw dev "$IFACE" info | awk '$1 == "type" {print $2}')
[ "$TYPE" = monitor ] || fail 'La interfaz no ha quedado en modo monitor.'
trap - EXIT HUP INT TERM
printf '\n%s\n' "Modo MONITOR activado en $IFACE."
iw dev "$IFACE" info
