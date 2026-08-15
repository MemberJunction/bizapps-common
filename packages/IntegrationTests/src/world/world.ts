export interface WorldOrg {
    ID: string;
    Code: string;
    Name: string;
}

export interface WorldPerson {
    ID: string;
    Email: string;
    FirstName: string;
    LastName: string;
}

export interface WorldState {
    OrganizationTypeIDs: Record<string, string>;
    AddressTypeIDs: Record<string, string>;
    ContactTypeIDs: Record<string, string>;
    RelationshipTypeIDs: Record<string, string>;
    Organizations: Record<string, WorldOrg>;
    People: Record<string, WorldPerson>;
    Addresses: Record<string, string>;
}

let current: WorldState | null = null;

export function SetWorld(world: WorldState): void {
    current = world;
}

export function GetWorld(): WorldState | null {
    return current;
}

export function World(): WorldState {
    if (!current) {
        throw new Error('COM-WORLD has not been loaded. Run common-world.CW1 first.');
    }
    return current;
}
