#!/bin/sh
# Vuelve al modo managed y devuelve la interfaz a NetworkManager.
set -eu
IFACE=${1:-wlan0}
fail() { printf '%s\n' "$*" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || fail 'Ejecuta este script como root.'
for cmd in ip iw nmcli; do
    command -v "$cmd" >/dev/null 2>&1 || fail "Falta el comando: $cmd"
done
iw dev "$IFACE" info >/dev/null 2>&1 || fail "No existe la interfaz wifi $IFACE. Comprueba: iw dev"
TYPE=$(iw dev "$IFACE" info | awk '$1 == "type" {print $2}')
if [ "$TYPE" != managed ]; then
    ip link set dev "$IFACE" down
    iw dev "$IFACE" set type managed
fi
ip link set dev "$IFACE" up
nmcli device set "$IFACE" managed yes
TYPE=$(iw dev "$IFACE" info | awk '$1 == "type" {print $2}')
[ "$TYPE" = managed ] || fail 'La interfaz no ha quedado en modo normal.'
printf '\n%s\n' "Modo NORMAL (managed) activado en $IFACE."
iw dev "$IFACE" info
# NetworkManager usará una conexión guardada si existe.
if ! nmcli --wait 20 device connect "$IFACE"; then
    printf '\n%s\n' 'El modo normal está restaurado, pero no se ha conectado automáticamente.' 'Selecciona tu red desde el icono de conexiones y comprueba que el wifi esté activado.'
fi
