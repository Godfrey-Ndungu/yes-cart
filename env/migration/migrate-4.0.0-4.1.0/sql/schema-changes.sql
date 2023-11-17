--
--  Copyright 2009 Inspire-Software.com
--
--     Licensed under the Apache License, Version 2.0 (the "License");
--     you may not use this file except in compliance with the License.
--     You may obtain a copy of the License at
--
--         http://www.apache.org/licenses/LICENSE-2.0
--
--     Unless required by applicable law or agreed to in writing, software
--     distributed under the License is distributed on an "AS IS" BASIS,
--     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--     See the License for the specific language governing permissions and
--     limitations under the License.
--

--
-- This script is for MySQL only with some Derby hints inline with comments
-- We highly recommend you seek YC's support help when upgrading your system
-- for detailed analysis of your code.
--
-- Upgrades organised in blocks representing JIRA tasks for which they are
-- necessary - potentially you may hand pick the upgrades you required but
-- to keep upgrade process as easy as possible for future we recommend full
-- upgrades
--

--
-- YC-1042 Show more feature on category lister pages
--

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV)
  VALUES (  11130,  'SHOP_CATEGORY_PAGE_CTRL_DISABLE', 'SHOP_CATEGORY_PAGE_CTRL_DISABLE',  0,  NULL,  'Category: Hide pagination controls on category page',
   'Hide pagination buttons on the category page',  'Boolean', 'SHOP', 0, 0, 0, 0);

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV)
  VALUES (  11131,  'SHOP_CATEGORY_SORT_CTRL_DISABLE', 'SHOP_CATEGORY_SORT_CTRL_DISABLE',  0,  NULL,  'Category: Hide sorting controls on category page',
   'Disable sorting buttons on the category page',  'Boolean', 'SHOP', 0, 0, 0, 0);

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV)
  VALUES (  11132,  'SHOP_CATEGORY_PAGESIZE_CTRL_DISABLE', 'SHOP_CATEGORY_PAGESIZE_CTRL_DISABLE',  0,  NULL,  'Category: Hide page size controls on category page',
   'Disable page size buttons on the category page',  'Boolean', 'SHOP', 0, 0, 0, 0);

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV)
  VALUES (  11133,  'SHOP_CATEGORY_SHOWMORE_CTRL_DISABLE', 'SHOP_CATEGORY_SHOWMORE_CTRL_DISABLE',  0,  NULL,  'Category: Hide show more controls on category page',
   'Disable show more buttons on the category page',  'Boolean', 'SHOP', 0, 0, 0, 0);

--
-- YC-1037 Job schedules abstraction layer
--

    create table TJOBDEFINITION (
        JOBDEFINITION_ID bigint not null auto_increment,
        VERSION bigint not null default 0,
        JOB_NAME varchar(255) not null unique,
        PROCESSOR varchar(255) not null,
        CONTEXT longtext,
        HOST_REGEX varchar(45),
        DEFAULT_CRON varchar(45),
        DEFAULT_CRON_KEY varchar(100),
        DEFAULT_PAUSED  bit not null default 0,
        GUID varchar(100) not null unique,
        CREATED_TIMESTAMP datetime,
        UPDATED_TIMESTAMP datetime,
        CREATED_BY varchar(64),
        UPDATED_BY varchar(64),
        primary key (JOBDEFINITION_ID)
    );

    create table TJOB (
        JOB_ID bigint not null auto_increment,
        VERSION bigint not null default 0,
        NODE_ID varchar(45) not null,
        JOB_DEFINITION_CODE varchar(100) not null,
        CRON varchar(45),
        PAUSED  bit not null default 0,
        PAUSE_ON_ERROR  bit not null default 0,
        DISABLED  bit not null default 0,
        LAST_RUN  datetime,
        LAST_REPORT longtext,
        LAST_STATE varchar(45),
        LAST_DURATION_MS bigint default 0,
        CHECKPOINT  datetime,
        GUID varchar(36) not null unique,
        CREATED_TIMESTAMP datetime,
        UPDATED_TIMESTAMP datetime,
        CREATED_BY varchar(64),
        UPDATED_BY varchar(64),
        primary key (JOB_ID)
    );

    create index JOBDEFINITION_GUID on TJOBDEFINITION (GUID);
    create index JOB_JD_CODE on TJOB (JOB_DEFINITION_CODE);

