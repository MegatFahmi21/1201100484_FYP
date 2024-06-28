import selenium
from selenium import webdriver
import time
import requests
import os
from PIL import Image
import hashlib
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.service import Service

# This is the path to the ChromeDriver executable
# DRIVER_PATH = "chromedriver.exe"

def fetch_image_urls(query:str, max_links_to_fetch:int, wd:webdriver, sleep_between_interactions:int=1):
    def scroll_to_end(wd):
        wd.execute_script("window.scrollTo(0, document.body.scrollHeight);")
        time.sleep(sleep_between_interactions)
    
    # Build the Google query
    search_url = "https://www.google.com/search?safe=off&site=&tbm=isch&source=hp&q={q}&oq={q}&gs_l=img"

    # Load the page
    wd.get(search_url.format(q=query))

    image_urls = set()
    image_count = 0
    results_start = 0
    while image_count < max_links_to_fetch:
        scroll_to_end(wd)

        # Get all image thumbnail results
        thumbnail_results = wd.find_elements(By.CSS_SELECTOR, "img.rg_i.Q4LuWd")
        number_results = len(thumbnail_results)
        
        # ...

        for img in thumbnail_results[results_start:number_results]:
            try:
                img.click()
                time.sleep(sleep_between_interactions)
            except Exception:
                continue

            # Wait for the larger image to load and extract its URLs
            try:
                large_images = WebDriverWait(wd, 10).until(
                    EC.presence_of_all_elements_located((By.CSS_SELECTOR, "img.sFlh5c"))
                )
                for actual_image in large_images:
                    if actual_image.get_attribute('src') and 'http' in actual_image.get_attribute('src'):
                        image_urls.add(actual_image.get_attribute('src'))
            except Exception as e:
                print("Error - Could not load large image -", e)
                continue

            image_count = len(image_urls)

            if len(image_urls) >= max_links_to_fetch:
                print(f"Found: {len(image_urls)} image links, done!")
                break
        else:
            print("Found:", len(image_urls), "image links, looking for more ...")
            time.sleep(30)
            return
            # load_more_button = wd.find_element_by_css_selector(".mye4qd")
            # if load_more_button:
            #     wd.execute_script("document.querySelector('.mye4qd').click();")

        # Move the result startpoint further down
        results_start = len(thumbnail_results)

    return image_urls

def persist_image(folder_path:str, file_name:str, url:str):
    try:
        image_content = requests.get(url).content

    except Exception as e:
        print(f"ERROR - Could not download {url} - {e}")

    try:
        hash_code = hashlib.sha1(image_content).hexdigest()[:10]
        file_path = os.path.join(folder_path, file_name.replace(' ', '_') + '_' + hash_code + '.jpg')

        if not os.path.exists(folder_path):
            os.makedirs(folder_path)

        with open(file_path, 'wb') as f:
            f.write(image_content)
        print(f"SUCCESS - saved {url} - as {file_path}")
    except Exception as e:
        print(f"ERROR - Could not save {url} - {e}")

    # try:
    #     image_file = io.BytesIO(image_content)
    #     image = Image.open(image_file).convert('RGB')
    #     folder_path = os.path.join(folder_path, file_name)
    #     if os.path.exists(folder_path):
    #         file_path = os.path.join(folder_path, hashlib.sha1(image_content).hexdigest()[:10] + '.jpg')
    #     else:
    #         os.mkdir(folder_path)
    #         file_path = os.path.join(folder_path, hashlib.sha1(image_content).hexdigest()[:10] + '.jpg')
    #     with open(file_path, 'wb') as f:
    #         image.save(f, "JPEG", quality=85)
    #     print(f"SUCCESS - saved {url} - as {file_path}")
    # except Exception as e:
        # print(f"ERROR - Could not save {url} - {e}")

if __name__ == '__main__':
    wd = webdriver.Chrome(service=Service(ChromeDriverManager().install()))

    # Path to the folder where the images will be saved
    images_path = 'C:/Users/Megat/Downloads/DownloadImages/images'
    
    # List of queries for 30 different fruits with "ripe", "unripe", and "rotten" conditions
    queries = [
    # "ripe apple fruit",
    # "unripe apple fruit",
    # "rotten apple fruit",
    # "ripe banana fruit",
    # "unripe banana fruit",
    # "rotten banana fruit",
    # "ripe orange fruit",
    # "unripe orange fruit",
    # "rotten orange fruit",
    # "ripe strawberry fruit",
    # "unripe strawberry fruit",
    # "rotten strawberry fruit",
    # "ripe pineapple fruit",
    # "unripe pineapple fruit",
    # "rotten pineapple fruit",
    # "ripe mango fruit",
    # "unripe mango fruit",
    # "rotten mango fruit",
    #"ripe grapes ",
    #"unripe grapes",
    #"rotten grapes",
    # "ripe watermelon fruit",
    # "unripe watermelon fruit",
    # "rotten watermelon fruit",
    # "ripe peach fruit",
    # "unripe peach fruit",
    # "rotten peach fruit",
    # "ripe pear fruit",
    # "unripe pear fruit",
    # "rotten pear fruit",
    # "ripe kiwi fruit",
    # "unripe kiwi fruit",
    # "rotten kiwi fruit",
    # "ripe cherry fruit",
    # "unripe cherry fruit",
    # "rotten cherry fruit",
    # "ripe mangosteen fruit",
    # "unripe mangosteen fruit",
    # "rotten mangosteen fruit",
    # "ripe durian fruit",
    # "unripe durian fruit",
    # "rotten durian fruit",
    # "ripe lychee fruit",
    # "unripe lychee fruit",
    # "rotten lychee fruit",
    # "ripe passionfruit fruit",
    # "unripe passionfruit fruit",
    # "rotten passionfruit fruit",
    # "ripe dragonfruit",
    # "unripe dragonfruit",
    # "rotten dragonfruit",
    # "ripe avacado fruit",
    # "unripe avacado fruit",
    # "rotten avacado fruit",
    # "ripe rambutan fruit",
    # "unripe rambutan fruit",
    # "rotten rambutan fruit",
    # "ripe honeydew fruit",
    # "unripe honeydew fruit",
    # "rotten honeydew fruit",
    # "ripe starfruit",
    # "unripe starfruit",
    # "rotten starfruit",
    # "ripe longan fruit",
    # "unripe longan fruit",
     "rotten longan fruit",
    # "ripe jackfruit",
    # "unripe jackfruit",
    # "rotten jackfruit",
]

    
    for query in queries:
        wd.get('https://google.com')

        # Get the search box element
        search_box = WebDriverWait(wd, 10).until(EC.presence_of_element_located((By.NAME, 'q')))
        search_box.send_keys(query)

        # Condition
        condition = query.split()[0]
        # Fruit name
        fruit_name = query.split()[1]
        # Combine the condition and fruit name to form the folder path
        folder_path = os.path.join(images_path, condition + ' ' + fruit_name)

        links = fetch_image_urls(query, 110, wd)

        for i in links:
            persist_image(folder_path, query, i)
    wd.quit()
