<?php

declare(strict_types=1);

/**
 * Seed the synthetic college estate through `drush php:script`.
 */

use Drupal\field\Entity\FieldConfig;
use Drupal\field\Entity\FieldStorageConfig;
use Drupal\node\Entity\Node;
use Drupal\node\Entity\NodeType;
use Drupal\user\Entity\Role;
use Drupal\workflows\Entity\Workflow;

if (!class_exists(Drupal::class) || !defined('DRUPAL_ROOT')) {
    throw new RuntimeException('Run this fixture through a bootstrapped Drush php:script command.');
}

$moduleInstaller = Drupal::service('module_installer');
$moduleInstaller->install([
    'options',
    'datetime',
    'workflows',
    'content_moderation',
    'college_catalog',
    'college_search',
], true);

cx_fixture_content_type('department', 'Department', 'College academic and administrative departments.');
cx_fixture_content_type('program', 'Program', 'Programs and credentials offered by the college.');
cx_fixture_content_type('emergency_alert', 'Emergency Alert', 'Time-sensitive notices displayed across college sites.');

cx_fixture_field('department', 'field_department_code', 'Department code', 'string', [
    'max_length' => 32,
], true);

cx_fixture_field('program', 'field_program_code', 'Program code', 'string', [
    'max_length' => 32,
], true);
cx_fixture_field('program', 'field_external_id', 'SIS external identifier', 'string', [
    'max_length' => 128,
]);
cx_fixture_field('program', 'field_tuition', 'Annual tuition', 'decimal', [
    'precision' => 12,
    'scale' => 2,
]);
cx_fixture_field('program', 'field_delivery_mode', 'Delivery mode', 'list_string', [
    'allowed_values' => [
        'campus' => 'On campus',
        'online' => 'Online',
        'hybrid' => 'Hybrid',
    ],
]);
cx_fixture_field('program', 'field_last_synced', 'Last synchronized from SIS', 'datetime', [
    'datetime_type' => 'datetime',
]);
cx_fixture_field('program', 'field_program_summary', 'Program summary', 'text_long');

cx_fixture_field('emergency_alert', 'field_alert_severity', 'Severity', 'list_string', [
    'allowed_values' => [
        'info' => 'Information',
        'warning' => 'Warning',
        'critical' => 'Critical',
    ],
], true);
cx_fixture_field('emergency_alert', 'field_expires', 'Expires', 'datetime', [
    'datetime_type' => 'datetime',
]);

cx_fixture_role('college_content_editor', 'College content editor', [
    'access content',
    'access content overview',
    'create program content',
    'edit any program content',
    'create emergency_alert content',
]);
cx_fixture_role('college_site_manager', 'College site manager', [
    'access content',
    'access content overview',
    'administer nodes',
    'administer menu',
    'administer content types',
]);

cx_fixture_node('department', 'School of Business', [
    'field_department_code' => 'BUS',
]);
cx_fixture_node('department', 'School of Health Sciences', [
    'field_department_code' => 'HLTH',
]);
cx_fixture_node('department', 'School of Technology', [
    'field_department_code' => 'TECH',
]);

cx_fixture_node('program', 'Business Administration', [
    'field_program_code' => 'BUS-ADM',
    'field_external_id' => 'SIS-1001',
    'field_tuition' => '4850.00',
    'field_delivery_mode' => 'hybrid',
    'field_last_synced' => '2026-11-01T12:00:00',
    'field_program_summary' => 'Synthetic business program used for Contexla testing.',
]);
cx_fixture_node('program', 'Practical Nursing', [
    'field_program_code' => 'HLTH-PN',
    'field_external_id' => 'SIS-2001',
    'field_tuition' => '6250.00',
    'field_delivery_mode' => 'campus',
    'field_last_synced' => '2026-11-01T12:00:00',
    'field_program_summary' => 'Synthetic health program used for Contexla testing.',
]);
cx_fixture_node('program', 'Computer Systems Technology', [
    'field_program_code' => 'TECH-CST',
    'field_external_id' => 'SIS-3001',
    'field_tuition' => '5400.00',
    'field_delivery_mode' => 'hybrid',
    'field_last_synced' => '2026-11-01T12:00:00',
    'field_program_summary' => 'Synthetic technology program used for Contexla testing.',
]);
cx_fixture_node('program', 'Cybersecurity Fundamentals', [
    'field_program_code' => 'TECH-CYB',
    'field_external_id' => 'SIS-3002',
    'field_tuition' => '5100.00',
    'field_delivery_mode' => 'online',
    'field_last_synced' => '2026-11-01T12:00:00',
    'field_program_summary' => 'Synthetic online program used for Contexla testing.',
]);
cx_fixture_node('emergency_alert', 'Campus network maintenance', [
    'field_alert_severity' => 'info',
    'field_expires' => '2026-12-01T12:00:00',
]);

