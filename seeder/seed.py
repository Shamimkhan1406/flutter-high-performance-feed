import os
import io

from dotenv import load_dotenv
from PIL import Image
from supabase import create_client

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SECRET_KEY")
BUCKET_NAME = os.getenv("BUCKET_NAME", "media")

supabase = create_client(
    SUPABASE_URL,
    SUPABASE_KEY,
)

INPUT_DIR = "input_images"


def upload_to_storage(path, file_bytes):
    try:
        supabase.storage.from_(BUCKET_NAME).upload(
            path,
            file_bytes,
            {
                "content-type": "image/webp"
            },
        )
        print(f"Uploaded: {path}")
    except Exception:
        print(f"Skipping {path} (already exists)")


def process_and_upload():
    if not os.path.exists(INPUT_DIR):
        print(f"Folder '{INPUT_DIR}' not found.")
        return

    image_files = [
        f for f in os.listdir(INPUT_DIR)
        if f.lower().endswith(
            (".png", ".jpg", ".jpeg", ".webp")
        )
    ]

    if not image_files:
        print("No images found.")
        return

    for filename in image_files:
        filepath = os.path.join(
            INPUT_DIR,
            filename,
        )

        base_name = os.path.splitext(
            filename
        )[0]

        print(f"\nProcessing {filename}")

        with Image.open(filepath) as img:

            # RAW
            raw_bytes = io.BytesIO()
            img.save(
                raw_bytes,
                format=img.format,
            )

            raw_path = (
                f"{base_name}_raw."
                f"{img.format.lower()}"
            )

            # MOBILE
            mobile_img = img.copy()
            mobile_img.thumbnail(
                (1080, 1080),
                Image.Resampling.LANCZOS,
            )

            mobile_bytes = io.BytesIO()

            mobile_img.save(
                mobile_bytes,
                format="WEBP",
                quality=80,
            )

            mobile_path = (
                f"{base_name}_mobile.webp"
            )

            # THUMB
            thumb_img = img.copy()

            thumb_img.thumbnail(
                (300, 300),
                Image.Resampling.LANCZOS,
            )

            thumb_bytes = io.BytesIO()

            thumb_img.save(
                thumb_bytes,
                format="WEBP",
                quality=70,
            )

            thumb_path = (
                f"{base_name}_thumb.webp"
            )

            upload_to_storage(
                raw_path,
                raw_bytes.getvalue(),
            )

            upload_to_storage(
                mobile_path,
                mobile_bytes.getvalue(),
            )

            upload_to_storage(
                thumb_path,
                thumb_bytes.getvalue(),
            )

            raw_url = (
                supabase.storage
                .from_(BUCKET_NAME)
                .get_public_url(raw_path)
            )

            mobile_url = (
                supabase.storage
                .from_(BUCKET_NAME)
                .get_public_url(mobile_path)
            )

            thumb_url = (
                supabase.storage
                .from_(BUCKET_NAME)
                .get_public_url(thumb_path)
            )

            supabase.table("posts").insert({
                "media_thumb_url": thumb_url,
                "media_mobile_url": mobile_url,
                "media_raw_url": raw_url,
            }).execute()

            print(
                f"Seeded {filename}"
            )

    print("\nDone!")


if __name__ == "__main__":
    process_and_upload()