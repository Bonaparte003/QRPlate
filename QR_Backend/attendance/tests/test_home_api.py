import django
import requests
from django.conf import settings

# Initialize Django
django.setup()

VERIFY_OTP_URL = f"{settings.BASE_URL}/api/verify-otp/"
HOME_API_URL = f"{settings.BASE_URL}/api/home/"

def test_home_api():
    # Step 1: Verify OTP and obtain session cookies
    otp_data = {
        "otp": "767430"  # Replace with a valid OTP
    }
    
    # Send a POST request to verify the OTP
    otp_response = requests.post(VERIFY_OTP_URL, json=otp_data)
    assert otp_response.status_code == 200, f"OTP verification failed: {otp_response.json()}"
    
    # Get the session cookies from the response
    session_cookies = otp_response.cookies

    # Step 2: Access the home API using the session cookies
    session = requests.Session()
    session.cookies.update(session_cookies)

    # Send a GET request to the home API
    home_response = session.get(HOME_API_URL)
    
    # Check if the home API call was successful
    assert home_response.status_code == 200, f"Home API failed: {home_response.json()}"
    response_data = home_response.json()
    
    # Verify the expected keys in the response
    assert 'qr_code' in response_data, "QR code is missing in the response"
    assert 'qr_code_url' in response_data, "QR code URL is missing in the response"
    assert 'user_profile' in response_data, "User profile is missing in the response"

    print("Test passed successfully!")
