import Transport from '@ledgerhq/hw-transport';
export declare type LedgerTypes = 'hid' | 'u2f' | 'webusb';
export interface TransportDef {
    create(): Promise<Transport>;
    type: LedgerTypes;
}
