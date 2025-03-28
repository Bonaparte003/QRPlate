from django import template
import base64

register = template.Library()

@register.filter
def base64encode(value):
    """Convert bytes to base64-encoded string."""
    return base64.b64encode(value).decode('utf-8')
