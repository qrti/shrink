# shrink

#### linux bash script to resize Raspberry SD card images

#### download  
download repository from GitHub,  
unzip and copy for example to: ~/shrink

**or**

copy script to current directory  
`wget https://raw.github.com/qrti/shrink/master/script/shrink.sh`

**or**

check if git is installed  
`$ git --version`

if git is not installed  
`$ sudo apt-get install git-all`

clone shrink repository to current directory  
`$ git clone https://github.com/qrti/shrink.git`

- - -

#### necessary installs  
`$ sudo apt-get update && sudo apt-get install dcfldd`  
`$ sudo apt-get update && sudo apt-get install gparted`

- - -

#### configure  
before executing the script, insert your SD card

enter the following at the command line and find the name of your SD device, there should be two entries, for example /dev/sdd1 and /dev/sdd2  
`$ df -h`

edit the script and enter your data between the quotation marks, for DEVICE omit the digit, so our example gets /dev/sdd, fill in your linux user name at USER  
`$ nano shrink.sh`
```
DEVICE=""                   # source and target SD card device
USER=""                     # linux user name
```

explore the top of the script to configure some more things

- - -

#### execute  
change directory  
`$ cd ~/shrink`

make script executable once  
`$ chmod 755 shrink.sh`

execute script  
`$ sudo ./shrink.sh`

- - -

#### remarks  
do not shrink images to minimum, otherwise they won't start on your Raspberry, especially Raspbian Full *Desktop* images need some extra space, about >= 250 MB are advised, Raspbian *Lite* images might be more moderate

when using the new SD card for the first time, expand the filesystem to fill its space and reboot

by raspi-config  
`sudo raspi-config`  
*Expand Filesystem*

**or**

from command line  
`sudo raspi-config --expand-rootfs`  
`sudo reboot`

the script is 'half automatic', meaning at one point it will start GParted on desktop and guide you what to do

the script was developed and tested on a VirtualBox Windows host with Linux Mint guest

inspired by  
http://www.aoakley.com/articles/2015-10-09-resizing-sd-images.php

- - -

#### copyright  
shrink is published under the terms of ISC license

Copyright (c) 2016 [qrt@qland.de](mailto:qrt@qland.de)

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED 'AS IS' AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
