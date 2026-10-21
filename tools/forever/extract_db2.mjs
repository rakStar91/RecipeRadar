// Downloads DB2 tables for a WoW Forever build straight from Blizzard's CDN (CASC)
// and dumps every row as JSON into <out>/<build>/<locale>/<Table>.json.
//
// Usage: node extract_db2.mjs [--product wow_classic_beta] [--region eu]
//                             [--locales enUS,deDE] [--out ./cache] [--adb <WoW>/_classic_beta_/Cache/ADB]
//                             [TableName ...]
//
// --adb applies the hotfixes from the client's own DBCache.bin (the base DB2 files carry placeholder
// values for many Forever recipes). The cache must match the downloaded build. String tables only use
// the cache of their own locale; numeric tables fall back to whichever locale cache exists.
import fs from 'node:fs/promises';
import path from 'node:path';
import { ADBReader, CASCClient, WDCReader, DBDParser } from '@rhyster/wow-casc-dbc';

const DEFAULT_TABLES = [
    'SkillLine', 'SkillLineAbility', 'SkillRaceClassInfo', 'TradeSkillCategory',
    'Spell', 'SpellName', 'SpellEffect', 'SpellReagents', 'SpellMisc',
    'Item', 'ItemSparse', 'ItemEffect', 'ItemXItemEffect',
    'Faction',
];
// Tables whose strings are localized; everything else is only fetched for the first locale.
const LOCALIZED = new Set(['Faction', 'SkillLine', 'SpellName', 'ItemSparse', 'TradeSkillCategory', 'Spell']);

const args = process.argv.slice(2);
const opts = { product: 'wow_classic_beta', region: 'eu', locales: 'enUS', out: './cache', adb: '' };
const tables = [];
for (let i = 0; i < args.length; i++) {
    if (args[i].startsWith('--')) opts[args[i].slice(2)] = args[++i];
    else tables.push(args[i]);
}
const wanted = tables.length ? tables : DEFAULT_TABLES;
const locales = opts.locales.split(',');

const version = await CASCClient.getProductVersion(opts.region, opts.product);
if (!version) throw new Error(`No version for ${opts.product}/${opts.region}`);
console.log(`Product ${opts.product} build ${version.VersionsName}`);

const client = new CASCClient(opts.region, opts.product, version);
await client.init();
await client.loadRemoteTACTKeys();
await client.loadRemoteListFile();

// Hotfix caches by locale, only accepted when they were written for exactly this build.
const adbByLocale = new Map();
if (opts.adb) {
    for (const entry of await fs.readdir(opts.adb, { withFileTypes: true })) {
        if (!entry.isDirectory()) continue;
        try {
            const adb = new ADBReader(await fs.readFile(path.join(opts.adb, entry.name, 'DBCache.bin')));
            if (adb.build === Number(version.BuildId)) adbByLocale.set(entry.name, adb);
            else console.warn(`Skipping ${entry.name} DBCache.bin: build ${adb.build} != ${version.BuildId}`);
        } catch (e) { console.warn(`Cannot read ${entry.name} DBCache.bin: ${e.message}`); }
    }
    console.log(`Hotfix caches: ${[...adbByLocale.keys()].join(', ') || 'none'}`);
}
const adbFor = (locale, table) => adbByLocale.get(locale)
    ?? (LOCALIZED.has(table) ? undefined : adbByLocale.values().next().value);

const jsonSafe = (_, v) => (typeof v === 'bigint' ? v.toString() : v);

for (const locale of locales) {
    const flag = CASCClient.LocaleFlags[locale];
    if (!flag) throw new Error(`Unknown locale ${locale}`);
    const dir = path.join(opts.out, version.VersionsName, locale);
    await fs.mkdir(dir, { recursive: true });

    for (const table of wanted) {
        if (locale !== locales[0] && !LOCALIZED.has(table)) continue;
        const fileDataID = client.getFileDataIDByName(`dbfilesclient/${table.toLowerCase()}.db2`);
        if (!fileDataID) { console.warn(`  ${table}: not in listfile`); continue; }
        const cKeys = client.getContentKeysByFileDataID(fileDataID) ?? [];
        const cKey = cKeys.find((k) => k.localeFlags & flag) ?? cKeys[0];
        if (!cKey) { console.warn(`  ${table}: no content key`); continue; }
        const result = await client.getFileByContentKey(cKey.cKey, true);
        const reader = new WDCReader(result.buffer, result.blocks, adbFor(locale, table));
        const parser = await DBDParser.parse(reader);
        const rows = {};
        for (const id of parser.getAllIDs()) rows[id] = parser.getRowData(id);
        await fs.writeFile(path.join(dir, `${table}.json`), JSON.stringify(rows, jsonSafe));
        console.log(`  ${locale} ${table}: ${Object.keys(rows).length} rows`);
    }
}
