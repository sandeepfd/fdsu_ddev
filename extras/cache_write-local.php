<?php

// yii1 cache write component config
return [
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
