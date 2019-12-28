#!/bin/bash

function die() {
  echo $*
  exit 1
}

# build your own Pi MusicBox.
# reeeeeeaaallly alpha. Also see Create Pi MusicBox.rst

MIN_FREE_SPACE_KB=$(expr 1024 \* 1024)
FREE_SPACE=$(df | awk '$NF == "/" { print $4 }')
if [ $FREE_SPACE -lt $MIN_FREE_SPACE_KB ]; then
    echo "************************************************"
    echo "** ERROR: Insufficient free space to upgrade  **"
    echo "** Use ./makeimage.sh bigger <image_file>     **"
    echo "************************************************"
    exit 3
fi

#Update the mount options so anyone can mount the boot partition and give everyone all permissions.
sed -i '/mmcblk0p1\s\+\/boot\s\+vfat/ s/defaults /defaults,user,umask=000/' /etc/fstab

apt-key adv --keyserver pool.sks-keyservers.net --recv-keys F8E3347256922A8AE767605B7808CE96D38B9201

if ! grep -q "Europe/London" /etc/timezone
then
    apt-get install --yes locales || die "Failed to install locales"
    echo "Europe/London" > /etc/timezone
    dpkg-reconfigure -f noninteractive tzdata || die "Failed to configure tzdata"
    sed -i -e 's/en_US.UTF-8 UTF-8/# en_US.UTF-8 UTF-8/' /etc/locale.gen
    sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
    echo -e 'LANG="en_GB.UTF-8"\nLANGUAGE="en_GB:en"' > /etc/default/locale
    dpkg-reconfigure --frontend=noninteractive locales || die "Failed to configure locales"
    update-locale LANG=en_GB.UTF-8 || die "Failed to configure locale"
fi

if [ ! -f /etc/apt/sources.list.d/upmpdcli.list ]; then
    cat << EOF > /etc/apt/sources.list.d/upmpdcli.list
deb http://www.lesbonscomptes.com/upmpdcli/downloads/raspbian/ stretch main
deb-src http://www.lesbonscomptes.com/upmpdcli/downloads/raspbian/ stretch main
EOF
fi

apt-get remove --yes --purge python-pykka python-pylast
# https://github.com/pimusicbox/pimusicbox/issues/316
apt-get remove --yes --purge linux-wlan-ng

# Ensure we reinstall the upstream config.
apt-get install --yes -o Dpkg::Options::="--force-confmiss" --reinstall avahi-daemon

#make sure no unneeded packages are installed
printf 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";\n' > /etc/apt/apt.conf

#Install the packages you need to continue:
apt-get update && apt-get --yes install sudo wget unzip mc || die "Failed to install required packages"

#Next, issue this command to update the distribution.
#This is good because newer versions have fixes for audio and usb-issues:

apt-get dist-upgrade -y || die "distribution upgrade failed"


#if [ ! -f /etc/apt/sources.list.d/mopidy.list ]; then
# wget -q -O - http://apt.mopidy.com/mopidy.gpg | apt-key add -
# wget -q -O /etc/apt/sources.list.d/mopidy.list https://apt.mopidy.com/buster.list
#i

#update time, to prevent update problems
apt install ntpdate || die "Failed to install ntpdate"
ntpdate -u ntp.ubuntu.com || die "Failed to set time"

apt-get install --yes --allow-unauthenticated apt-transport-https || die "Failed to install apt-transport-https"

#Then install all packages we need with this command:
apt-get update || die "updating package list failed"

