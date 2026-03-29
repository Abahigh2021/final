cp /home/jack/upload-ex1.bash /home/jack/bin/upload-ex1.bash
cp /home/jack/upload-ex1.bash /home/jill/bin/upload-ex1.bash
cp /home/jack/upload-ex1.bash /home/tay/bin/upload-ex1.bash
cp /home/jack/upload-ex1.bash /home/aba-hadi/bin/upload-ex1.bash
Then fix ownership:


chown jack:jack /home/jack/bin/upload-ex1.bash
chown jill:jill /home/jill/bin/upload-ex1.bash
chown tay:tay /home/tay/bin/upload-ex1.bash
chown aba-hadi:aba-hadi /home/aba-hadi/bin/upload-ex1.bash
And permissions:


chmod 700 /home/*/bin/upload-ex1.bash
