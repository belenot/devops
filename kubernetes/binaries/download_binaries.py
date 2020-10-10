import urllib.request
import json
import logging
import os

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
ch = logging.StreamHandler()
ch.setLevel(logging.INFO)
formatter = formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)


def main():
    logger.info("Download binaries, if doesn't exists.")
    binaries_urls = json.load(open('binaries_urls.json'))
    for binary_url in binaries_urls:
        if os.path.isfile(binary_url['filename']):
            logger.info("Found file {}, skip downloading.".format(
                binary_url['filename']))
        else:
            logger.info("File {} not found, download.".format(
                binary_url['filename']))
            open(binary_url['filename'], mode='wb').write(
                urllib.request.urlopen(binary_url['url']).read())
            logger.info("File {} was downloaded.".format(
                binary_url['filename']))


if __name__ == '__main__':
    main()
