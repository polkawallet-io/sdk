import type { AddressSubject } from './types';
export declare function genericSubject(keyCreator: (address: string) => string, withTest?: boolean): AddressSubject;
