import base64
import os
import json
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
ch = logging.StreamHandler()
ch.setLevel(logging.INFO)
formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)


def main():
    logger.info("Create kubeconfigs for roles.")
    ca = open('ca-crt.pem').read()
    roles = json.loads(open('roles.json').read())
    kubernetes_public_address = 'https://k8s-master:6443'
    logger.info("Ca file ca-crt.pem.")
    logger.info("Kubernetes public address {}.".format(
        kubernetes_public_address))
    for role in roles:
        logger.info('Create {}.kubeconfig'.format(role['common_name']))
        certificate = open(role['common_name'] + '-crt.pem').read()
        key = open(role['common_name'] + '-key.pem').read()
        name = role['common_name']
        kubeconfig = create_kubeconfig(
            ca, certificate, key, name, kubernetes_public_address)
        open(name + '.kubeconfig', mode='w').write(json.dumps(kubeconfig, indent=2))
    encryption_config = create_encryption_config()
    open('encryption-config.json', mode='w').write(json.dumps(encryption_config))
    logger.info('Wrote to encryption-config.json')


def create_kubeconfig(ca, certificate, key, name, kubernetes_public_address):
    return {
        'apiVersion': 'v1',
        'clusters': [
            {
                'cluster': {
                    'certificate-authority-data': str(base64.b64encode(bytes(ca, encoding='utf-8')), encoding='utf-8'),
                    'server': kubernetes_public_address
                },
                'name': 'kubernetes'
            }
        ],
        'contexts': [
            {
                'context': {
                    'cluster': 'kubernetes',
                    'user': name
                },
                'name': 'default'
            }
        ],
        'current-context': 'default',
        'kind': 'Config',
        'preferences': {},
        'users': [
            {
                'name': 'system:node:node-1',
                'user': {
                    'client-certificate-data': str(base64.b64encode(bytes(certificate, encoding='utf-8')), encoding='utf-8'),
                    'client-key-data': str(base64.b64encode(bytes(key, encoding='utf-8')), encoding='utf-8')
                }
            }
        ]
    }


def create_encryption_config():
    return {
        'kind': 'EncryptionConfig',
        'apiVersion': 'v1',
        'resources': [
            {
                'resources': [
                    'secrets'
                ],
                'providers': [
                    {
                        'aescbc': {
                            'keys': [
                                {
                                    'name': 'key1',
                                    'secret': str(base64.b64encode(os.urandom(32)), encoding='utf-8')
                                }
                            ]
                        },
                    },
                    {
                        'identity': {}
                    }
                ]
            }
        ]
    }


if __name__ == '__main__':
    main()