cx_fixture_workflow();
Drupal::service('cache_tags.invalidator')->invalidateTags(['config:core.extension']);

fwrite(STDOUT, "Synthetic college estate is ready.\n");

function cx_fixture_content_type(string $id, string $label, string $description): void
{
    if (NodeType::load($id)) {
        return;
    }

    NodeType::create([
        'type' => $id,
        'name' => $label,
        'description' => $description,
        'new_revision' => true,
        'preview_mode' => 1,
        'display_submitted' => false,
    ])->save();
}

function cx_fixture_field(
    string $bundle,
    string $fieldName,
    string $label,
    string $type,
    array $storageSettings = [],
    bool $required = false,
): void {
    $storage = FieldStorageConfig::loadByName('node', $fieldName);
    if (!$storage) {
        $storage = FieldStorageConfig::create([
            'field_name' => $fieldName,
            'entity_type' => 'node',
            'type' => $type,
            'cardinality' => 1,
            'settings' => $storageSettings,
        ]);
        $storage->save();
    }

    if (!FieldConfig::loadByName('node', $bundle, $fieldName)) {
        FieldConfig::create([
            'field_storage' => $storage,
            'bundle' => $bundle,
            'label' => $label,
            'required' => $required,
        ])->save();
    }
}

function cx_fixture_role(string $id, string $label, array $permissions): void
{
    $role = Role::load($id) ?: Role::create(['id' => $id, 'label' => $label]);
    foreach ($permissions as $permission) {
        $role->grantPermission($permission);
    }
    $role->save();
}

function cx_fixture_node(string $type, string $title, array $values): void
{
    $existing = Drupal::entityTypeManager()->getStorage('node')->getQuery()
        ->accessCheck(false)
        ->condition('type', $type)
        ->condition('title', $title)
        ->range(0, 1)
        ->execute();

    if ($existing !== []) {
        return;
    }

    Node::create(array_merge([
        'type' => $type,
        'title' => $title,
        'status' => true,
        'uid' => 1,
    ], $values))->save();
}

function cx_fixture_workflow(): void
{
    if (Workflow::load('college_editorial')) {
        return;
    }

    Workflow::create([
        'id' => 'college_editorial',
        'label' => 'College editorial workflow',
        'type' => 'content_moderation',
        'type_settings' => [
            'states' => [
                'draft' => [
                    'label' => 'Draft',
                    'weight' => 0,
                    'published' => false,
                    'default_revision' => false,
                ],
                'review' => [
                    'label' => 'Needs review',
                    'weight' => 1,
                    'published' => false,
                    'default_revision' => false,
                ],
                'published' => [
                    'label' => 'Published',
                    'weight' => 2,
                    'published' => true,
                    'default_revision' => true,
                ],
                'archived' => [
                    'label' => 'Archived',
                    'weight' => 3,
                    'published' => false,
                    'default_revision' => true,
                ],
            ],
            'transitions' => [
                'submit_for_review' => [
                    'label' => 'Submit for review',
                    'from' => ['draft'],
                    'to' => 'review',
                    'weight' => 0,
                ],
                'publish' => [
                    'label' => 'Publish',
                    'from' => ['draft', 'review'],
                    'to' => 'published',
                    'weight' => 1,
                ],
                'archive' => [
                    'label' => 'Archive',
                    'from' => ['published'],
                    'to' => 'archived',
                    'weight' => 2,
                ],
            ],
            'entity_types' => [
                'node' => ['program', 'emergency_alert'],
            ],
            'default_moderation_state' => 'draft',
        ],
    ])->save();
}
