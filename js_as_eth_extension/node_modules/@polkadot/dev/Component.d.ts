import React from 'react';
interface Props {
    children: React.ReactNode;
    className?: string;
    label?: string;
}
declare function Component({ children, className, label }: Props): React.ReactElement<Props>;
declare const _default: React.MemoExoticComponent<typeof Component>;
export default _default;