--     create table TJOBDEFINITION (
--         JOBDEFINITION_ID bigint not null GENERATED BY DEFAULT AS IDENTITY,
--         VERSION bigint not null default 0,
--         JOB_NAME varchar(255) not null unique,
--         PROCESSOR varchar(255) not null,
--         CONTEXT varchar(4000),
--         HOST_REGEX varchar(45),
--         DEFAULT_CRON varchar(45),
--         DEFAULT_CRON_KEY varchar(100),
--         DEFAULT_PAUSED  smallint not null default 0,
--         GUID varchar(100) not null unique,
--         CREATED_TIMESTAMP timestamp,
--         UPDATED_TIMESTAMP timestamp,
--         CREATED_BY varchar(64),
--         UPDATED_BY varchar(64),
--         primary key (JOBDEFINITION_ID)
--     );
--
--     create table TJOB (
--         JOB_ID bigint not null GENERATED BY DEFAULT AS IDENTITY,
--         VERSION bigint not null default 0,
--         NODE_ID varchar(45) not null,
--         JOB_DEFINITION_CODE varchar(100) not null,
--         CRON varchar(45),
--         PAUSED  smallint not null default 0,
--         PAUSE_ON_ERROR  smallint not null default 0,
--         DISABLED  smallint not null default 0,
--         LAST_RUN  timestamp,
--         LAST_REPORT varchar(4000),
--         LAST_STATE varchar(45),
--         LAST_DURATION_MS bigint default 0,
--         CHECKPOINT  timestamp,
--         GUID varchar(36) not null unique,
--         CREATED_TIMESTAMP timestamp,
--         UPDATED_TIMESTAMP timestamp,
--         CREATED_BY varchar(64),
--         UPDATED_BY varchar(64),
--         primary key (JOB_ID)
--     );
--
--     create index JOBDEFINITION_GUID on TJOBDEFINITION (GUID);
--     create index JOB_JD_CODE on TJOB (JOB_DEFINITION_CODE);

-- manager-cronjob.xml ---------------

-- BulkMailProcessorImpl
INSERT INTO TJOBDEFINITION (JOBDEFINITION_ID, GUID, JOB_NAME, PROCESSOR, CONTEXT, HOST_REGEX, DEFAULT_CRON_KEY, DEFAULT_PAUSED)
  VALUES (1001, 'sendMailJob', 'Send Mail', 'bulkMailProcessor', '', '^(ADM)$', 'admin.cron.sendMailJob', 1);
-- LocalFileShareImportListenerImpl
DELETE FROM TSYSTEMATTRVALUE WHERE CODE IN ('JOB_LOCAL_FILE_IMPORT_PAUSE', 'JOB_LOCAL_FILE_IMPORT_FS_ROOT');
DELETE FROM TATTRIBUTE WHERE CODE IN ('JOB_LOCAL_FILE_IMPORT_PAUSE', 'JOB_LOCAL_FILE_IMPORT_FS_ROOT');
INSERT INTO TJOBDEFINITION (JOBDEFINITION_ID, GUID, JOB_NAME, PROCESSOR, CONTEXT, HOST_REGEX, DEFAULT_CRON_KEY, DEFAULT_PAUSED)
  VALUES (1002, 'autoImportJob', 'Auto Import', 'autoImportListener', 'file-import-root=/set/path/here
# set groups e.g.
SHOP10.config.0.group=YC DEMO: Initial Data
SHOP10.config.0.regex=import\\.zip
SHOP10.config.0.reindex=true
SHOP10.config.0.user=admin@yes-cart.com
SHOP10.config.0.pass=xxxxxx',
    '^(ADM)$', 'admin.cron.autoImportJob', 1);
-- RawDataImporterRunnerImpl
DELETE FROM TSYSTEMATTRVALUE WHERE CODE IN ('JOB_RAW_DATA_IMPORT_PAUSE');
DELETE FROM TATTRIBUTE WHERE CODE IN ('JOB_RAW_DATA_IMPORT_PAUSE');
-- LocalFileShareImageVaultProcessorImpl
DELETE FROM TSYSTEMATTRVALUE WHERE CODE IN ('JOB_LOCAL_IMAGEVAULT_SCAN_PAUSE');
DELETE FROM TATTRIBUTE WHERE CODE IN ('JOB_LOCAL_IMAGEVAULT_SCAN_PAUSE');
INSERT INTO TJOBDEFINITION (JOBDEFINITION_ID, GUID, JOB_NAME, PROCESSOR, CONTEXT, HOST_REGEX, DEFAULT_CRON_KEY, DEFAULT_PAUSED)
  VALUES (1003, 'imageVaultProcessorJob', 'Image Vault Scanner', 'imageVaultProcessor', 'config.user=admin@yes-cart.com
config.pass=xxxxxx
config.reindex=true',
    '^(ADM)$', 'admin.cron.imageVaultProcessorJob', 1);
