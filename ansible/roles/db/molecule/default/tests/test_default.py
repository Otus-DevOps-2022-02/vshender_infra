import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']
).get_hosts('all')


def test_mongo_running_and_enabled(host):
    """Check if MongoDB is enabled and running."""

    mongo = host.service('mongod')
    assert mongo.is_running
    assert mongo.is_enabled


def test_mongo_access(host):
    """Check if MongoDB is available on port 27017."""

    addr = host.addr('localhost')
    assert addr.port(27017).is_reachable


def test_config_file(host):
    """Check if configuration file contains the required line."""

    config_file = host.file('/etc/mongod.conf')
    assert config_file.is_file
    assert config_file.contains('bindIp: 0.0.0.0')
