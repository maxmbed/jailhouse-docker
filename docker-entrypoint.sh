
set -x

rootdir=/
workdir=${rootdir}jailhouse-build
materials_dir=${workdir}/materials
buildroot_dir=${workdir}/buildroot
log_dir=${workdir}/logs
sdk_dir=${materials_dir}/sdk
configs_dir=${workdir}/configs
image_dir=${materials_dir}/images

log_file() {
  local log_mesg=$1
  local log_file=$2

  echo "$(date +"%Y-%m-%d %H:%M:%S") ${log_mesg}" >> ${log_file}
}

log_shell() {
  echo $1
}

log_export() {
  cp -r ${log_dir} ${materials_dir}
  sleep 1
}

trap log_export SIGINT

# Build the sdk 
buildroot_build_sdk() {
  local status_file=${log_dir}/buildroot_sdk.status
  local log_file_path=${log_dir}/buildroot_sdk.log
  local defconfig=jailhouse-sdk-qemu_x86_64_defconfig
  local sdk_archive=x86_64-jailhouse-linux-gnu_sdk-buildroot.tar.gz

  cd ${workdir}

  # Clean logs
  rm -fv ${log_file_path}
  rm -fv ${status_file}

  log_file "build sdk start" ${status_file}

  # Set sdk config
  cp ${configs_dir}/${defconfig} ${buildroot_dir}/configs
  if [ $? -ne 0 ]; then
    log_file "set sdk config failure" ${status_file}
    return 1
  fi
  log_file "set sdk config success" ${status_file}

  # Build sdk
  log_file "build running" ${status_file}
  cd ${buildroot_dir}

  if ! make ${defconfig} &>> ${log_file_path}; then
    log_shell "set defconfig failure"
    log_file "set defconfig failure" ${status_file}
    return 1
  fi

  if ! make sdk -j$(nproc) &>> ${log_file_path}; then
    log_shell "build sdk failure"
    log_file "build failure" ${status_file}
    return 1
  fi
  log_file "build success" ${status_file}

  # Export sdk archive
  mkdir -p ${sdk_dir}
  cp ${buildroot_dir}/output/images/${sdk_archive} ${sdk_dir}
  if [ $? -ne 0 ]; then
    log_file "export sdk failure" ${status_file}
    return 1
  fi
  log_file "export sdk success" ${status_file}

  log_file "build sdk done" ${status_file}
  return 0
}

buildroot_build_image() {
  local status_file=${log_dir}/buildroot_image.status
  local log_file_path=${log_dir}/buildroot_image.log
  local defconfig=jailhouse-image-qemu_x86_64_defconfig
  local sdk_archive=x86_64-jailhouse-linux-gnu_sdk-buildroot.tar.gz

  # Clean logs
  rm -fv ${log_file_path}
  rm -fv ${status_file}

  log_file "build image start" ${status_file}

  # Extract sdk
  cd ${sdk_dir}

  tar -xzvf ${sdk_archive} &> ${log_file_path}
  if [ $? -ne 0 ]; then
    log_shell "extract sdk failure"
    log_file "extract failure" ${status_file}
    return 1
  fi 

  log_file "extract sdk success" ${status_file}

  # Set image config
  cp ${configs_dir}/${defconfig} ${buildroot_dir}/configs
  if [ $? -ne 0 ]; then
    log_file "set image config failure" ${status_file}
    return 1
  fi
  log_file "set image config success" ${status_file}

  # Build image
  cd ${buildroot_dir}
  log_file "build running" ${status_file}

  if ! make ${defconfig} &>> ${log_file_path}; then
    log_shell "set defconfig failure"
    log_file "set defconfig failure" ${status_file}
    return 1
  fi

  if ! make -j$(nproc) &> ${log_file_path}; then
    log_shell "build image failure"
    log_file "build failure" ${status_file}
    return 1
  fi

  # Exract images
  cp -r ${buildroot_dir}/output/images ${materials_dir}
  if [ $? -ne 0 ]; then
    log_file "export images failure" ${status_file}
    return 1
  fi
  log_file "export images success" ${status_file}

  log_file "build image done" ${status_file}
  return 0
}

start_system() {
  log_shell "start system"
  local sdk_name=x86_64-jailhouse-linux-gnu_sdk-buildroot
  local qemu_system=${sdk_dir}/${sdk_name}/bin/qemu-system-x86_64

  ${qemu_system} \
      -M pc \
      -kernel ${image_dir}/bzImage \
      -drive file=${image_dir}/rootfs.ext2,if=virtio,format=raw \
      -append "root=/dev/vda console=ttyS0" \
      -net user,hostfwd=tcp:127.0.0.1:3333-:22 \
      -net nic,model=virtio \
      -nographic

  log_shell "exit system"
}

shell() {
  echo "entering shell"
  log_file  "entering shell" ${log_dir}/shell.log
  /bin/bash
  echo "exiting shell"
}

show_usage() {
  echo "usage (to do ..)"
}

while getopts ":sb:x" opt; do
case ${opt} in
  b)
    case ${OPTARG} in
      sdk)
        buildroot_build_sdk
        log_export
        ;;
      image)
        buildroot_build_image
        log_export
        ;;
      all)
        buildroot_build_sdk
        if [ $? -ne 0]; then
          log_export
          exit 1
        fi
        buildroot_build_image
        if [ $? -ne 0 ]; then
          log_export
          exit 1
        fi
        log_export
        ;;
      ?) 
        echo "build option unknown"
        show_usage
        exit
        ;;
    esac
    ;;
  x)
    start_system
    ;;
  s)
    shell
    ;;
  ?)
    show_usage
    ;;
esac
done

