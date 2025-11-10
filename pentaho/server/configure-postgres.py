#!/usr/bin/env python3
"""
Pentaho Server PostgreSQL Configuration Script

Automatically configures Pentaho Server to use PostgreSQL instead of HSQLDB.
Modifies:
- repository.xml (Jackrabbit JCR)
- quartz.properties (Scheduler)
- hibernate-settings.xml (Repository)
"""

import sys
import os
import shutil
from pathlib import Path
from lxml import etree
import argparse

# Default PostgreSQL connection settings
DEFAULT_CONFIG = {
    'host': 'localhost',
    'port': '5432',
    'hibernate_db': 'hibernate',
    'hibernate_user': 'hibuser',
    'hibernate_pass': 'password',
    'jackrabbit_db': 'jackrabbit',
    'jackrabbit_user': 'jcr_user',
    'jackrabbit_pass': 'password',
    'quartz_db': 'quartz',
    'quartz_user': 'pentaho_user',
    'quartz_pass': 'password',
}


def backup_file(filepath):
    """Create a backup of the original file"""
    backup = f"{filepath}.bak"
    if not os.path.exists(backup):
        shutil.copy2(filepath, backup)
        print(f"✓ Backed up: {os.path.basename(filepath)}")


def configure_jackrabbit(server_path, config):
    """Configure Jackrabbit repository.xml for PostgreSQL"""
    repo_xml = os.path.join(
        server_path,
        'pentaho-solutions/system/jackrabbit/repository.xml'
    )
    
    if not os.path.exists(repo_xml):
        print(f"✗ Not found: {repo_xml}")
        return False
    
    backup_file(repo_xml)
    
    # Parse XML
    parser = etree.XMLParser(remove_blank_text=False)
    tree = etree.parse(repo_xml, parser)
    root = tree.getroot()
    
    # Find Workspace and Versioning DataSource configurations
    # The repository.xml uses a specific namespace
    ns = {'jr': 'http://www.apache.org/jackrabbit/repository'}
    
    # Update Workspace DataSource
    workspace_ds = root.find('.//Workspace/FileSystem[@class="org.apache.jackrabbit.core.fs.db.DbFileSystem"]', ns)
    if workspace_ds is not None:
        # Update to PostgreSQL driver
        for param in workspace_ds.findall('param'):
            name = param.get('name')
            if name == 'driver':
                param.set('value', 'org.postgresql.Driver')
            elif name == 'url':
                param.set('value', f"jdbc:postgresql://{config['host']}:{config['port']}/{config['jackrabbit_db']}")
            elif name == 'user':
                param.set('value', config['jackrabbit_user'])
            elif name == 'password':
                param.set('value', config['jackrabbit_pass'])
    
    # Update Workspace PersistenceManager
    workspace_pm = root.find('.//Workspace/PersistenceManager[@class="org.apache.jackrabbit.core.persistence.pool.PostgreSQLPersistenceManager"]', ns)
    if workspace_pm is None:
        # Need to change the class attribute
        workspace_pm = root.find('.//Workspace/PersistenceManager', ns)
        if workspace_pm is not None:
            workspace_pm.set('class', 'org.apache.jackrabbit.core.persistence.pool.PostgreSQLPersistenceManager')
    
    if workspace_pm is not None:
        for param in workspace_pm.findall('param'):
            name = param.get('name')
            if name == 'url':
                param.set('value', f"jdbc:postgresql://{config['host']}:{config['port']}/{config['jackrabbit_db']}")
            elif name == 'user':
                param.set('value', config['jackrabbit_user'])
            elif name == 'password':
                param.set('value', config['jackrabbit_pass'])
            elif name == 'driver':
                param.set('value', 'org.postgresql.Driver')
            elif name == 'databaseType':
                param.set('value', 'postgresql')
    
    # Similar updates for Versioning section
    versioning_ds = root.find('.//Versioning/FileSystem[@class="org.apache.jackrabbit.core.fs.db.DbFileSystem"]', ns)
    if versioning_ds is not None:
        for param in versioning_ds.findall('param'):
            name = param.get('name')
            if name == 'driver':
                param.set('value', 'org.postgresql.Driver')
            elif name == 'url':
                param.set('value', f"jdbc:postgresql://{config['host']}:{config['port']}/{config['jackrabbit_db']}")
            elif name == 'user':
                param.set('value', config['jackrabbit_user'])
            elif name == 'password':
                param.set('value', config['jackrabbit_pass'])
    
    versioning_pm = root.find('.//Versioning/PersistenceManager', ns)
    if versioning_pm is not None:
        versioning_pm.set('class', 'org.apache.jackrabbit.core.persistence.pool.PostgreSQLPersistenceManager')
        for param in versioning_pm.findall('param'):
            name = param.get('name')
            if name == 'url':
                param.set('value', f"jdbc:postgresql://{config['host']}:{config['port']}/{config['jackrabbit_db']}")
            elif name == 'user':
                param.set('value', config['jackrabbit_user'])
            elif name == 'password':
                param.set('value', config['jackrabbit_pass'])
            elif name == 'driver':
                param.set('value', 'org.postgresql.Driver')
            elif name == 'databaseType':
                param.set('value', 'postgresql')
    
    # Write back
    tree.write(repo_xml, encoding='UTF-8', xml_declaration=True, pretty_print=True)
    print(f"✓ Configured: repository.xml")
    return True


