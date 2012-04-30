# Class: selinux::config
#
# Description
#  This class is designed to configure the system to use SELinux on the system
#
# Parameters:
#  - $mode (enforced|permissive|disabled) - sets the operating state for SELinux.
# 
# Actions:
#  Configures SELinux to a specific state (enforced|permissive|disabled)
#
# Requires:
#  This module has no requirements
#
# Sample Usage:
#  This module should not be called directly.
#
class selinux::config(
  $mode
) {
  Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin',
  }

  file { $selinux::params::sx_mod_dir:
    ensure => directory,
  }

  # Check to see if the mode set is valid.
  if $mode == 'enforcing' or $mode == 'permissive' or $mode == 'disabled' {

  # Change mode _first_
    case $mode {
      permissive,disabled: { 
        $sestatus = '0'
        if $mode == 'disabled' and $::selinux_current_mode == 'permissive' {
          notice('A reboot is required to fully disable SELinux. SELinux will operate in Permissive mode until a reboot')
        }

        service{restorecond:
         ensure => stopped,
          enable => false,
         }

        service{mcstrans:
         ensure => stopped,
          enable => false,
        }

      }
      enforcing: {
        $sestatus = '1'
      }
    }

    exec { "change-selinux-status-to-${mode}":
      command => "echo ${sestatus} > /selinux/enforce",
      unless  => "grep -q '${sestatus}' /selinux/enforce",
    }

    # Replace the SELinux mod in config files
    exec { "set-selinux-config-to-${mode}-A":
      user    => root,
      command => "sed -i \"s@^\\(SELINUX=\\).*@\\1${mode}@\" /etc/sysconfig/selinux",
      unless  => "grep -q \"SELINUX=${mode}\" /etc/sysconfig/selinux",
    }

    exec { "set-selinux-config-to-${mode}-B":
      user    => root,
      command => "sed -i \"s@^\\(SELINUX=\\).*@\\1${mode}@\" /etc/sysconfig/selinux",
      unless  => "grep -q \"SELINUX=${mode}\" /etc/selinux/config",
    }

  } else {
    fail("Invalid mode specified for SELinux: ${mode}")
  }
}
