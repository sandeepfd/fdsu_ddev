<?php

$configPath = dirname(__FILE__) . DIRECTORY_SEPARATOR;
$dbReadConfigLocal = require $configPath . 'db_read-local.php';
$dbReadReportConfigLocal = require $configPath . 'db_read_report-local.php';
$dbConfigLocal = [
    'class' => 'system.db.CDbConnection',
    'connectionString' => 'pgsql:host=db;dbname=db',
    'username' => 'db',
    'password' => 'db',
    'charset' => 'utf8',
    'initSQLs' => ['SET search_path TO app, public; SET statement_timeout TO 2500000;'],
];

$cacheReadConfigLocal = require $configPath . 'cache-local.php';
$cacheConfigLocal = [
    'class' => 'system.caching.CRedisCache',
    'keyPrefix' => 'dev10',
    'options' => STREAM_CLIENT_CONNECT,
    'behaviors' => [
        'cacheTag' => [
            'class' => 'site_app.components.CacheTagBehavior',
        ],
    ],
    'hostname' => 'redis',
    'port' => '6379',
    'password' => 'yourpassword',
    'database' => 0
];

$sitePath = dirname(dirname(__FILE__));
$basePath = dirname($sitePath);
$configPath = $sitePath . '/config/';
$imgPath = $basePath.'/site/web/img/';
$picsPath = $basePath.'/site/web/images/pics/';
$iconsPath = $basePath.'/site/web/images/icons/';
$filesPath = $basePath.'/site/web/files/';
$videosSrcPath = $basePath.'/site/vsrc/';
$videosPath = $basePath.'/site/web/v/';
$schema = 'https';
return [
    'components' => [
        'db' => $dbConfigLocal,
        'dbRead' => $dbConfigLocal,
        'dbReadReport' => $dbConfigLocal,
        'dbWrite' => $dbConfigLocal,
        'cache' => $cacheConfigLocal,
        'cacheWrite' => $cacheConfigLocal,
    ],
    'params' => [
        'rootUrl' => $schema . '://sizeup.firstduesizeup.test/',
        'picDbUrl' => $schema . '://sizeup.firstduesizeup.test/images/pics/',
        'googleApiBrowserKey' => 'AIzaSyBXBn3-dNLuOBu2mRfePCUgNL9cn_kPvSo',
        'googleApiServerKey' => 'AIzaSyCwJGvA6LZx_7C3TmS2sHy5kwILLJBed14',
        'fileDbPath' => $sitePath . '/web/files/',
        'picDbPath' => $picsPath,
        'imgPath' => $imgPath,
        'smartyStreets' => [
            'authId' => '477965af-80ad-d6a6-d211-2e99104fe497',
            'authToken' => '3TAJGbewkU8DyUlGyusq',
        ],
        'signatureDbPath' => $basePath . '/site/web/images/signatures/',
        'amqp' => [
            'host' => 'rabbitmq',
            'vhost' => '/',
            'port' => '5672',
            'login' => 'rabbitmq',
            'password' => 'rabbitmq',
        ],
        'smtps' => [
            'DEFAULT' => [
                'host' => 'localhost',
                'port' => 1025,
                'encryption' => 0,
                'smtp_credential_provider' => 'swiftmailer'
            ],
        ],
    ]
];
