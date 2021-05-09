#linux tesseract
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-tesseract.sh && wget --no-cache https://raw.staticdn.net/share-group/shell/master/install-tesseract.sh && sh install-tesseract.sh

yum install -y gcc-c++ tesseract tesseract-langpack-deu tesseract-osd tesseract-langpack-chi_sim tesseract-langpack-chi_tra

tesseract -v