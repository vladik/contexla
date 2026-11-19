<?php

declare(strict_types=1);

/**
 * Read-only Drupal snapshot collector spike.
 *
 * Run from a fully bootstrapped Drush `php:script` command. The script reads
 * metadata through public Drupal services and writes a Contexla evidence ZIP.
 */

use Drupal\Core\Field\FieldDefinitionInterface;

if (!class_exists(Drupal::class) || !defined('DRUPAL_ROOT')) {
    throw new RuntimeException('Run this collector through a bootstrapped Drush php:script command.');
}

$projectRoot = dirname(DRUPAL_ROOT);
$outputRoot = getenv('CONTEXLA_OUTPUT_DIR') ?: $projectRoot . '/.contexla-snapshots';
$installationId = getenv('CONTEXLA_INSTALLATION_ID') ?: 'local-drupal-11';
$environment = getenv('CONTEXLA_ENVIRONMENT') ?: 'local';
$createdAt = gmdate('Y-m-d\TH:i:s\Z');
$stamp = gmdate('Ymd-His');
$packageId = cx_safe_id($installationId) . '-' . $stamp;
$workDir = $outputRoot . '/' . $packageId;
$sourcesDir = $workDir . '/sources';

cx_ensure_directory($sourcesDir);

$documents = [
    'sources/drupal-status.json' => [
        'kind' => 'drupal.system',
        'data' => cx_drupal_status($installationId, $environment),
    ],
    'sources/modules.json' => [
        'kind' => 'drupal.modules',
        'data' => cx_extensions('module'),
    ],
    'sources/themes.json' => [
        'kind' => 'drupal.themes',
        'data' => cx_extensions('theme'),
    ],
    'sources/sites.json' => [
        'kind' => 'drupal.sites',
        'data' => cx_sites($installationId),
    ],
    'sources/content-types.json' => [
        'kind' => 'drupal.content_model',
        'data' => cx_content_types(),
    ],
    'sources/fields.json' => [
        'kind' => 'drupal.content_model',
        'data' => cx_fields(),
    ],
    'sources/views.json' => [
        'kind' => 'drupal.configuration',
        'data' => cx_config_entities('views.view.', 'views'),
    ],
    'sources/workflows.json' => [
        'kind' => 'drupal.configuration',
        'data' => cx_config_entities('workflows.workflow.', 'workflows'),
    ],
    'sources/roles-summary.json' => [
        'kind' => 'drupal.configuration',
        'data' => cx_role_summaries(),
    ],
    'sources/content-counts.json' => [
        'kind' => 'drupal.content_counts',
        'data' => cx_bundle_counts('node', 'node_type'),
    ],
    'sources/media-counts.json' => [
        'kind' => 'drupal.media_counts',
        'data' => cx_bundle_counts('media', 'media_type'),
    ],
    'sources/cron.json' => [
        'kind' => 'drupal.scheduled_work',
        'data' => cx_cron(),
    ],
];

foreach (['composer.json', 'composer.lock'] as $composerFile) {
    $sourcePath = $projectRoot . '/' . $composerFile;
    if (is_file($sourcePath)) {
        $documents['sources/' . $composerFile] = [
            'kind' => $composerFile === 'composer.json' ? 'composer.manifest' : 'composer.lock',
            'body' => (string) file_get_contents($sourcePath),
        ];
    }
}

ksort($documents, SORT_STRING);
$declarations = [];

foreach ($documents as $relativePath => $document) {
    $body = array_key_exists('body', $document)
        ? $document['body']
        : cx_json($document['data']);

    $absolutePath = $workDir . '/' . $relativePath;
    cx_ensure_directory(dirname($absolutePath));
    cx_write($absolutePath, $body);

    $declarations[] = [
        'path' => $relativePath,
        'kind' => $document['kind'],
        'media_type' => 'application/json',
        'sha256' => hash('sha256', $body),
        'bytes' => strlen($body),
        'collected_at' => $createdAt,
        'contains_secrets' => false,
        'classification' => 'internal',
    ];
}

$manifest = [
    'contract' => 'contexla.estate-evidence-package',
    'version' => '1.0',
    'profile' => [
        'id' => 'contexla.drupal-snapshot',
        'version' => '1.0',
    ],
    'package_id' => $packageId,
    'created_at' => $createdAt,
    'producer' => [
        'type' => 'drush-script',
        'name' => 'contexla-drupal-snapshot',
        'version' => '0.1.0-spike',
    ],
    'source' => [
        'system' => 'drupal',
        'installation_id' => $installationId,
        'environments' => [$environment],
    ],
    'collection' => [
        'mode' => 'local_read_only_collector',
        'started_at' => $createdAt,
        'completed_at' => $createdAt,
        'limitations' => [
            'Content field values were not collected.',
            'Infrastructure topology and external-system ownership were not collected.',
            'Configuration values were not exported.',
        ],
    ],
    'classification' => 'internal',
    'files' => $declarations,
];