-- LocalFileShareProductImageVaultCleanupProcessorImpl
DELETE FROM TSYSTEMATTRVALUE WHERE CODE IN ('JOB_LOCAL_PRODIMAGECLEAN_SCAN_PAUSE', 'JOB_LOCAL_PRODIMAGEVAULT_CLEAN_MODE');
DELETE FROM TATTRIBUTE WHERE CODE IN ('JOB_LOCAL_PRODIMAGECLEAN_SCAN_PAUSE', 'JOB_LOCAL_PRODIMAGEVAULT_CLEAN_MODE');
INSERT INTO TJOBDEFINITION (JOBDEFINITION_ID, GUID, JOB_NAME, PROCESSOR, CONTEXT, HOST_REGEX, DEFAULT_CRON_KEY, DEFAULT_PAUSED)
  VALUES (1004, 'productImageVaultCleanupProcessorJob', 'Product Image Vault Clean Up', 'productImageVaultCleanupProcessor', 'clean-mode=scan',
    '^(ADM)$', 'admin.cron.productImageVaultCleanupProcessorJob', 1);
-- CacheEvictionQueueProcessorImpl
DELETE FROM TSYSTEMATTRVALUE WHERE CODE IN ('JOB_CACHE_EVICT_PAUSE');
DELETE FROM TATTRIBUTE WHERE CODE IN ('JOB_CACHE_EVICT_PAUSE');
INSERT INTO TJOBDEFINITION (JOBDEFINITION_ID, GUID, JOB_NAME, PROCESSOR, CONTEXT, HOST_REGEX, DEFAULT_CRON_KEY, DEFAULT_PAUSED)
  VALUES (1005, 'cacheEvictionQueueJob', 'Evict frontend cache', 'cacheEvictionQueueProcessor', null,
    '^(ADM)$', 'admin.cron.cacheEvictionQueueJob', 0);


-- core-manager-cronjob.xml ---------------

-- BulkCustomerTagProcessorImpl
DELETE FROM TSYSTEMATTRVALUE WHERE CODE IN ('JOB_CUSTOMER_TAG_BATCH_SIZE', 'JOB_CUSTOMER_TAG_PAUSE');
DELETE FROM TATTRIBUTE WHERE CODE IN ('JOB_CUSTOMER_TAG_BATCH_SIZE', 'JOB_CUSTOMER_TAG_PAUSE');
INSERT INTO TJOBDEFINITION (JOBDEFINITION_ID, GUID, JOB_NAME, PROCESSOR, CONTEXT, HOST_REGEX, DEFAULT_CRON_KEY, DEFAULT_PAUSED)
  VALUES (1101, 'customerTagJob', 'Customer Tagging', 'bulkCustomerTagProcessor', 'process-batch-size=500',
    '^(ADM)$', 'admin.cron.customerTagJob', 1);
-- BulkAbandonedShoppingCartProcessorImpl
DELETE FROM TSYSTEMATTRVALUE WHERE CODE IN ('JOB_ABANDONED_CARTS_BATCH_SIZE', 'CART_ABANDONED_TIMEOUT_SECONDS', 'JOB_ABANDONED_CARTS_PAUSE');
DELETE FROM TATTRIBUTE WHERE CODE IN ('JOB_ABANDONED_CARTS_BATCH_SIZE', 'CART_ABANDONED_TIMEOUT_SECONDS', 'JOB_ABANDONED_CARTS_PAUSE');
INSERT INTO TJOBDEFINITION (JOBDEFINITION_ID, GUID, JOB_NAME, PROCESSOR, CONTEXT, HOST_REGEX, DEFAULT_CRON_KEY, DEFAULT_PAUSED)
  VALUES (1102, 'abandonedShoppingCartJob', 'Abandoned Shopping Cart State Clean Up', 'bulkAbandonedShoppingCartProcessor', 'process-batch-size=500
abandoned-timeout-seconds=2592000',
    '^(ADM)$', 'admin.cron.abandonedShoppingCartJob', 0);
