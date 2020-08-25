import requests
import urllib.request
from bs4 import BeautifulSoup
import unidecode
import logging
from tqdm import tqdm
import sys

logging.basicConfig(
    format="%(asctime)s %(levelname)s:%(name)s: %(message)s",
    level=logging.INFO,
    datefmt="%H:%M:%S",
    stream=sys.stderr,
)

logger = logging.getLogger("peronist_scraper")

logging.getLogger("chardet.charsetprober").disabled = True


URL = 'http://archivoperonista.com'

DATA_PATH = './data/peronist_speeches/pdf/'


def download_pdfs():

    page = requests.get(URL + '/discursos/')

    soup = BeautifulSoup(page.text, 'lxml')

    speeches_years_list = soup.find('ol', class_='anios').find_all('a')

    speeches_years_list = [a.text for a in speeches_years_list]

    logger.info(
        f'Speeches were found for the following years:\n{speeches_years_list}')

    for year in speeches_years_list:

        page = requests.get(URL + '/discursos/' + year)

        soup = BeautifulSoup(page.text, 'lxml')

        speeches_links = soup.find('ol', class_='archivo').find_all('li')

        speeches_links = [s.find('a')['href'] for s in speeches_links]

        logger.info(
            f'Downloading {len(speeches_links)} speeches for the year {year}')

        for i, speech_link in tqdm(enumerate(speeches_links)):

            page = requests.get(URL + speech_link)

            soup = BeautifulSoup(page.text, 'lxml')

            speaker = unidecode.unidecode(
                soup.find('div', class_='personaje').text)

            pdf_link = soup.find('div', class_='descarga').find('a')['href']

            response = requests.get(pdf_link)

            with open(f'{DATA_PATH}{year}_{speaker}_{i}.pdf', 'wb') as f:

                f.write(response.content)


if __name__ == '__main__':

    download_pdfs()
