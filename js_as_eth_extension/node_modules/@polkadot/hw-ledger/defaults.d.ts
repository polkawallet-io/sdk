import type Transport from '@ledgerhq/hw-transport';
import type { SubstrateApp } from '@zondax/ledger-substrate';
export declare const ledgerApps: Record<string, (transport: Transport) => SubstrateApp>;
