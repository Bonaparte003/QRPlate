import qrcode
from django.conf import settings

def generate_qr_code(user_profile):
    # Get the URL with the qr_code_id for this user
    url = f"{settings.BASE_URL}/scan/{user_profile.qr_code_id}/"
    
    # Generate QR code image
    img = qrcode.make(url)
    
    return img
