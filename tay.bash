echo "unsafe from tay" > tay-unsafe-kali.txt
chmod 666 tay-unsafe-kali.txt
upload-file.bash tay-unsafe-kali.txt


echo "safe from tay" > tay-safe-kali.txt
chmod 660 tay-safe-kali.txt
upload-file.bash tay-safe-kali.txt