-- BulkEmptyAnonymousShoppingCartProcessorImpl
DELETE FROM TSYSTEMATTRVALUE WHERE CODE IN ('JOB_EMPTY_CARTS_BATCH_SIZE', 'CART_EMPTY_ANONYMOUS_TIMEOUT_SECONDS', 'JOB_EMPTY_CARTS_PAUSE');
DELETE FROM TATTRIBUTE WHERE CODE IN ('JOB_EMPTY_CARTS_BATCH_SIZE', 'CART_EMPTY_ANONYMOUS_TIMEOUT_SECONDS', 'JOB_EMPTY_CARTS_PAUSE');
INSERT INTO TJOBDEFINITION (JOBDEFINITION_ID, GUID, JOB_NAME, PROCESSOR, CONTEXT, HOST_REGEX, DEFAULT_CRON_KEY, DEFAULT_PAUSED)
  VALUES (1103, 'emptyAnonymousShoppingCartJob', 'Empty Anonymous Shopping Cart State Clean Up', 'bulkEmptyAnonymousShoppingCartProcessor', 'process-batch-size=500
empty-timeout-seconds=86400',
    '^(ADM)$', 'admin.cron.emptyAnonymousShoppingCartJob', 0);
-- BulkExpiredGuestsProcessorImpl
DELETE FROM TSYSTEMATTRVALUE WHERE CODE IN ('JOB_EXPIRE_GUESTS_BATCH_SIZE', 'GUESTS_EXPIRY_TIMEOUT_SECONDS', 'JOB_EXPIRE_GUESTS_PAUSE');
DELETE FROM TATTRIBUTE WHERE CODE IN ('JOB_EXPIRE_GUESTS_BATCH_SIZE', 'GUESTS_EXPIRY_TIMEOUT_SECONDS', 'JOB_EXPIRE_GUESTS_PAUSE');
INSERT INTO TJOBDEFINITION (JOBDEFINITION_ID, GUID, JOB_NAME, PROCESSOR, CONTEXT, HOST_REGEX, DEFAULT_CRON_KEY, DEFAULT_PAUSED)
  VALUES (1104, 'expiredGuestsJob', 'Expired Guest Accounts Clean Up', 'bulkExpiredGuestsProcessor', 'process-batch-size=500
guest-timeout-seconds=86400',
    '^(ADM)$', 'admin.cron.expiredGuestsJob', 0);
-- RemoveObsoleteProductProcessorImpl
DELETE FROM TSYSTEMATTRVALUE WHERE CODE IN ('JOB_PROD_OBS_BATCH_SIZE', 'JOB_PROD_OBS_MAX', 'JOB_PROD_OBS_PAUSE');
DELETE FROM TATTRIBUTE WHERE CODE IN ('JOB_PROD_OBS_BATCH_SIZE', 'JOB_PROD_OBS_MAX', 'JOB_PROD_OBS_PAUSE');
INSERT INTO TJOBDEFINITION (JOBDEFINITION_ID, GUID, JOB_NAME, PROCESSOR, CONTEXT, HOST_REGEX, DEFAULT_CRON_KEY, DEFAULT_PAUSED)
  VALUES (1105, 'removeObsoleteProductProcessorJob', 'Remove obsolete products', 'removeObsoleteProductProcessor', 'process-batch-size=500
obsolete-timeout-days=365',
    '^(ADM)$', 'admin.cron.removeObsoleteProductProcessorJob', 1);

-- core-index-cronjob.xml ---------------------------

-- ProductsGlobalIndexProcessorImpl
DELETE FROM TSYSTEMATTRVALUE WHERE CODE IN ('JOB_REINDEX_PRODUCT_BATCH_SIZE', 'JOB_GLOBALREINDEX_PAUSE');
DELETE FROM TATTRIBUTE WHERE CODE IN ('JOB_REINDEX_PRODUCT_BATCH_SIZE', 'JOB_GLOBALREINDEX_PAUSE');
INSERT INTO TJOBDEFINITION (JOBDEFINITION_ID, GUID, JOB_NAME, PROCESSOR, CONTEXT, HOST_REGEX, DEFAULT_CRON_KEY, DEFAULT_PAUSED)
  VALUES (1201, 'productsGlobalIndexProcessorJob', 'Reindex All Products', 'productsGlobalIndexProcessor', 'reindex-batch-size=100',
    '^((API)|(SF[A-Z]))$', 'ws.cron.productsGlobalIndexProcessorJob', 1);
