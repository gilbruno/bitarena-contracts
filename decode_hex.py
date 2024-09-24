# decode_hex.py
import sys
from eth_utils import decode_hex, to_text

# La valeur hexadécimale renvoyée par getGame
hex_value = sys.argv[1]

# Décoder la valeur hexadécimale
decoded_bytes = decode_hex(hex_value)

# Extraire la chaîne de caractères
# La chaîne commence après les 64 premiers octets (32 octets pour le décalage et 32 octets pour la longueur)
string_length = int.from_bytes(decoded_bytes[32:64], byteorder='big')
raw_string = to_text(decoded_bytes[64:64 + string_length])

print(raw_string)