cx_write($workDir . '/manifest.json', cx_json($manifest));

$zipPath = $outputRoot . '/' . $packageId . '.zip';
cx_zip($zipPath, $workDir, array_merge(['manifest.json'], array_keys($documents)));

fwrite(STDOUT, $zipPath . PHP_EOL);

function cx_drupal_status(string $installationId, string $environment): array
{
    $database = Drupal::database();
    $databaseVersion = null;

    try {
        $databaseVersion = (string) $database->query('SELECT VERSION()')->fetchField();
    } catch (Throwable) {
        // A missing database version is represented as unknown, not fabricated.
    }

    return [
        'id' => $installationId,
        'name' => (string) Drupal::config('system.site')->get('name'),
        'environment' => $environment,
        'drupal_version' => Drupal::VERSION,
        'php_version' => PHP_VERSION,
        'database_driver' => $database->driver(),
        'database_version' => $databaseVersion,
        'site_uuid' => (string) Drupal::config('system.site')->get('uuid'),
    ];
}

function cx_extensions(string $type): array
{
    $serviceId = $type === 'module' ? 'extension.list.module' : 'extension.list.theme';
    $extensionList = Drupal::service($serviceId);
    $enabled = (array) Drupal::config('core.extension')->get($type);
    $discovered = $extensionList->getList();
    $items = [];

    foreach ($discovered as $machineName => $extension) {
        $path = str_replace('\\', '/', $extension->getPath());
        try {
            $info = $extensionList->getExtensionInfo($machineName);
        } catch (Throwable) {
            $info = [];
        }
        $items[] = [
            'id' => (string) $machineName,
            'machine_name' => (string) $machineName,
            'label' => (string) ($info['name'] ?? $machineName),
            'status' => array_key_exists($machineName, $enabled) ? 'enabled' : 'disabled',
            'origin' => cx_extension_origin($path),
            'version' => isset($info['version']) ? (string) $info['version'] : null,
            'package' => isset($info['package']) ? (string) $info['package'] : null,
            'path' => $path,
            'code_present' => true,
        ];
    }

    foreach (array_keys($enabled) as $machineName) {
        if (array_key_exists($machineName, $discovered)) {
            continue;
        }

        $items[] = [
            'id' => (string) $machineName,
            'machine_name' => (string) $machineName,
            'label' => (string) $machineName,
            'status' => 'enabled',
            'origin' => 'missing',
            'version' => null,
            'package' => null,
            'path' => null,
            'code_present' => false,
        ];
    }

    usort($items, static fn(array $left, array $right): int => $left['id'] <=> $right['id']);
    return $items;
}

function cx_extension_origin(string $path): string
{
    if (str_starts_with($path, 'core/')) {
        return 'core';
    }
    if (str_contains($path, '/custom/')) {
        return 'custom';
    }
    if (str_contains($path, '/contrib/')) {
        return 'contributed';
    }
    return 'unknown';
}

function cx_sites(string $installationId): array
{
    return [[
        'id' => 'default',
        'machine_name' => 'default',
        'label' => (string) Drupal::config('system.site')->get('name'),
        'installation_id' => $installationId,
        'site_uuid' => (string) Drupal::config('system.site')->get('uuid'),
    ]];
}

function cx_content_types(): array
{
    $storage = Drupal::entityTypeManager()->getStorage('node_type');
    $items = [];

    foreach ($storage->loadMultiple() as $contentType) {
        $items[] = [
            'id' => $contentType->id(),
            'machine_name' => $contentType->id(),
            'label' => $contentType->label(),
            'description' => (string) $contentType->getDescription(),
            'new_revision' => (bool) $contentType->shouldCreateNewRevision(),
        ];
    }

    usort($items, static fn(array $left, array $right): int => $left['id'] <=> $right['id']);
    return $items;
}

