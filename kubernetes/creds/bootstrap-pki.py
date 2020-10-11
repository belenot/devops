#! python3
import json
import datetime
import uuid
import os
import logging
import ipaddress

from cryptography import x509
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
ch = logging.StreamHandler()
ch.setLevel(logging.INFO)
formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)


def main():
    logger.info("Starting bootstraping creds")
    clear_dir()
    ca_info = json.loads(open('ca.json').read())
    ca_crt, ca_key = init_ca(ca_info)
    with open('roles.json') as f:
        roles = json.loads(f.read())
        logger.debug('Summary roles: \n%s', json.dumps(roles, indent=2))
    roles_certs = []
    for role in roles:
        role_cert = create_cert(
            ca_crt, ca_key, role['common_name'], role['subjectAltNames'])
        roles_certs.append(role_cert)


def clear_dir():
    logger.info("Clear directory from old creds")
    for filename in os.listdir():
        if (not filename.endswith('.conf')
            and not filename.endswith('.sh')
            and not filename.endswith('.py')
                and not filename.endswith('.json')):
            os.remove(filename)
            logger.info('Deleted ' + filename)


def init_ca(ca_info):
    logger.info('Init ca certificate and key for ' + json.dumps(ca_info))
    one_day = datetime.timedelta(1, 0, 0)
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
        backend=default_backend()
    )

    public_key = private_key.public_key()
    builder = x509.CertificateBuilder()
    builder = builder.subject_name(x509.Name([
        x509.NameAttribute(NameOID.COMMON_NAME, ca_info['common_name'])
    ]))
    builder = builder.issuer_name(x509.Name([
        x509.NameAttribute(NameOID.COMMON_NAME, ca_info['common_name'])
    ]))

    builder = builder.not_valid_before(datetime.datetime.today() - one_day)
    builder = builder.not_valid_after(
        datetime.datetime.today() + one_day * 365 * 2)
    builder = builder.serial_number(int(x509.random_serial_number()))
    builder = builder.public_key(public_key)
    builder = builder.add_extension(
        x509.BasicConstraints(ca=True, path_length=None), critical=True
    )
    builder = builder.add_extension(
        x509.KeyUsage(
            key_encipherment=True,
            key_cert_sign=True,
            crl_sign=True,
            digital_signature=True,
            content_commitment=True,
            data_encipherment=True,
            key_agreement=True,
            encipher_only=False,
            decipher_only=False
        ), critical=False
    )
    certificate = builder.sign(
        private_key=private_key,
        algorithm=hashes.SHA256(),
        backend=default_backend()
    )

    ca_key_filename = 'ca-key.pem'
    ca_crt_filename = 'ca-crt.pem'
    logger.info('Write %s certificate and key in %s %s',
                ca_info['common_name'], ca_crt_filename, ca_key_filename)

    with open(ca_key_filename, 'wb') as f:
        f.write(private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=serialization.NoEncryption()
        ))

    with open(ca_crt_filename, 'wb') as f:
        f.write(certificate.public_bytes(
            encoding=serialization.Encoding.PEM))

    logger.info('CA was successfuly generated')
    return certificate, private_key


def create_cert(ca_crt, ca_key, common_name, subjectAltNames):
    logger.info('Create certificate for %s with sans %s',
                common_name, ','.join(subjectAltNames))
    one_day = datetime.timedelta(1, 0, 0)
    issuer_name = ca_crt.issuer.get_attributes_for_oid(
        x509.name.NameOID.COMMON_NAME)[0].value
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
        backend=default_backend()
    )

    public_key = private_key.public_key()

    builder = x509.CertificateBuilder()
    builder = builder.subject_name(x509.Name([
        x509.NameAttribute(NameOID.COMMON_NAME, common_name),
    ]))
    builder = builder.issuer_name(x509.Name([
        x509.NameAttribute(NameOID.COMMON_NAME, issuer_name)
    ]))

    builder = builder.not_valid_before(datetime.datetime.today() - one_day)
    builder = builder.not_valid_after(
        datetime.datetime.today() + one_day * 365 * 1)
    builder = builder.serial_number(int(x509.random_serial_number()))
    builder = builder.public_key(public_key)
    builder = builder.add_extension(
        x509.BasicConstraints(ca=False, path_length=None), critical=True,
    )
    builder = builder.add_extension(
        x509.SubjectAlternativeName(
            [x509.DNSName(name) for name in subjectAltNames] +
            [x509.IPAddress(ipaddress.IPv4Address('127.0.0.1'))]
        ),
        critical=True
    )
    builder = builder.add_extension(
        x509.ExtendedKeyUsage([
            x509.oid.ExtendedKeyUsageOID.CLIENT_AUTH,
            x509.oid.ExtendedKeyUsageOID.SERVER_AUTH,
        ]), critical=False
    )
    certificate = builder.sign(
        private_key=ca_key,
        algorithm=hashes.SHA256(),
        backend=default_backend()
    )

    ca_key_filename = common_name.split(' ')[0].lower() + '-key.pem'
    ca_crt_filename = common_name.split(' ')[0].lower() + '-crt.pem'
    logger.info('Write %s certificate and key in %s %s',
                common_name, ca_crt_filename, ca_key_filename)

    with open(ca_key_filename, 'wb') as f:
        f.write(private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=serialization.NoEncryption()
        ))

    with open(ca_crt_filename, 'wb') as f:
        f.write(certificate.public_bytes(
            encoding=serialization.Encoding.PEM))
    return certificate, private_key


if __name__ == '__main__':
    main()