def configure_quartz(server_path, config):
    """Configure Quartz quartz.properties for PostgreSQL"""
    quartz_props = os.path.join(
        server_path,
        'pentaho-solutions/system/quartz/quartz.properties'
    )
    
    # Try alternate location if not found
    if not os.path.exists(quartz_props):
        quartz_props = os.path.join(
            server_path,
            'pentaho-solutions/system/scheduler-plugin/quartz/quartz.properties'
        )
    
    if not os.path.exists(quartz_props):
        print(f"✗ Not found: {quartz_props}")
        return False
    
    backup_file(quartz_props)
    
    # Read properties file
    with open(quartz_props, 'r') as f:
        lines = f.readlines()
    
    # Update properties
    new_lines = []
    for line in lines:
        stripped = line.strip()
        
        # Comment out HSQLDB driver
        if stripped.startswith('org.quartz.dataSource.myDS.driver') and 'hsqldb' in stripped.lower():
            new_lines.append(f"#{line}")
            new_lines.append(f"org.quartz.dataSource.myDS.driver = org.postgresql.Driver\n")
        # Comment out HSQLDB URL
        elif stripped.startswith('org.quartz.dataSource.myDS.URL') and 'hsqldb' in stripped.lower():
            new_lines.append(f"#{line}")
            new_lines.append(f"org.quartz.dataSource.myDS.URL = jdbc:postgresql://{config['host']}:{config['port']}/{config['quartz_db']}\n")
        # Update user
        elif stripped.startswith('org.quartz.dataSource.myDS.user'):
            new_lines.append(f"org.quartz.dataSource.myDS.user = {config['quartz_user']}\n")
        # Update password
        elif stripped.startswith('org.quartz.dataSource.myDS.password'):
            new_lines.append(f"org.quartz.dataSource.myDS.password = {config['quartz_pass']}\n")
        # Comment out HSQLDB delegate
        elif stripped.startswith('org.quartz.jobStore.driverDelegateClass') and 'HSQL' in stripped:
            new_lines.append(f"#{line}")
            new_lines.append(f"org.quartz.jobStore.driverDelegateClass = org.quartz.impl.jdbcjobstore.PostgreSQLDelegate\n")
        else:
            new_lines.append(line)
    
    # Write back
    with open(quartz_props, 'w') as f:
        f.writelines(new_lines)
    
    print(f"✓ Configured: quartz.properties")
    return True


