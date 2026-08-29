/** Quote a string for ExtraFilter. Not a substitute for parameters — ExtraFilter is a string. */
export function EscapeSql(value: string): string {
    return value.replace(/'/g, "''");
}

export function InList(values: readonly string[]): string {
    if (values.length === 0) {
        return `'00000000-0000-0000-0000-000000000000'`;
    }
    return values.map((v) => `'${EscapeSql(v)}'`).join(',');
}
