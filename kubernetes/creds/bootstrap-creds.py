#! python3
import json
import datetime
import uuid
import os

from cryptography import x509
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID


ca_info = { 'CN': 'LazyLamantin Test CA', 'ALTNAMES': [ 'DNS:lazylamantin.io' ] }

def main():
  clear_dir()
  ca_crt, ca_key = init_ca(ca_info)
  with open('roles.json') as f:
    roles = json.loads(f.read())
  roles_certs = create_certs(ca_crt, ca_key, roles)

def clear_dir():
  for filename in os.listdir():
    if (not filename.endswith('.conf')
    and not filename.endswith('.sh')
    and not filename.endswith('.py')
    and not filename.endswith('.json')):
      print('Delete', filename)
    
def init_ca(ca_info):
  one_day = datetime.timedelta(1, 0, 0)
  private_key = rsa.generate_private_key(
    public_exponent = 65537,
    key_size = 2048,
    backend = default_backend()
  )
  
  public_key = private_key.public_key()
  builder = x509.CertificateBuilder()
  builder = builder.subject_name(x509.Name([
    x509.NameAttribute(NameOID.COMMON_NAME, ca_info['CN']),
    x509.NameAttribute(NameOID.ORGANIZATION_NAME, ca_info['CN'].split(' ')[0])
  ]))
  builder = builder.issuer_name(x509.Name([
    x509.NameAttribute(NameOID.COMMON_NAME, ca_info['CN'])
  ]))
  
  builder = builder.not_valid_before(datetime.datetime.today() - one_day)
  builder = builder.not_valid_after(datetime.datetime.today() + one_day * 365 * 2)
  builder = builder.serial_number(int(x509.random_serial_number()))
  builder = builder.public_key(public_key)
  builder = builder.add_extension(
    x509.BasicConstraints(ca = True, path_length = None), critical = True
  )
  certificate = builder.sign(
    private_key = private_key,
    algorithm = hashes.SHA256(),
    backend = default_backend()
  )

  print(isinstance(certificate, x509.Certificate))

  with open(ca_info['CN'].split(' ')[0].lower() + '-key.pem', 'wb') as f:
    f.write(private_key.private_bytes(
      encoding = serialization.Encoding.PEM,
      format = serialization.PrivateFormat.TraditionalOpenSSL,
      encryption_algorithm = serialization.BestAvailableEncryption(b'belenot')
    ))
    
    with open(ca_info['CN'].split(' ')[0].lower() + '-crt.pem', 'wb') as f:
      f.write(certificate.public_bytes(encoding = serialization.Encoding.PEM))
  return certificate, private_key

def create_certs(a,b,c):
  pass
      
      
if __name__ == '__main__':
  main()