def configure_hibernate(server_path, config):
    """Configure Hibernate hibernate-settings.xml for PostgreSQL"""
    hibernate_settings = os.path.join(
        server_path,
        'pentaho-solutions/system/hibernate/hibernate-settings.xml'
    )
    
    if not os.path.exists(hibernate_settings):
        print(f"✗ Not found: {hibernate_settings}")
        return False
    
    backup_file(hibernate_settings)
    
    # Parse XML
    parser = etree.XMLParser(remove_blank_text=False)
    tree = etree.parse(hibernate_settings, parser)
    root = tree.getroot()
    
    # Find the config-file element and change it to postgresql
    config_file = root.find('.//config-file')
    if config_file is not None:
        config_file.text = 'system/hibernate/postgresql.hibernate.cfg.xml'
        print(f"✓ Configured: hibernate-settings.xml")
    
    # Write back
    tree.write(hibernate_settings, encoding='UTF-8', xml_declaration=True, pretty_print=True)
    
    # Now update the postgresql.hibernate.cfg.xml with credentials
    pg_hibernate = os.path.join(
        server_path,
        'pentaho-solutions/system/hibernate/postgresql.hibernate.cfg.xml'
    )
    
    if os.path.exists(pg_hibernate):
        backup_file(pg_hibernate)
        tree = etree.parse(pg_hibernate, parser)
        root = tree.getroot()
        
        # Find session-factory and update properties
        for prop in root.findall('.//property'):
            name = prop.get('name')
            if name == 'connection.url':
                prop.text = f"jdbc:postgresql://{config['host']}:{config['port']}/{config['hibernate_db']}"
            elif name == 'connection.username':
                prop.text = config['hibernate_user']
            elif name == 'connection.password':
                prop.text = config['hibernate_pass']
            elif name == 'connection.driver_class':
                prop.text = 'org.postgresql.Driver'
        
        tree.write(pg_hibernate, encoding='UTF-8', xml_declaration=True, pretty_print=True)
        print(f"✓ Configured: postgresql.hibernate.cfg.xml")
    
    return True


def main():
    parser = argparse.ArgumentParser(
        description='Configure Pentaho Server to use PostgreSQL'
    )
    parser.add_argument(
        'server_path',
        help='Path to pentaho-server directory'
    )
    parser.add_argument(
        '--host',
        default=DEFAULT_CONFIG['host'],
        help='PostgreSQL host (default: localhost)'
    )
    parser.add_argument(
        '--port',
        default=DEFAULT_CONFIG['port'],
        help='PostgreSQL port (default: 5432)'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be changed without modifying files'
    )
    
    args = parser.parse_args()
    
    if not os.path.isdir(args.server_path):
        print(f"Error: Server path not found: {args.server_path}")
        return 1
    
    # Update config with command line args
    config = DEFAULT_CONFIG.copy()
    config['host'] = args.host
    config['port'] = args.port
    
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("Pentaho Server PostgreSQL Configuration")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print(f"Server: {args.server_path}")
    print(f"PostgreSQL: {config['host']}:{config['port']}")
    print()
    
    if args.dry_run:
        print("DRY-RUN MODE - No files will be modified")
        print()
        return 0
    
    success = True
    
    # Configure each component
    print("Configuring Jackrabbit (JCR)...")
    if not configure_jackrabbit(args.server_path, config):
        success = False
    
    print("\nConfiguring Quartz (Scheduler)...")
    if not configure_quartz(args.server_path, config):
        success = False
    
    print("\nConfiguring Hibernate (Repository)...")
    if not configure_hibernate(args.server_path, config):
        success = False
    
    print()
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    if success:
        print("✓ Configuration complete!")
        print()
        print("IMPORTANT: You must restart Pentaho Server for changes to take effect")
        print()
        print("Backup files created with .bak extension")
        print("To restore original configuration, copy .bak files back")
    else:
        print("✗ Configuration failed - check errors above")
        return 1
    
    return 0


if __name__ == '__main__':
    sys.exit(main())