function cx_fields(): array
{
    $fieldManager = Drupal::service('entity_field.manager');
    $contentTypes = Drupal::entityTypeManager()->getStorage('node_type')->loadMultiple();
    $items = [];

    foreach ($contentTypes as $contentType) {
        foreach ($fieldManager->getFieldDefinitions('node', $contentType->id()) as $fieldName => $definition) {
            if (!$definition instanceof FieldDefinitionInterface) {
                continue;
            }

            $storage = $definition->getFieldStorageDefinition();
            $items[] = [
                'id' => 'node.' . $contentType->id() . '.' . $fieldName,
                'machine_name' => $fieldName,
                'label' => (string) $definition->getLabel(),
                'entity_type' => 'node',
                'bundle' => $contentType->id(),
                'field_type' => $definition->getType(),
                'required' => $definition->isRequired(),
                'cardinality' => $storage->getCardinality(),
                'base_field' => $storage->isBaseField(),
            ];
        }
    }

    usort($items, static fn(array $left, array $right): int => $left['id'] <=> $right['id']);
    return $items;
}

function cx_config_entities(string $prefix, string $key): array
{
    $storage = Drupal::service('config.storage');
    $items = [];

    foreach ($storage->listAll($prefix) as $configName) {
        $data = $storage->read($configName) ?: [];
        $id = substr($configName, strlen($prefix));
        $items[] = [
            'id' => $id,
            'machine_name' => $id,
            'label' => (string) ($data['label'] ?? $id),
            'status' => (bool) ($data['status'] ?? true),
            'dependencies' => array_values((array) ($data['dependencies']['module'] ?? [])),
        ];
    }

    usort($items, static fn(array $left, array $right): int => $left['id'] <=> $right['id']);
    return [$key => $items];
}

function cx_role_summaries(): array
{
    $items = [];
    $storage = Drupal::entityTypeManager()->getStorage('user_role');

    foreach ($storage->loadMultiple() as $role) {
        $items[] = [
            'id' => $role->id(),
            'machine_name' => $role->id(),
            'label' => $role->label(),
            'permission_count' => count($role->getPermissions()),
            'administrative' => $role->isAdmin(),
        ];
    }

    usort($items, static fn(array $left, array $right): int => $left['id'] <=> $right['id']);
    return $items;
}

function cx_bundle_counts(string $entityType, string $bundleEntityType): array
{
    if (!Drupal::entityTypeManager()->hasDefinition($entityType)
        || !Drupal::entityTypeManager()->hasDefinition($bundleEntityType)) {
        return [];
    }

    $entityStorage = Drupal::entityTypeManager()->getStorage($entityType);
    $bundleStorage = Drupal::entityTypeManager()->getStorage($bundleEntityType);
    $bundleKey = Drupal::entityTypeManager()->getDefinition($entityType)->getKey('bundle');
    $items = [];

    foreach ($bundleStorage->loadMultiple() as $bundle) {
        $count = $entityStorage->getQuery()
            ->accessCheck(false)
            ->condition($bundleKey, $bundle->id())
            ->count()
            ->execute();

        $items[] = [
            'bundle' => $bundle->id(),
            'label' => $bundle->label(),
            'count' => (int) $count,
        ];
    }

    usort($items, static fn(array $left, array $right): int => $left['bundle'] <=> $right['bundle']);
    return $items;
}

function cx_cron(): array
{
    return [[
        'id' => 'drupal-core-cron',
        'machine_name' => 'drupal-core-cron',
        'label' => 'Drupal core cron',
        'last_run' => Drupal::state()->get('system.cron_last'),
        'logging' => (bool) Drupal::config('system.cron')->get('logging'),
    ]];
}

function cx_json(array $value): string
{
    $json = json_encode($value, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR);
    return $json . "\n";
}

function cx_safe_id(string $value): string
{
    $safe = strtolower((string) preg_replace('/[^a-zA-Z0-9._-]+/', '-', trim($value)));
    return trim($safe, '-') ?: 'drupal';
}

function cx_ensure_directory(string $path): void
{
    if (!is_dir($path) && !mkdir($path, 0770, true) && !is_dir($path)) {
        throw new RuntimeException('Unable to create directory: ' . $path);
    }
}

function cx_write(string $path, string $body): void
{
    if (file_put_contents($path, $body) === false) {
        throw new RuntimeException('Unable to write file: ' . $path);
    }
}

function cx_zip(string $zipPath, string $workDir, array $relativePaths): void
{
    if (!class_exists(ZipArchive::class)) {
        throw new RuntimeException('The PHP Zip extension is required.');
    }

    $zip = new ZipArchive();
    if ($zip->open($zipPath, ZipArchive::CREATE | ZipArchive::OVERWRITE) !== true) {
        throw new RuntimeException('Unable to create ZIP: ' . $zipPath);
    }

    sort($relativePaths, SORT_STRING);
    foreach ($relativePaths as $relativePath) {
        if (!$zip->addFile($workDir . '/' . $relativePath, $relativePath)) {
            $zip->close();
            throw new RuntimeException('Unable to add ZIP entry: ' . $relativePath);
        }
    }

    $zip->close();
}
