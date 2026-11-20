/**
 * Lookups: the late-tag sweep and the re-read by Message-ID, on the replay transport and as the OData
 * the live transport sends. The replay must answer exactly what Graph would for the same filter, or a
 * sandbox run proves a different program from the live one.
 */
import { describe, expect, it, vi } from 'vitest';

import { CONSENT_MESSAGE_EXPAND } from '../consent.js';

import {
    GraphCommunicationTransport,
    MESSAGE_ID_BATCH,
    MessageIdFilter,
    TaggedFilter,
    type GraphMessageReader,
} from '../providers/GraphCommunicationTransport.js';
import { RecordedMessageTransport } from '../providers/RecordedMessageTransport.js';

const BOX = 'rep@internal.test';
const payloads = [
    { id: 'a', internetMessageId: '<a@x>', categories: ['AIDP'], lastModifiedDateTime: '2026-11-01T00:00:00Z' },
    { id: 'b', internetMessageId: '<b@x>', categories: ['AIDP'], lastModifiedDateTime: '2026-11-09T00:00:00Z' },
    { id: 'c', internetMessageId: '<c@x>', categories: [], lastModifiedDateTime: '2026-11-09T00:00:00Z' },
];
const transport = new RecordedMessageTransport([{ Mailbox: BOX, Payloads: payloads, Provenance: 'test' }]);

describe('RecordedMessageTransport lookups', () => {
    it('Tagged returns tagged items modified at or after the instant, ignoring Since', async () => {
        const batch = await transport.Fetch({
            Mailbox: BOX,
            Since: new Date('2030-01-01T00:00:00Z'),
            Limit: 50,
            Lookup: { Kind: 'Tagged', Tag: 'aidp', ModifiedSince: new Date('2026-11-05T00:00:00Z') },
        });
        expect(batch.Payloads.map((p) => p.id)).toEqual(['b']);
    });

    it('MessageIds returns exactly the named messages, and an empty batch for none', async () => {
        const named = await transport.Fetch({ Mailbox: BOX, Since: null, Limit: 50, Lookup: { Kind: 'MessageIds', MessageIds: ['<c@x>', '<gone@x>'] } });
        expect(named.Payloads.map((p) => p.id)).toEqual(['c']);
        const none = await transport.Fetch({ Mailbox: BOX, Since: null, Limit: 50, Lookup: { Kind: 'MessageIds', MessageIds: ['<gone@x>'] } });
        expect(none.Payloads).toEqual([]);
    });

    it('a lookup that binds the limit is capped', async () => {
        const batch = await transport.Fetch({ Mailbox: BOX, Since: null, Limit: 1, Lookup: { Kind: 'Tagged', Tag: 'AIDP', ModifiedSince: null } });
        expect(batch.Capped).toBe(true);
    });
});

describe('live lookup filters', () => {
    it('TaggedFilter uses categories/any and escapes quotes', () => {
        expect(TaggedFilter("O'Brien", new Date('2026-11-05T00:00:00Z'))).toBe(
            "categories/any(c:c eq 'O''Brien') and lastModifiedDateTime ge 2026-11-05T00:00:00.000Z",
        );
        expect(TaggedFilter('AIDP', null)).toBe("categories/any(c:c eq 'AIDP')");
    });

    it('MessageIdFilter ORs the ids', () => {
        expect(MessageIdFilter(['<a@x>', '<b@x>'])).toBe("internetMessageId eq '<a@x>' or internetMessageId eq '<b@x>'");
    });
});

describe('GraphCommunicationTransport lookups — what reaches MJ', () => {
    function live(pages: Record<string, unknown>[][]) {
        const GetMessages = vi.fn<GraphMessageReader['GetMessages']>();
        for (const page of pages) GetMessages.mockResolvedValueOnce({ Success: true, SourceData: page });
        const transport = new GraphCommunicationTransport({
            ResolveCredential: async () => ({ tenantId: 't', clientId: 'c', clientSecret: 's' }),
            ResolveProvider: async () => ({ GetMessages }),
        });
        return { transport, GetMessages };
    }

    it('a Tagged lookup is one request with the tag filter and the consent $expand', async () => {
        const { transport, GetMessages } = live([[{ id: 'a' }]]);
        const since = new Date('2026-11-05T00:00:00Z');
        const batch = await transport.Fetch({ Mailbox: BOX, Since: null, Limit: 50, Lookup: { Kind: 'Tagged', Tag: 'AIDP', ModifiedSince: since } });
        expect(batch.Payloads).toEqual([{ id: 'a' }]);
        expect(GetMessages).toHaveBeenCalledTimes(1);
        expect(GetMessages.mock.calls[0][0]).toMatchObject({
            Identifier: BOX,
            NumMessages: 50,
            ContextData: { Filter: TaggedFilter('AIDP', since), Expand: CONSENT_MESSAGE_EXPAND },
        });
    });

    it('a MessageIds lookup is split into batches of MESSAGE_ID_BATCH', async () => {
        const ids = Array.from({ length: MESSAGE_ID_BATCH + 1 }, (_, i) => `<m${i}@x>`);
        const { transport, GetMessages } = live([[], []]);
        await transport.Fetch({ Mailbox: BOX, Since: null, Limit: 50, Lookup: { Kind: 'MessageIds', MessageIds: ids } });
        expect(GetMessages).toHaveBeenCalledTimes(2);
        expect(GetMessages.mock.calls[1][0].ContextData).toMatchObject({ Filter: MessageIdFilter([ids[MESSAGE_ID_BATCH]]) });
    });

    it('the window read asks for the consent $expand too', async () => {
        const { transport, GetMessages } = live([[]]);
        await transport.Fetch({ Mailbox: BOX, Since: null, Limit: 50 });
        expect(GetMessages.mock.calls[0][0].ContextData).toEqual({ Expand: CONSENT_MESSAGE_EXPAND });
    });

    it('a failed lookup throws, so the run fails closed instead of reading "no tags"', async () => {
        const GetMessages = vi.fn<GraphMessageReader['GetMessages']>().mockResolvedValue({ Success: false, ErrorMessage: 'Forbidden' });
        const transport = new GraphCommunicationTransport({
            ResolveCredential: async () => ({ tenantId: 't', clientId: 'c', clientSecret: 's' }),
            ResolveProvider: async () => ({ GetMessages }),
        });
        await expect(transport.Fetch({ Mailbox: BOX, Since: null, Limit: 50, Lookup: { Kind: 'Tagged', Tag: 'AIDP', ModifiedSince: null } })).rejects.toThrow('Forbidden');
    });
});
