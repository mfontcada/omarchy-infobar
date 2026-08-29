#!/usr/bin/env bash
# Emit CPU usage/temp, GPU usage/temp, RAM, and root disk as pipe-delimited
# fields for the omarchy-infobar Quickshell module.

set -u

cpu_usage() {
  read -r _ u n s id io irq sirq st _ </proc/stat
  idle0=$((id + io))
  total0=$((u + n + s + id + io + irq + sirq + st))
  sleep 0.5
  read -r _ u n s id io irq sirq st _ </proc/stat
  idle1=$((id + io))
  total1=$((u + n + s + id + io + irq + sirq + st))
  didle=$((idle1 - idle0))
  dtotal=$((total1 - total0))

  if ((dtotal > 0)); then
    awk -v dI="$didle" -v dT="$dtotal" 'BEGIN { printf "%.0f", (1 - dI/dT) * 100 }'
  else
    echo "--"
  fi
}

cpu_temp() {
  if command -v sensors >/dev/null 2>&1; then
    local value
    value=$(sensors 2>/dev/null | awk '/^(Package id 0|Tctl|Tdie|CPU Temperature):/ {print $2; exit}')
    if [[ -n "$value" ]]; then
      echo "${value//[+°C]/}"
      return
    fi
  fi

  local zone type
  for zone in /sys/class/thermal/thermal_zone*; do
    [[ -r "$zone/type" && -r "$zone/temp" ]] || continue
    type=$(<"$zone/type")
    case "$type" in
      x86_pkg_temp|cpu-thermal|acpitz|soc_thermal)
        awk '{printf "%.0f", $1/1000}' "$zone/temp"
        return
        ;;
    esac
  done
  echo "--"
}

gpu_info() {
  local usage="--" temp="--" dev vendor line h sample

  for dev in /sys/class/drm/card*/device; do
    [[ -r "$dev/vendor" ]] || continue
    vendor=$(<"$dev/vendor")
    case "$vendor" in
      0x10de)
        if command -v nvidia-smi >/dev/null 2>&1; then
          line=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n 1)
          usage=${line%%,*}
          temp=${line##*, }
        fi
        echo "$usage|$temp"
        return
        ;;
      0x1002|0x1022)
        [[ -r "$dev/gpu_busy_percent" ]] && usage=$(<"$dev/gpu_busy_percent")
        for h in "$dev"/hwmon/hwmon*/temp*_input; do
          [[ -r "$h" ]] || continue
          temp=$(awk '{printf "%.0f", $1/1000}' "$h")
          break
        done
        echo "$usage|$temp"
        return
        ;;
      0x8086)
        for h in "$dev"/hwmon/hwmon*/temp*_input; do
          [[ -r "$h" ]] || continue
          temp=$(awk '{printf "%.0f", $1/1000}' "$h")
          break
        done
        if command -v intel_gpu_top >/dev/null 2>&1 && command -v timeout >/dev/null 2>&1; then
          sample=$(timeout 0.3s intel_gpu_top -J -s 200 2>/dev/null | head -n 200)
          if [[ -n "$sample" ]]; then
            usage=$(awk -v RS=',' 'match($0, /"busy" *: *([0-9.]+)/, m) {s+=m[1]; c++} END {if(c) printf "%.0f", s/c}' <<<"$sample")
            [[ -z "$usage" ]] && usage="--"
          fi
        fi
        echo "$usage|$temp"
        return
        ;;
    esac
  done

  echo "--|--"
}

ram_usage() {
  awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {printf "%.1f/%.0fG", (t-a)/1024/1024, t/1024/1024}' /proc/meminfo
}

disk_usage() {
  local size used
  read -r size used _ <<<"$(df -BG --output=size,used / | tail -n 1)"
  echo "${used}/${size}"
}

cpu_pct=$(cpu_usage)
cpu_tmp=$(cpu_temp)
IFS='|' read -r gpu_pct gpu_tmp <<<"$(gpu_info)"
ram=$(ram_usage)
disk=$(disk_usage)

printf '%s|%s|%s|%s|%s|%s\n' "$cpu_pct" "$cpu_tmp" "$gpu_pct" "$gpu_tmp" "$ram" "$disk"
