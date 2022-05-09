#!/bin/bash
# SOURCE: https://github.com/tarqmamdouh/tigervnc-gnome

set -e

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-vnctiger.sh - Install vnctiger
#
# usage: install-vnctiger.sh NON_ROOT_USER (use a non root user on your file system)
#
# Copyright (c) 2020 Malcolm Jones
# All Rights Reserved.
#-----------------------------------------------------------------------


logmsg() {
  echo ">>> $1"
}


_user=$1

# SOURCE: https://github.com/tkyonezu/Linux-tools/blob/98a373f3756fe9e27d27a8c3cf7d39fd447ea5c1/install-ctop.sh

# Install cheat
# https://github.com/cheat/cheat/releases

if [[ "${_user}x" = "x" ]]; then
  NON_ROOT_USER=$(whoami)
else
  NON_ROOT_USER=${_user}
fi

sudo apt-get update
sudo apt install tigervnc-standalone-server tigervnc-common -y
sudo apt install tigervnc-xorg-extension -y
sudo apt install xterm -y

logmsg "start up vncserver"
vncserver -localhost no

logmsg "check that vncserver is running"
vncserver -list

logmsg "Configure Xterm, xstartup"
vncserver -kill :1


# mkdir -p /etc/systemd/system/kubelet.service.d
cat ~/.vnc/xstartup || true
cat <<EOF >~/.vnc/xstartup
#!/bin/sh
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r \${HOME}/.Xresources ] && xrdb \${HOME}/.Xresources

EOF

cat ~/.vnc/xstartup || true
chmod u+x ~/.vnc/xstartup

vncserver -kill $DISPLAY

sudo mkdir -p /etc/vnc || true
sudo out=/etc/vnc/xstartup sh -c 'cat << EOF > $out
#!/bin/sh

test x"\$SHELL" = x"" && SHELL=/bin/bash
test x"\$1"     = x"" && set -- default

vncconfig -iconic &
"\$SHELL" -l <<EOF
export XDG_SESSION_TYPE=x11
dbus-launch --exit-with-session gnome-session
exec /etc/X11/Xsession "\$@"
EOF'

echo -e "EOF\nvncserver -kill \$DISPLAY" | sudo tee -a /etc/vnc/xstartup

logmsg "cat /etc/vnc/xstartup"
cat /etc/vnc/xstartup

sudo chmod u+x /etc/vnc/xstartup

sudo NON_ROOT_USER=${NON_ROOT_USER} out=/etc/systemd/system/vncserver@.service sh -c 'cat << EOF > $out
[Service]
Type=forking
User=${NON_ROOT_USER}
Group=${NON_ROOT_USER}
WorkingDirectory=/home/${NON_ROOT_USER}

PIDFile=/home/${NON_ROOT_USER}/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1360x768 -localhost :%i
ExecStop=/usr/bin/vncserver -kill :%i


[Install]
WantedBy=multi-user.target
EOF'

logmsg "cat /etc/systemd/system/vncserver@.service"
cat /etc/systemd/system/vncserver@.service

sudo systemctl daemon-reload
sudo systemctl enable vncserver@1.service
sudo systemctl start vncserver@1.service
# sleep 15
sudo systemctl status vncserver@1.service
vncserver -list

logmsg "don't forget to run a ssh foward command => ssh -L 5901:127.0.0.1:5901 ${NON_ROOT_USER}@$(ifconfig| grep 192 | grep inet | awk '{print $2}')"

exit 0