for pkg in build-essential autoconf automake python3.8-dev logrotate \
           alsa-utils wpasupplicant \
           libgstreamer1.0-0 \
           gir1.2-gstreamer-1.0 \
           gir1.2-gst-plugins-base-1.0 \
           libgstreamer-plugins-base1.0-0 \
           gstreamer1.0-plugins-good \
           gstreamer1.0-plugins-bad \
           gstreamer1.0-plugins-ugly \
           gstreamer1.0-fluendo-mp3 \
           gstreamer1.0-alsa \
           gstreamer1.0-tools \
           python3-gst-1.0 \
           exfat-fuse ifplugd \
           samba dos2unix avahi-utils \
           avahi-daemon wireless-regdb crda \
           alsa-base cifs-utils avahi-autoipd libnss-mdns \
           ntpdate ca-certificates ncmpcpp rpi-update \
           alsa-firmware-loaders iw atmel-firmware \
           firmware-atheros firmware-brcm80211 firmware-ipw2x00 \
           firmware-iwlwifi firmware-libertas firmware-linux \
           firmware-linux-nonfree firmware-ralink firmware-realtek \
           zd1211-firmware iptables build-essential python-dev \
           usbmount monit upmpdcli watchdog dropbear mpc dosfstools \
           libxml2-dev libxslt1-dev python-tunigo \
           xmltoman  libdaemon-dev \
           libasound2-dev libpopt-dev libconfig-dev \
           libavahi-client-dev libssl-dev libc6 libconfig9 \
           libdaemon0 libasound2 libpopt0 libavahi-common3 \
           avahi-daemon libavahi-client3 libssl1.0.2 libtool \
           libffi-dev libssl-dev \
           libxml2-dev libxmlsec1-dev libspotify-dev
do
    apt-get --yes --no-install-suggests --no-install-recommends install $pkg || die "Failed to install $pkg"
done
           
# update pip from sources
rm -rf /tmp/pip_build_root
curl https://bootstrap.pypa.io/get-pip.py | python || die "Failed to update PIP"
python3 -m pip install --upgrade setuptools || die "Failed to update setuptools"

# Attempted workarounds for SSL/TLS issues in old Python version.
pip3 install --upgrade certifi urllib3[secure] requests[security] || die "Failed to install required Python packages"

#mopidy from pip
pip3 install --upgrade -r requirements.txt || die "Failed to install required Python packages"

if [ ! -f /usr/local/sbin/mopidyctl ]; then
    curl -o /usr/local/sbin/mopidyctl https://raw.githubusercontent.com/mopidy/mopidy/master/extra/mopidyctl/mopidyctl
    chmod +x /usr/local/sbin/mopidyctl
fi

declare -r SHAIRPORT_VERSION=3.2.2
wget https://github.com/mikebrady/shairport-sync/archive/${SHAIRPORT_VERSION}.zip || die "Failed to download shairport-sync"
unzip ${SHAIRPORT_VERSION}.zip && rm ${SHAIRPORT_VERSION}.zip || die "Failed to unpack ${SHAIRPORT_VERSION}.zip"
pushd shairport-sync-${SHAIRPORT_VERSION} || die "Failed to find shairport-sync-${SHAIRPORT_VERSION}"
autoreconf -i -f
./configure --sysconfdir=/etc --with-alsa --with-avahi --with-ssl=openssl --with-metadata --with-systemv || die "Failed to configure shairport-sync"
make && make install || die "Failed to build shairport-sync"
popd
rm -rf shairport-sync*

# Download and install Raspberry Pi Compatible ARMHF
declare -r LIBRESPOT_VERSION="v20180529-1e69138"
if [ ! -d /opt/librespot ]; then
    mkdir -p /opt/librespot || die "Failed to create /opt/librespot"
fi

pushd /opt/librespot || die "Failed to change to /opt/librespot"
wget https://github.com/pimusicbox/librespot/releases/download/${LIBRESPOT_VERSION}/librespot-linux-armhf-raspberry_pi.zip || die "Failed to download Raspberry Pi Compatible ARMHF"
unzip librespot-linux-armhf-raspberry_pi.zip || die "Failed to unpack librespot"
rm librespot-linux-armhf-raspberry_pi.zip
popd

# Install mpd-watchdog (#224)
if [ ! -f /usr/bin/mpd-watchdog ]; then
    curl -o /usr/bin/mpd-watchdog https://raw.githubusercontent.com/autostatic/mpd-watchdog/master/mpd-watchdog || die "Failed to download mpd-watchdog"
    chmod a+rx /usr/bin/mpd-watchdog
    curl -o /etc/init.d/mpd-watchdog https://raw.githubusercontent.com/autostatic/mpd-watchdog/master/debian/mpd-watchdog.init || die "Failed to download mpd-watchdog init file"
    systemctl enable mpd-watchdog || die "Failed to enable mpd-watchdog service"
fi

#**Configuration and Files**
cd filechanges || die "Failed to change to filechanges"

