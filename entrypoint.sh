#!/bin/bash
echo -n 'Starting dovecot... '; dovecot -c /etc/dovecot/dovecot.conf && echo "ok." || { echo "failed!"; exit 1; }
echo -n "Launching first run check... "; su -l user -c '/firstrun.sh &'; echo "launched."
echo "Starting Notbit..."

declare -g -i __notbit_pid=0 __sigterm=0

sigterm_handler() {
  __sigterm=1; echo "SIGTERM handler called..."
  [ ${__notbit_pid} -eq 0 ] || \
    ! kill -0 ${__notbit_pid} > /dev/null 2>&1 || \
    kill ${__notbit_pid}
}
trap 'sigterm_handler' SIGTERM

declare -a __notbit_args
__notbit_args+=( -s 60025 -D /data/notbit -m /data/maildir -l /data/notbit.log )
[ -z "${SOCKS_ADDRESS}" ] || __notbit_args+=( -r "${SOCKS_ADDRESS}" -B -i )

while [ ${__sigterm} -eq 0 ]; do
  su-exec user:user notbit "${__notbit_args[@]}" "${@}" &
  __notbit_pid=${!}
  [ -z ${__notbit_return_code} ] && echo "Notbit started." || echo "Notbit restarted."
  unset __notbit_return_code; wait ${__notbit_pid}; __notbit_return_code=${?}
  echo -n "Notbit exited with code ${__notbit_return_code}... "
  kill -0 ${__notbit_pid} > /dev/null 2>&1 || __notbit_pid=0
  [ ${__sigterm} -ne 0 ] || {
    sleep 5
    [ ${__notbit_pid} -eq 0 ] || \
      ! kill -0 ${__notbit_pid} > /dev/null 2>&1 || \
      kill ${__notbit_pid}
    echo "Restarting Notbit..."
  }
done