-- ProductInventoryChangedProcessorImpl
DELETE FROM TSYSTEMATTRVALUE WHERE CODE LIKE 'JOB_PRODINVUP_LR_%';
DELETE FROM TATTRIBUTE  WHERE CODE LIKE 'JOB_PRODINVUP_LR_%';
DELETE FROM TSYSTEMATTRVALUE WHERE CODE IN ('JOB_REINDEX_PRODUCT_BATCH_SIZE', 'JOB_PRODINVUP_DELTA', 'JOB_PRODINVUP_FULL', 'JOB_PRODINVUP_DELTA_S', 'JOB_PRODINVUP_PAUSE');
DELETE FROM TATTRIBUTE  WHERE CODE IN ('JOB_REINDEX_PRODUCT_BATCH_SIZE', 'JOB_PRODINVUP_DELTA', 'JOB_PRODINVUP_FULL', 'JOB_PRODINVUP_DELTA_S', 'JOB_PRODINVUP_PAUSE');
INSERT INTO TJOBDEFINITION (JOBDEFINITION_ID, GUID, JOB_NAME, PROCESSOR, CONTEXT, HOST_REGEX, DEFAULT_CRON_KEY, DEFAULT_PAUSED)
  VALUES (1202, 'productInventoryChangedProcessorJob', 'Inventory Changes Product Indexing', 'productInventoryChangedProcessor', 'reindex-batch-size=100
inventory-full-threshold=1000
inventory-delta-seconds=15
inventory-update-delta=100',
    '^((API)|(SF[A-Z]))$', 'ws.cron.productInventoryChangedProcessorJob', 0);


-- core-export-cronjob.xml ---------------------------

-- OrderAutoExportProcessorImpl
DELETE FROM TSYSTEMATTRVALUE WHERE CODE IN ('JOB_ORDER_AUTO_EXPORT_PAUSE');
DELETE FROM TATTRIBUTE WHERE CODE IN ('JOB_ORDER_AUTO_EXPORT_PAUSE');
INSERT INTO TJOBDEFINITION (JOBDEFINITION_ID, GUID, JOB_NAME, PROCESSOR, CONTEXT, HOST_REGEX, DEFAULT_CRON_KEY, DEFAULT_PAUSED)
  VALUES (1301, 'orderAutoExportProcessorJob', 'Order Auto Export Processing', 'orderAutoExportProcessor', '',
    '^(ADM)$', 'admin.cron.orderAutoExportProcessorJob', 1);


-- core-orderstate-cronjob.xml ---------------------------

-- BulkAwaitingInventoryDeliveriesProcessorImpl
DELETE FROM TSYSTEMATTRVALUE WHERE CODE IN ('JOB_DELIVERY_WAIT_INVENTORY_PAUSE', 'JOB_DELWAITINV_LR');
DELETE FROM TATTRIBUTE WHERE CODE IN ('JOB_DELIVERY_WAIT_INVENTORY_PAUSE', 'JOB_DELWAITINV_LR');
INSERT INTO TJOBDEFINITION (JOBDEFINITION_ID, GUID, JOB_NAME, PROCESSOR, CONTEXT, HOST_REGEX, DEFAULT_CRON_KEY, DEFAULT_PAUSED)
  VALUES (1401, 'preorderJob', 'Inventory Awaiting Delivery Processing', 'bulkAwaitingInventoryDeliveriesProcessor', '',
    '^(ADM)$', 'admin.cron.preorderJob', 0);
-- OrderDeliveryInfoUpdateProcessorImpl
DELETE FROM TSYSTEMATTRVALUE WHERE CODE IN ('JOB_DELIVERY_INFO_UPDATE_PAUSE');
DELETE FROM TATTRIBUTE WHERE CODE IN ('JOB_DELIVERY_INFO_UPDATE_PAUSE');
INSERT INTO TJOBDEFINITION (JOBDEFINITION_ID, GUID, JOB_NAME, PROCESSOR, CONTEXT, HOST_REGEX, DEFAULT_CRON_KEY, DEFAULT_PAUSED)
  VALUES (1402, 'deliveryInfoUpdateJob', 'Order Delivery Information Update Processing', 'orderDeliveryInfoUpdateProcessor', '',
    '^(ADM)$', 'admin.cron.deliveryInfoUpdateJob', 0);


-- core-pricerules-cronjob.xml --------------

-- BulkPriceRuleProcessorImpl
DELETE FROM TSYSTEMATTRVALUE WHERE CODE IN ('JOB_PRICE_RULES_BATCH_SIZE', 'JOB_PRICE_RULES_PAUSE');
DELETE FROM TATTRIBUTE WHERE CODE IN ('JOB_PRICE_RULES_BATCH_SIZE', 'JOB_PRICE_RULES_PAUSE');
INSERT INTO TJOBDEFINITION (JOBDEFINITION_ID, GUID, JOB_NAME, PROCESSOR, CONTEXT, HOST_REGEX, DEFAULT_CRON_KEY, DEFAULT_PAUSED)
  VALUES (1501, 'priceGeneratorJob', 'Price generator', 'bulkPriceRuleProcessor', 'process-batch-size=500',
  '^(ADM)$', 'admin.cron.priceGeneratorJob', 1);

