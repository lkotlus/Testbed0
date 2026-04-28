#!/bin/bash 

cp /bin/bash /tmp/bash
chown root:root /tmp/bash
chmod 4755 /tmp/bash

echo "dta_flag{5b825933-f75e-46ed-a305-b25458460e63}" > /root/flag.txt