#Now we are going to copy some files. Backup the old ones if youâre not sure!
#This sets up the boot and opt directories:
#manually copy cmdline.txt and config.txt if you want
if [ ! -d /boot/config ]; then
    mkdir /boot/config || die "Failed to create /boot/config"
fi
cp -R boot/config /boot/config || die "Failed to copy config files"
cp -R opt/musicbox /opt/ || die "Failed to copy musicbox"

#Make the system work:
#cp -R etc/* /etc
declare -r timestamp=$(date +%FT%T)
if [ ! -d /etc/backup ]; then
    mkdir /etc/backup
fi
FILES="rc.local issue motd network/if-up.d/iptables firewall/musicbox_iptables sudoers default/avahi-daemon samba/smb.conf usbmount/usbmount.conf init.d/upmpdcli"
(cd /etc && tar -c -f /home/pi/etc-${timestamp}.tar --ignore-failed-read $FILES) || die "Failed to make backup of /etc"

for file in $FILES
do
    cp etc/$file /etc/ || die "Failed to install $file"
done

chmod +x /etc/network/if-up.d/iptables
chown root:root /etc/firewall/musicbox_iptables
chmod 600 /etc/firewall/musicbox_iptables

#Next, create a symlink from the package to the /opt/defaultwebclient.
ln -fsn /usr/local/lib/python2.7/dist-packages/mopidy_musicbox_webclient/static /opt/webclient
ln -fsn /usr/local/lib/python2.7/dist-packages/mopidy_moped/static /opt/moped
ln -fsn /opt/webclient /opt/defaultwebclient


#Let everyone shutdown the system (to support it from the webclient):
chmod u+s /sbin/shutdown

#**Add the mopidy user**
#Mopidy runs under the user mopidy. Add it.
if ! grep -q "mopidy" /etc/passwd
then
    useradd -m mopidy
    passwd -l mopidy
    #Add the user to the audio and video groups:
    usermod -a -G audio,video mopidy
fi

#Create a couple of directories inside the user dir:
mkdir -p /home/mopidy/.config/mopidy
mkdir -p /home/mopidy/.cache/mopidy
mkdir -p /home/mopidy/.local/share/mopidy
chown -R mopidy:mopidy /home/mopidy
chown -R mopidy:audio /var/cache/mopidy
chown -R mopidy:audio /var/lib/mopidy
chown -R mopidy:audio /var/log/mopidy
chown -R mopidy:audio /music/playlists

#**Create Music directory for MP3/OGG/FLAC **
#Create the directory containing the music and the one where the network share is mounted:
mkdir -p /music/MusicBox
mkdir -p /music/Network
mkdir -p /music/USB
mkdir -p /music/USB2
mkdir -p /music/USB3
mkdir -p /music/USB4
chmod -R 777 /music
chown -R mopidy:mopidy /music

#Disable the SSH service for more security if you want (it can be started with an option in the configuration-file):
#update-rc.d ssh disable

#Link the mopidy configuration to the new one in /boot/config
ln -fsn /boot/config/settings.ini /home/mopidy/.config/mopidy/mopidy.conf
mkdir -p /var/lib/mopidy/.config/mopidy
ln -fsn /boot/config/settings.ini /var/lib/mopidy/.config/mopidy/mopidy.conf

#**Optimizations**
rpi-update

#For the music to play without cracks, you have to optimize your system a bit.
#For MusicBox, these are the optimizations:

#**USB Fix**
#It's tricky to get good sound out of the Pi. For USB Audio (sound cards, etc),
# it is essential to disable the so called FIQ_SPLIT. Why? It seems that audio
# at high nitrates interferes with the ethernet activity, which also runs over USB.
# These options are added at the beginning of the cmdline.txt file in /boot
#sed -i '1s/^/dwc_otg.fiq_fix_enable=1 dwc_otg.fiq_split_enable=0 smsc95xx.turbo_mode=N /' /boot/cmdline.txt

declare -r MUSICBOX_SERVICES="dropbear upmpdcli shairport-sync mpd-watchdog"
for service in $MUSICBOX_SERVICES
do
    update-rc.d $service disable
done

#cleanup
apt-get autoremove --yes
#apt-get remove --yes build-essential python-pip
#apt-get clean
#apt-get autoclean

#other options to be done by hand. Won't do it automatically on a running system