-- int-module-pim-icecat.xml --------------
-- DailyIndexProcessorV2Impl
DELETE FROM TSYSTEMATTRVALUE WHERE CODE IN ('JOB_ICE_DAILY_PAUSE');
DELETE FROM TATTRIBUTE WHERE CODE IN ('JOB_ICE_DAILY_PAUSE');
INSERT INTO TJOBDEFINITION (JOBDEFINITION_ID, GUID, JOB_NAME, PROCESSOR, CONTEXT, HOST_REGEX, DEFAULT_CRON_KEY, DEFAULT_PAUSED)
  VALUES (1601, 'iceCatDailyIndexJobV2', 'IceCat Daily Index Update (V2)', 'iceCatDailyIndexProcessorV2', null,
  '^(ADM)$', 'admin.cron.iceCatDailyIndexJobV2', 1);
-- BrandAttributesProcessorImpl
DELETE FROM TSYSTEMATTRVALUE WHERE CODE IN ('JOB_ICE_ENHANCE_B_PAUSE');
DELETE FROM TATTRIBUTE WHERE CODE IN ('JOB_ICE_ENHANCE_B_PAUSE');
INSERT INTO TJOBDEFINITION (JOBDEFINITION_ID, GUID, JOB_NAME, PROCESSOR, CONTEXT, HOST_REGEX, DEFAULT_CRON_KEY, DEFAULT_PAUSED)
  VALUES (1602, 'iceCatBrandAttributesJob', 'IceCat Brand Attributes Enhancer', 'iceCatBrandAttributesProcessor', null,
  '^(ADM)$', 'admin.cron.iceCatBrandAttributesJob', 1);
-- AuthenticatedProductAttributesProcessorImpl
DELETE FROM TSYSTEMATTRVALUE WHERE CODE IN ('JOB_ICE_ENHANCE_PAUSE');
DELETE FROM TATTRIBUTE WHERE CODE IN ('JOB_ICE_ENHANCE_PAUSE');
INSERT INTO TJOBDEFINITION (JOBDEFINITION_ID, GUID, JOB_NAME, PROCESSOR, CONTEXT, HOST_REGEX, DEFAULT_CRON_KEY, DEFAULT_PAUSED)
  VALUES (1603, 'iceCatProductAttributesJob', 'IceCat Product Attributes Enhancer', 'authenticatedIceCatProductAttributesProcessor', null,
  '^(ADM)$', 'admin.cron.iceCatProductAttributesJob', 1);


--
-- YC-1045 Login for cart page
--

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV)
  VALUES (  11408,  'SHOP_SF_REQUIRE_LOGIN_CART', 'SHOP_SF_REQUIRE_LOGIN_CART',  1,  NULL,  'Customer: login required for cart',  'Anonymous viewing of cart is prohibited',  'Boolean', 'SHOP', 0, 0, 0, 0);


--
-- YC-1047 Dictionary service for various items
--

