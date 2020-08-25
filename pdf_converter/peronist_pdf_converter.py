from io import StringIO
from pdfminer.converter import TextConverter
from pdfminer.layout import LAParams
from pdfminer.pdfdocument import PDFDocument
from pdfminer.pdfinterp import PDFResourceManager, PDFPageInterpreter
from pdfminer.pdfpage import PDFPage
from pdfminer.pdfparser import PDFParser
import glob
import os
from tqdm import tqdm

DATA_PATH = './data/peronist_speeches/pdf/'

SAVE_DATA_PATH = './data/peronist_speeches/txt/'


def convert_pdf_to_string(file_path):

    output_string = StringIO()
    with open(file_path, 'rb') as in_file:
        parser = PDFParser(in_file)
        doc = PDFDocument(parser)
        rsrcmgr = PDFResourceManager()
        device = TextConverter(rsrcmgr, output_string, laparams=LAParams())
        interpreter = PDFPageInterpreter(rsrcmgr, device)
        for page in PDFPage.create_pages(doc):
            interpreter.process_page(page)

    return (output_string.getvalue())


def pdfs_to_txt():

    print('Started conversion of pdf files to txt')

    for file_path in tqdm(glob.glob(DATA_PATH+'*.pdf')):

        text = convert_pdf_to_string(file_path)

        saved_file_name = file_path.split('\\')[1].split('.')[0]

        with open(SAVE_DATA_PATH + saved_file_name + '.txt', 'wb') as f:

            f.write(text.encode("utf-8"))


if __name__ == '__main__':

    pdfs_to_txt()