INSERT INTO TATTRIBUTEGROUP (ATTRIBUTEGROUP_ID, GUID, CODE, NAME, DESCRIPTION) VALUES (1099, 'DICTIONARY', 'DICTIONARY', 'Dictionary.', '');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7001,  'PROMOTION_TYPE_O', 'PROMOTION_TYPE_O',  0,  NULL,  'Promotion Type: Order',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Bestellung#~#en#~#Order#~#ru#~#Заказ#~#uk#~#Замовлення#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7002,  'PROMOTION_TYPE_S', 'PROMOTION_TYPE_S',  0,  NULL,  'Promotion Type: Shipping',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Versand#~#en#~#Shipping#~#ru#~#Доставка#~#uk#~#Доставка#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7003,  'PROMOTION_TYPE_I', 'PROMOTION_TYPE_I',  0,  NULL,  'Promotion Type: Product',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Produkt#~#en#~#Product#~#ru#~#Товар#~#uk#~#Товар#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7004,  'PROMOTION_TYPE_C', 'PROMOTION_TYPE_C',  0,  NULL,  'Promotion Type: Customer',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Kunde#~#en#~#Customer#~#ru#~#Покупатель#~#uk#~#Покупець#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7010,  'PROMOTION_ACTION_F', 'PROMOTION_ACTION_F',  0,  NULL,  'Promotion Action: Value off',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Betrag auf Preisreduziert#~#en#~#Value off#~#ru#~#Сумма скидки#~#uk#~#Сума знижки#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7011,  'PROMOTION_ACTION_P', 'PROMOTION_ACTION_P',  0,  NULL,  'Promotion Action: Percentage off',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Prozentsatz Rabatt#~#en#~#Percentage off#~#ru#~#Процент скидки#~#uk#~#Відсоток знижки#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7012,  'PROMOTION_ACTION_S', 'PROMOTION_ACTION_S',  0,  NULL,  'Promotion Action: Percentage off (non sale)',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Prozentsatz Rabatt (kein Verkaufsrabatt)#~#en#~#Percentage off (non sale)#~#ru#~#Процент скидки (не для цен со скидкой)#~#uk#~#Відсоток знижки (не для цін зі знижкою)#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7013,  'PROMOTION_ACTION_G', 'PROMOTION_ACTION_G',  0,  NULL,  'Promotion Action: Gift',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Geschenk#~#en#~#Gift#~#ru#~#Подарок#~#uk#~#Подарунок#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7014,  'PROMOTION_ACTION_T', 'PROMOTION_ACTION_T',  0,  NULL,  'Promotion Action: Customer tag',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Kunden Tag#~#en#~#Customer tag#~#ru#~#Тег для покупателя#~#uk#~#Тег для покупця#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7020,  'CARRIERSLA_SLATYPE_F', 'CARRIERSLA_SLATYPE_F',  0,  NULL,  'SLA Type: Fixed',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Fest#~#en#~#Fixed#~#ru#~#Фиксированая цена#~#uk#~#Фіксована ціна#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7021,  'CARRIERSLA_SLATYPE_R', 'CARRIERSLA_SLATYPE_R',  0,  NULL,  'SLA Type: Free',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Kostenfrei#~#en#~#Free#~#ru#~#Бесплатно#~#uk#~#Безкоштовно#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7022,  'CARRIERSLA_SLATYPE_W', 'CARRIERSLA_SLATYPE_W',  0,  NULL,  'SLA Type: Weight & Volume',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Gewicht & Volumen#~#en#~#Weight & Volume#~#ru#~#Вес и объем#~#uk#~#Вага і обсяг#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7023,  'CARRIERSLA_SLATYPE_O', 'CARRIERSLA_SLATYPE_O',  0,  NULL,  'SLA Type: Offline calculation',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Offline-Berechnung#~#en#~#Offline calculation#~#ru#~#Расчитывается отдельно#~#uk#~#Розраховується окремо#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7024,  'CARRIERSLA_SLATYPE_E', 'CARRIERSLA_SLATYPE_E',  0,  NULL,  'SLA Type: External service calculation',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Externe Preisrechnung#~#en#~#External service calculation#~#ru#~#Кастомизация#~#uk#~#Кастомізація#~#');


INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7050,  'REPORT_PARAM_orderNumber', 'REPORT_PARAM_orderNumber',  0,  NULL,  'Report parameter: Order Number',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Bestellnummer#~#en#~#Order Number#~#ru#~#Номер заказа#~#uk#~#Номер замовлення#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7051,  'REPORT_PARAM_warehouse', 'REPORT_PARAM_warehouse',  0,  NULL,  'Report parameter: Fulfilment centre',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Auslieferzentrum#~#en#~#Fulfilment centre#~#ru#~#Центр выполнения заказа#~#uk#~#Центр виконання замовлення#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7052,  'REPORT_PARAM_shop', 'REPORT_PARAM_shop',  0,  NULL,  'Report parameter: Sales channel',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Vertriebskanal#~#en#~#Sales channel#~#ru#~#Канал продаж#~#uk#~#Канал збуту#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7053,  'REPORT_PARAM_skuCode', 'REPORT_PARAM_skuCode',  0,  NULL,  'Report parameter: SKU',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#SKU#~#en#~#SKU#~#ru#~#Артикул#~#uk#~#Артикул#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7054,  'REPORT_PARAM_fromDate', 'REPORT_PARAM_fromDate',  0,  NULL,  'Report parameter: From Date',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Von (yyyy-MM-dd HH:mm:ss, nur Jahr ist Pflichteingabe)#~#en#~#From (yyyy-MM-dd HH:mm:ss, only year is mandatory)#~#ru#~#С (yyyy-MM-dd HH:mm:ss, только год обязателен)#~#uk#~#З (yyyy-MM-dd HH:mm:ss, тільки рік обов''язковий)#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7055,  'REPORT_PARAM_tillDate', 'REPORT_PARAM_tillDate',  0,  NULL,  'Report parameter: To Date',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Bis (yyyy-MM-dd HH:mm:ss, nur Jahr ist Pflichteingabe)#~#en#~#To (yyyy-MM-dd HH:mm:ss, only year is mandatory)#~#ru#~#По (yyyy-MM-dd HH:mm:ss, только год обязателен)#~#uk#~#До (yyyy-MM-dd HH:mm:ss, тільки рік обов''язковий)#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7060,  'REPORT_reportDeliveryPDF', 'REPORT_reportDeliveryPDF',  0,  NULL,  'Report: Delivery report (PDF)',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Liefer Report (PDF)#~#en#~#Delivery report (PDF)#~#ru#~#Счет-фактура по заказу (PDF)#~#uk#~#Рахунок-фактура на замовлення (PDF)#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7061,  'REPORT_reportAvailableStockPDF', 'REPORT_reportAvailableStockPDF',  0,  NULL,  'Report: Inventory report (PDF)',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Lager Report (PDF)#~#en#~#Inventory report (PDF)#~#ru#~#Отчет инвентаризации (PDF)#~#uk#~#Звіт інвентаризації (PDF)#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7062,  'REPORT_reportPaymentsPDF', 'REPORT_reportPaymentsPDF',  0,  NULL,  'Report: Payments report (PDF)',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Zahlungs Report (PDF)#~#en#~#Payments report (PDF)#~#ru#~#Отчет по оплатам (PDF)#~#uk#~#Звіт по оплатах (PDF)#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7063,  'REPORT_reportAvailableStockXLSX', 'REPORT_reportAvailableStockXLSX',  0,  NULL,  'Report: Inventory report (XLSX)',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Lager Report (XLSX)#~#en#~#Inventory report (XLSX)#~#ru#~#Отчет инвентаризации (XLSX)#~#uk#~#Звіт інвентаризації (XLSX)#~#');

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, DISPLAYNAME)
  VALUES (  7064,  'REPORT_salesByCategoryXLSX', 'REPORT_salesByCategoryXLSX',  0,  NULL,  'Report: Sales report by category (XLSX)',  null,  'String', 'DICTIONARY', 0, 0, 0, 0,
  'de#~#Verkaufsbericht nach Kategorie (XLSX)#~#en#~#Sales report by category (XLSX)#~#ru#~#Отчет продаж по категории (XLSX)#~#uk#~#Звіт продажів за категорією (XLSX)#~#');

--
-- Improvement to allow configuration of global "From" email
--

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, SECURE_ATTRIBUTE)
  VALUES (  11188,  'SYSTEM_MAIL_SERVER_FROM', 'SYSTEM_MAIL_SERVER_FROM',  0,  NULL,  'Mail: custom mail server "from"',
    'Custom mail server "from" email address.',  'Email', 'SYSTEM', 0, 0, 0, 0, 1);


--
--  Fixes for MySQL8
--

ALTER TABLE TSHOPPINGCARTSTATE RENAME COLUMN `EMPTY` TO IS_EMPTY;
-- ALTER TABLE TSHOPPINGCARTSTATE CHANGE   `EMPTY`    IS_EMPTY bit not null;



--
-- YC-1050 Enable setting at the fulfilment centre lever to force split backorder deliveries into individual items
--

alter table TWAREHOUSE add column FORCE_BACKORDER_SPLIT bit not null default 0;
alter table TWAREHOUSE add column FORCE_ALL_SPLIT bit not null default 0;
-- alter table TWAREHOUSE add column FORCE_BACKORDER_SPLIT smallint not null DEFAULT 0;
-- alter table TWAREHOUSE add column FORCE_ALL_SPLIT smallint not null DEFAULT 0;

--
-- YC-000 configuration for specific TSL protocol
--

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, SECURE_ATTRIBUTE)
  VALUES (  10982,  'SHOP_MAIL_SERVER_STARTTLS_V', 'SHOP_MAIL_SERVER_STARTTLS_V',  0,  NULL,  'Mail: force TSL (optional)',
    'Force specific TSL protocol (e.g. TLSv1.2)',  'String', 'SHOP', 0, 0, 0, 0, 1);

INSERT INTO TATTRIBUTE (ATTRIBUTE_ID, GUID, CODE, MANDATORY, VAL, NAME, DESCRIPTION, ETYPE, ATTRIBUTEGROUP, STORE, SEARCH, SEARCHPRIMARY, NAV, SECURE_ATTRIBUTE)
  VALUES (  11189,  'SYSTEM_MAIL_SERVER_STARTTLS_V', 'SYSTEM_MAIL_SERVER_STARTTLS_V',  0,  NULL,  'Mail: force TSL (optional)',
    'Force specific TSL protocol (e.g. TLSv1.2)',  'String', 'SYSTEM', 0, 0, 0, 0, 1);

