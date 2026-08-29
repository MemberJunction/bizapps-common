/********************************************************************************
* ALL ENTITIES - TypeGraphQL Type Class Definition - AUTO GENERATED FILE
* Generated Entities and Resolvers for Server
*
*   >>> DO NOT MODIFY THIS FILE!!!!!!!!!!!!
*   >>> YOUR CHANGES WILL BE OVERWRITTEN
*   >>> THE NEXT TIME THIS FILE IS GENERATED
*
**********************************************************************************/
import { Arg, Ctx, Int, Query, Resolver, Field, Float, ObjectType, InputType, Mutation,
            PubSub, PubSubEngine, ResolverBase, RunViewByIDInput, RunViewByNameInput, RunDynamicViewInput,
            AppContext, KeyValuePairInput, DeleteOptionsInput, GraphQLTimestamp as Timestamp,
            GetReadOnlyProvider, GetReadWriteProvider, RestoreContextInput } from '@memberjunction/server';
import { Metadata, EntityPermissionType, CompositeKey, UserInfo } from '@memberjunction/core'

import { MaxLength } from 'class-validator';
import * as mj_core_schema_server_object_types from '@memberjunction/server'


import { mjBizAppsCommonActivityEntity, mjBizAppsCommonActivityFileEntity, mjBizAppsCommonActivityLinkEntity, mjBizAppsCommonActivitySyncConnectionRuleSetEntity, mjBizAppsCommonActivitySyncConnectionEntity, mjBizAppsCommonActivitySyncExclusionEntity, mjBizAppsCommonActivitySyncExtensionEntity, mjBizAppsCommonActivitySyncProviderTypeEntity, mjBizAppsCommonActivitySyncRuleSetEntity, mjBizAppsCommonActivitySyncRuleEntity, mjBizAppsCommonActivitySyncRunDetailEntity, mjBizAppsCommonActivitySyncRunEntity, mjBizAppsCommonActivityTypeEntity, mjBizAppsCommonAddressLinkEntity, mjBizAppsCommonAddressTypeEntity, mjBizAppsCommonAddressEntity, mjBizAppsCommonContactMethodEntity, mjBizAppsCommonContactTypeEntity, mjBizAppsCommonOrganizationTypeEntity, mjBizAppsCommonOrganizationEntity, mjBizAppsCommonPersonEntity, mjBizAppsCommonRelationshipTypeEntity, mjBizAppsCommonRelationshipEntity } from '@mj-biz-apps/common-entities';
    

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Activities
//****************************************************************************
@ObjectType({ description: `One interaction that happened between people, about records. Timeline card — not a blob store, not a task, not field-level audit. Duration is derived from StartedAt/EndedAt.` })
export class mjBizAppsCommonActivity_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field() 
    @MaxLength(36)
    ActivityTypeID: string;
        
    @Field({description: `Sort key for every timeline. Instant events use the date/time of the event.`}) 
    StartedAt: Date;
        
    @Field({nullable: true, description: `End of a meeting/call. Leave null for a point-in-time log. Must be >= StartedAt when set. Duration is derived; do not store it.`}) 
    EndedAt?: Date;
        
    @Field({description: `Subject / one-line card title (e.g. Called Jane about renewal).`}) 
    @MaxLength(500)
    Title: string;
        
    @Field({nullable: true, description: `Notes or a short excerpt. Not the full email body — that lives on an ActivityFile of Kind Body.`}) 
    Description?: string;
        
    @Field({description: `Inbound, Outbound, or Internal. Channel lives on ActivityType; direction lives here so inbound email is a filter, not a type explosion.`}) 
    @MaxLength(20)
    Direction: string;
        
    @Field({description: `Logged (default for a past event), Scheduled, Completed, Cancelled, or Failed.`}) 
    @MaxLength(20)
    Status: string;
        
    @Field({nullable: true, description: `Optional disposition: Connected, LeftVoicemail, NoAnswer, NoShow, Bounced, Interested, NotInterested. A filter, not a type.`}) 
    @MaxLength(40)
    Outcome?: string;
        
    @Field({description: `Internal (anyone who can read a Regarding record) or Private (LoggedByUserID only, until a PermissionEngine domain exists). Manual default is Internal; synced mail should default Private in the engine.`}) 
    @MaxLength(20)
    Visibility: string;
        
    @Field({description: `How the row was written: Manual, System, or Integration.`}) 
    @MaxLength(20)
    Source: string;
        
    @Field({nullable: true, description: `Provider name for idempotent sync (Microsoft365, Gmail, Zoom). Required when ExternalID is set.`}) 
    @MaxLength(80)
    SourceSystem?: string;
        
    @Field({nullable: true, description: `Provider message/event id. Unique with SourceSystem where set — never dedup by subject.`}) 
    @MaxLength(400)
    ExternalID?: string;
        
    @Field({nullable: true, description: `Email or calendar thread id used to group replies.`}) 
    @MaxLength(400)
    ExternalThreadID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    ParentActivityID?: string;
        
    @Field() 
    @MaxLength(36)
    LoggedByUserID: string;
        
    @Field({nullable: true, description: `Meeting place as text. Optional AddressID is the structured location.`}) 
    @MaxLength(500)
    Location?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    AddressID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    ActivitySyncConnectionID?: string;
        
    @Field({nullable: true, description: `JSON extras that are not query predicates: MessageID, InReplyTo, MeetingURL, Mailbox, Folder, CalendarEventID. See ActivityDetails.`}) 
    Details?: string;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
    @Field() 
    @MaxLength(100)
    ActivityType: string;
        
    @Field({nullable: true}) 
    @MaxLength(500)
    ParentActivity?: string;
        
    @Field() 
    @MaxLength(100)
    LoggedByUser: string;
        
    @Field({nullable: true}) 
    @MaxLength(255)
    Address?: string;
        
    @Field({nullable: true}) 
    @MaxLength(200)
    ActivitySyncConnection?: string;
        
    @Field(() => Float, {nullable: true}) 
    _mj__Latitude?: number;
        
    @Field(() => Float, {nullable: true}) 
    _mj__Longitude?: number;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    RootParentActivityID?: string;
        
    @Field(() => Int, {nullable: true}) 
    ParentActivityIDDepth?: number;
        
    @Field({nullable: true}) 
    ParentActivityIDPath?: string;
        
    @Field(() => Boolean, {nullable: true}) 
    ParentActivityIDIsLeaf?: boolean;
        
    @Field(() => Int, {nullable: true}) 
    ParentActivityIDChildCount?: number;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activities
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonActivityInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    ActivityTypeID?: string;

    @Field({ nullable: true })
    StartedAt?: Date;

    @Field({ nullable: true })
    EndedAt: Date | null;

    @Field({ nullable: true })
    Title?: string;

    @Field({ nullable: true })
    Description: string | null;

    @Field({ nullable: true })
    Direction?: string;

    @Field({ nullable: true })
    Status?: string;

    @Field({ nullable: true })
    Outcome: string | null;

    @Field({ nullable: true })
    Visibility?: string;

    @Field({ nullable: true })
    Source?: string;

    @Field({ nullable: true })
    SourceSystem: string | null;

    @Field({ nullable: true })
    ExternalID: string | null;

    @Field({ nullable: true })
    ExternalThreadID: string | null;

    @Field({ nullable: true })
    ParentActivityID: string | null;

    @Field({ nullable: true })
    LoggedByUserID?: string;

    @Field({ nullable: true })
    Location: string | null;

    @Field({ nullable: true })
    AddressID: string | null;

    @Field({ nullable: true })
    ActivitySyncConnectionID: string | null;

    @Field({ nullable: true })
    Details: string | null;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activities
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonActivityInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    ActivityTypeID?: string;

    @Field({ nullable: true })
    StartedAt?: Date;

    @Field({ nullable: true })
    EndedAt?: Date | null;

    @Field({ nullable: true })
    Title?: string;

    @Field({ nullable: true })
    Description?: string | null;

    @Field({ nullable: true })
    Direction?: string;

    @Field({ nullable: true })
    Status?: string;

    @Field({ nullable: true })
    Outcome?: string | null;

    @Field({ nullable: true })
    Visibility?: string;

    @Field({ nullable: true })
    Source?: string;

    @Field({ nullable: true })
    SourceSystem?: string | null;

    @Field({ nullable: true })
    ExternalID?: string | null;

    @Field({ nullable: true })
    ExternalThreadID?: string | null;

    @Field({ nullable: true })
    ParentActivityID?: string | null;

    @Field({ nullable: true })
    LoggedByUserID?: string;

    @Field({ nullable: true })
    Location?: string | null;

    @Field({ nullable: true })
    AddressID?: string | null;

    @Field({ nullable: true })
    ActivitySyncConnectionID?: string | null;

    @Field({ nullable: true })
    Details?: string | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Activities
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonActivityViewResult {
    @Field(() => [mjBizAppsCommonActivity_])
    Results: mjBizAppsCommonActivity_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonActivity_)
export class mjBizAppsCommonActivityResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonActivityViewResult)
    async RunmjBizAppsCommonActivityViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivityViewResult)
    async RunmjBizAppsCommonActivityViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivityViewResult)
    async RunmjBizAppsCommonActivityDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Activities';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonActivity_, { nullable: true })
    async mjBizAppsCommonActivity(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonActivity_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Activities', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwActivities')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Activities', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Activities', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonActivity_)
    async CreatemjBizAppsCommonActivity(
        @Arg('input', () => CreatemjBizAppsCommonActivityInput) input: CreatemjBizAppsCommonActivityInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Activities', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonActivity_)
    async UpdatemjBizAppsCommonActivity(
        @Arg('input', () => UpdatemjBizAppsCommonActivityInput) input: UpdatemjBizAppsCommonActivityInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Activities', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonActivity_)
    async DeletemjBizAppsCommonActivity(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Activities', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Activity Files
//****************************************************************************
@ObjectType({ description: `Join from an Activity to an MJ File. Kind Body is the full MIME/HTML (at most one per activity); Attachment and Ics are extras. Deleting the activity drops the join, not the File.` })
export class mjBizAppsCommonActivityFile_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field() 
    @MaxLength(36)
    ActivityID: string;
        
    @Field() 
    @MaxLength(36)
    FileID: string;
        
    @Field({description: `Body (full MIME/HTML, at most one per activity), Attachment, or Ics.`}) 
    @MaxLength(20)
    Kind: string;
        
    @Field(() => Int, {description: `Display order of attachments.`}) 
    Sequence: number;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
    @Field() 
    @MaxLength(500)
    Activity: string;
        
    @Field() 
    @MaxLength(500)
    File: string;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Files
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonActivityFileInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    ActivityID?: string;

    @Field({ nullable: true })
    FileID?: string;

    @Field({ nullable: true })
    Kind?: string;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Files
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonActivityFileInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    ActivityID?: string;

    @Field({ nullable: true })
    FileID?: string;

    @Field({ nullable: true })
    Kind?: string;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Activity Files
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonActivityFileViewResult {
    @Field(() => [mjBizAppsCommonActivityFile_])
    Results: mjBizAppsCommonActivityFile_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonActivityFile_)
export class mjBizAppsCommonActivityFileResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonActivityFileViewResult)
    async RunmjBizAppsCommonActivityFileViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivityFileViewResult)
    async RunmjBizAppsCommonActivityFileViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivityFileViewResult)
    async RunmjBizAppsCommonActivityFileDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Activity Files';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonActivityFile_, { nullable: true })
    async mjBizAppsCommonActivityFile(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonActivityFile_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Activity Files', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwActivityFiles')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Activity Files', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Activity Files', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonActivityFile_)
    async CreatemjBizAppsCommonActivityFile(
        @Arg('input', () => CreatemjBizAppsCommonActivityFileInput) input: CreatemjBizAppsCommonActivityFileInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Activity Files', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonActivityFile_)
    async UpdatemjBizAppsCommonActivityFile(
        @Arg('input', () => UpdatemjBizAppsCommonActivityFileInput) input: UpdatemjBizAppsCommonActivityFileInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Activity Files', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonActivityFile_)
    async DeletemjBizAppsCommonActivityFile(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Activity Files', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Activity Links
//****************************************************************************
@ObjectType({ description: `Attaches an Activity to a resolved MJ record (EntityID + RecordID) or an unresolved identity (email/phone/external user) the matcher has not stamped yet. Role says whether the link is Regarding, a participant, or an email/meeting mailbox role.` })
export class mjBizAppsCommonActivityLink_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field() 
    @MaxLength(36)
    ActivityID: string;
        
    @Field({description: `Why this record is on the activity: Regarding (what it is about), Participant, From/To/Cc/Bcc, Organizer/Attendee, or LoggedFor (the mailbox it was filed under).`}) 
    @MaxLength(30)
    Role: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    EntityID?: string;
        
    @Field({nullable: true, description: `Primary key of the resolved record. NVARCHAR so composite keys work. Required with EntityID; must be null when the link is an unresolved identity.`}) 
    @MaxLength(450)
    RecordID?: string;
        
    @Field({nullable: true, description: `Email, Phone, or ExternalUser. Set with IdentityValue when the participant has not been matched to a Person/Org yet.`}) 
    @MaxLength(20)
    IdentityKind?: string;
        
    @Field({nullable: true, description: `The unmatched address, phone, or provider user id. A later matcher stamps EntityID/RecordID from ContactMethod.Value and clears these.`}) 
    @MaxLength(320)
    IdentityValue?: string;
        
    @Field(() => Int, {description: `Display order within a role (To, then Cc, …).`}) 
    Sequence: number;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
    @Field() 
    @MaxLength(500)
    Activity: string;
        
    @Field({nullable: true}) 
    @MaxLength(255)
    Entity?: string;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Links
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonActivityLinkInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    ActivityID?: string;

    @Field({ nullable: true })
    Role?: string;

    @Field({ nullable: true })
    EntityID: string | null;

    @Field({ nullable: true })
    RecordID: string | null;

    @Field({ nullable: true })
    IdentityKind: string | null;

    @Field({ nullable: true })
    IdentityValue: string | null;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Links
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonActivityLinkInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    ActivityID?: string;

    @Field({ nullable: true })
    Role?: string;

    @Field({ nullable: true })
    EntityID?: string | null;

    @Field({ nullable: true })
    RecordID?: string | null;

    @Field({ nullable: true })
    IdentityKind?: string | null;

    @Field({ nullable: true })
    IdentityValue?: string | null;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Activity Links
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonActivityLinkViewResult {
    @Field(() => [mjBizAppsCommonActivityLink_])
    Results: mjBizAppsCommonActivityLink_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonActivityLink_)
export class mjBizAppsCommonActivityLinkResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonActivityLinkViewResult)
    async RunmjBizAppsCommonActivityLinkViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivityLinkViewResult)
    async RunmjBizAppsCommonActivityLinkViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivityLinkViewResult)
    async RunmjBizAppsCommonActivityLinkDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Activity Links';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonActivityLink_, { nullable: true })
    async mjBizAppsCommonActivityLink(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonActivityLink_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Activity Links', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwActivityLinks')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Activity Links', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Activity Links', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonActivityLink_)
    async CreatemjBizAppsCommonActivityLink(
        @Arg('input', () => CreatemjBizAppsCommonActivityLinkInput) input: CreatemjBizAppsCommonActivityLinkInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Activity Links', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonActivityLink_)
    async UpdatemjBizAppsCommonActivityLink(
        @Arg('input', () => UpdatemjBizAppsCommonActivityLinkInput) input: UpdatemjBizAppsCommonActivityLinkInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Activity Links', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonActivityLink_)
    async DeletemjBizAppsCommonActivityLink(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Activity Links', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Activity Sync Connection Rule Sets
//****************************************************************************
@ObjectType({ description: `Binds a rule set to a connection, ordered. Many-to-many so a mailbox composes an org-wide baseline, a team overlay, and anything specific to itself — rather than owning one private copy of everything.` })
export class mjBizAppsCommonActivitySyncConnectionRuleSet_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field() 
    @MaxLength(36)
    ActivitySyncConnectionID: string;
        
    @Field({description: `The rule set bound to this connection. A mailbox composes several sets (org baseline, team overlay, mailbox-specific) through this join; Sequence on the binding is the evaluation order.`}) 
    @MaxLength(36)
    ActivitySyncRuleSetID: string;
        
    @Field(() => Int) 
    Sequence: number;
        
    @Field(() => Boolean) 
    IsEnabled: boolean;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
    @Field() 
    @MaxLength(200)
    ActivitySyncConnection: string;
        
    @Field() 
    @MaxLength(200)
    ActivitySyncRuleSet: string;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Sync Connection Rule Sets
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonActivitySyncConnectionRuleSetInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    ActivitySyncConnectionID?: string;

    @Field({ nullable: true })
    ActivitySyncRuleSetID?: string;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field(() => Boolean, { nullable: true })
    IsEnabled?: boolean;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Sync Connection Rule Sets
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonActivitySyncConnectionRuleSetInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    ActivitySyncConnectionID?: string;

    @Field({ nullable: true })
    ActivitySyncRuleSetID?: string;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field(() => Boolean, { nullable: true })
    IsEnabled?: boolean;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Activity Sync Connection Rule Sets
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonActivitySyncConnectionRuleSetViewResult {
    @Field(() => [mjBizAppsCommonActivitySyncConnectionRuleSet_])
    Results: mjBizAppsCommonActivitySyncConnectionRuleSet_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonActivitySyncConnectionRuleSet_)
export class mjBizAppsCommonActivitySyncConnectionRuleSetResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonActivitySyncConnectionRuleSetViewResult)
    async RunmjBizAppsCommonActivitySyncConnectionRuleSetViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivitySyncConnectionRuleSetViewResult)
    async RunmjBizAppsCommonActivitySyncConnectionRuleSetViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivitySyncConnectionRuleSetViewResult)
    async RunmjBizAppsCommonActivitySyncConnectionRuleSetDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Activity Sync Connection Rule Sets';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonActivitySyncConnectionRuleSet_, { nullable: true })
    async mjBizAppsCommonActivitySyncConnectionRuleSet(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonActivitySyncConnectionRuleSet_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Activity Sync Connection Rule Sets', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwActivitySyncConnectionRuleSets')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Activity Sync Connection Rule Sets', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Activity Sync Connection Rule Sets', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonActivitySyncConnectionRuleSet_)
    async CreatemjBizAppsCommonActivitySyncConnectionRuleSet(
        @Arg('input', () => CreatemjBizAppsCommonActivitySyncConnectionRuleSetInput) input: CreatemjBizAppsCommonActivitySyncConnectionRuleSetInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Activity Sync Connection Rule Sets', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonActivitySyncConnectionRuleSet_)
    async UpdatemjBizAppsCommonActivitySyncConnectionRuleSet(
        @Arg('input', () => UpdatemjBizAppsCommonActivitySyncConnectionRuleSetInput) input: UpdatemjBizAppsCommonActivitySyncConnectionRuleSetInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Activity Sync Connection Rule Sets', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonActivitySyncConnectionRuleSet_)
    async DeletemjBizAppsCommonActivitySyncConnectionRuleSet(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Activity Sync Connection Rule Sets', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Activity Sync Connections
//****************************************************************************
@ObjectType({ description: `A mailbox, calendar, or other provider connection that writes Activities. CredentialsRef is an MJ Credentials engine key — never a secret at rest.` })
export class mjBizAppsCommonActivitySyncConnection_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field({description: `Display name of the connection (e.g. Amith / Microsoft 365).`}) 
    @MaxLength(200)
    Name: string;
        
    @Field({nullable: true, description: `DEPRECATED — use ActivitySyncProviderTypeID. Retained nullable so a published host keeps working; removed in the next major.`}) 
    @MaxLength(40)
    Provider?: string;
        
    @Field({description: `Active, Paused, Error, or Disabled.`}) 
    @MaxLength(20)
    Status: string;
        
    @Field({description: `Inbound (pull into CRM), Outbound, or Bidirectional.`}) 
    @MaxLength(20)
    Direction: string;
        
    @Field() 
    @MaxLength(36)
    OwnerUserID: string;
        
    @Field({nullable: true, description: `MJ Credentials engine key. NEVER a secret value at rest.`}) 
    @MaxLength(200)
    CredentialsRef?: string;
        
    @Field({nullable: true, description: `Mailbox address this connection reads (jane@acme.com).`}) 
    @MaxLength(320)
    Mailbox?: string;
        
    @Field({nullable: true, description: `When the engine last completed a sync for this connection.`}) 
    LastSyncAt?: Date;
        
    @Field({nullable: true, description: `Most recent sync error, if Status is Error.`}) 
    LastError?: string;
        
    @Field({nullable: true, description: `JSON provider extras (TenantID, MailboxFolder, CalendarID, IncludeCalendar, IncludeMail). See ActivitySyncConnectionSettings.`}) 
    Settings?: string;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
    @Field({nullable: true, description: `The provider type this connection reads. Supersedes the Provider string column, whose CHECK constraint made every new source a migration to Common.`}) 
    @MaxLength(36)
    ActivitySyncProviderTypeID?: string;
        
    @Field({nullable: true, description: `Activation window. Combines with Status: a connection syncs only when Status = Active AND now is within [StartAt, EndAt], treating either bound as open when null. Lets a mailbox be provisioned ahead of time, or retired on a date, without anyone remembering to flip a switch.`}) 
    StartAt?: Date;
        
    @Field({nullable: true, description: `End of the activation window; see StartAt. Null means open-ended.`}) 
    EndAt?: Date;
        
    @Field({nullable: true, description: `Per-connection override of the provider type's DefaultSkippedContentPolicy. Null inherits. This is the knob for "this one mailbox is sensitive" without changing the estate.`}) 
    @MaxLength(20)
    SkippedContentPolicy?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    EncryptionKeyID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    StorageProviderID?: string;
        
    @Field(() => Int, {nullable: true}) 
    MaxAttachmentBytes?: number;
        
    @Field() 
    @MaxLength(100)
    OwnerUser: string;
        
    @Field({nullable: true}) 
    @MaxLength(100)
    ActivitySyncProviderType?: string;
        
    @Field({nullable: true}) 
    @MaxLength(100)
    EncryptionKey?: string;
        
    @Field({nullable: true}) 
    @MaxLength(50)
    StorageProvider?: string;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Sync Connections
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonActivitySyncConnectionInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Provider: string | null;

    @Field({ nullable: true })
    Status?: string;

    @Field({ nullable: true })
    Direction?: string;

    @Field({ nullable: true })
    OwnerUserID?: string;

    @Field({ nullable: true })
    CredentialsRef: string | null;

    @Field({ nullable: true })
    Mailbox: string | null;

    @Field({ nullable: true })
    LastSyncAt: Date | null;

    @Field({ nullable: true })
    LastError: string | null;

    @Field({ nullable: true })
    Settings: string | null;

    @Field({ nullable: true })
    ActivitySyncProviderTypeID: string | null;

    @Field({ nullable: true })
    StartAt: Date | null;

    @Field({ nullable: true })
    EndAt: Date | null;

    @Field({ nullable: true })
    SkippedContentPolicy: string | null;

    @Field({ nullable: true })
    EncryptionKeyID: string | null;

    @Field({ nullable: true })
    StorageProviderID: string | null;

    @Field(() => Int, { nullable: true })
    MaxAttachmentBytes: number | null;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Sync Connections
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonActivitySyncConnectionInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Provider?: string | null;

    @Field({ nullable: true })
    Status?: string;

    @Field({ nullable: true })
    Direction?: string;

    @Field({ nullable: true })
    OwnerUserID?: string;

    @Field({ nullable: true })
    CredentialsRef?: string | null;

    @Field({ nullable: true })
    Mailbox?: string | null;

    @Field({ nullable: true })
    LastSyncAt?: Date | null;

    @Field({ nullable: true })
    LastError?: string | null;

    @Field({ nullable: true })
    Settings?: string | null;

    @Field({ nullable: true })
    ActivitySyncProviderTypeID?: string | null;

    @Field({ nullable: true })
    StartAt?: Date | null;

    @Field({ nullable: true })
    EndAt?: Date | null;

    @Field({ nullable: true })
    SkippedContentPolicy?: string | null;

    @Field({ nullable: true })
    EncryptionKeyID?: string | null;

    @Field({ nullable: true })
    StorageProviderID?: string | null;

    @Field(() => Int, { nullable: true })
    MaxAttachmentBytes?: number | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Activity Sync Connections
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonActivitySyncConnectionViewResult {
    @Field(() => [mjBizAppsCommonActivitySyncConnection_])
    Results: mjBizAppsCommonActivitySyncConnection_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonActivitySyncConnection_)
export class mjBizAppsCommonActivitySyncConnectionResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonActivitySyncConnectionViewResult)
    async RunmjBizAppsCommonActivitySyncConnectionViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivitySyncConnectionViewResult)
    async RunmjBizAppsCommonActivitySyncConnectionViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivitySyncConnectionViewResult)
    async RunmjBizAppsCommonActivitySyncConnectionDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Activity Sync Connections';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonActivitySyncConnection_, { nullable: true })
    async mjBizAppsCommonActivitySyncConnection(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonActivitySyncConnection_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Activity Sync Connections', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwActivitySyncConnections')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Activity Sync Connections', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Activity Sync Connections', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonActivitySyncConnection_)
    async CreatemjBizAppsCommonActivitySyncConnection(
        @Arg('input', () => CreatemjBizAppsCommonActivitySyncConnectionInput) input: CreatemjBizAppsCommonActivitySyncConnectionInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Activity Sync Connections', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonActivitySyncConnection_)
    async UpdatemjBizAppsCommonActivitySyncConnection(
        @Arg('input', () => UpdatemjBizAppsCommonActivitySyncConnectionInput) input: UpdatemjBizAppsCommonActivitySyncConnectionInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Activity Sync Connections', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonActivitySyncConnection_)
    async DeletemjBizAppsCommonActivitySyncConnection(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Activity Sync Connections', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Activity Sync Exclusions
//****************************************************************************
@ObjectType({ description: `Never-ingest list, by identity: an email address, a phone number, a social handle, or a whole domain. Rows rather than a delimited string because an exclusion that cannot be queried cannot be audited, and this is precisely what a legal hold, an HR matter or an opt-out has to be able to prove. Scoped to a rule set, or global when ActivitySyncRuleSetID is null.` })
export class mjBizAppsCommonActivitySyncExclusion_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field({nullable: true, description: `Optional rule set this exclusion belongs to. Null means global — the identity is never ingested on any connection. A legal hold or opt-out is usually global; a mailbox-specific mute is not.`}) 
    @MaxLength(36)
    ActivitySyncRuleSetID?: string;
        
    @Field() 
    @MaxLength(20)
    IdentityKind: string;
        
    @Field() 
    @MaxLength(320)
    IdentityValue: string;
        
    @Field({nullable: true, description: `Optional link to the Person this identity belongs to. Optional because an address is often excluded before anyone knows whose it is, and because a Person has several ContactMethods — the identity is the durable key here, not the record.`}) 
    @MaxLength(36)
    PersonID?: string;
        
    @Field({nullable: true}) 
    Reason?: string;
        
    @Field({nullable: true}) 
    EffectiveFrom?: Date;
        
    @Field({nullable: true}) 
    EffectiveTo?: Date;
        
    @Field(() => Boolean) 
    IsEnabled: boolean;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
    @Field({nullable: true}) 
    @MaxLength(200)
    ActivitySyncRuleSet?: string;
        
    @Field({nullable: true}) 
    @MaxLength(201)
    Person?: string;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Sync Exclusions
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonActivitySyncExclusionInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    ActivitySyncRuleSetID: string | null;

    @Field({ nullable: true })
    IdentityKind?: string;

    @Field({ nullable: true })
    IdentityValue?: string;

    @Field({ nullable: true })
    PersonID: string | null;

    @Field({ nullable: true })
    Reason: string | null;

    @Field({ nullable: true })
    EffectiveFrom: Date | null;

    @Field({ nullable: true })
    EffectiveTo: Date | null;

    @Field(() => Boolean, { nullable: true })
    IsEnabled?: boolean;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Sync Exclusions
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonActivitySyncExclusionInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    ActivitySyncRuleSetID?: string | null;

    @Field({ nullable: true })
    IdentityKind?: string;

    @Field({ nullable: true })
    IdentityValue?: string;

    @Field({ nullable: true })
    PersonID?: string | null;

    @Field({ nullable: true })
    Reason?: string | null;

    @Field({ nullable: true })
    EffectiveFrom?: Date | null;

    @Field({ nullable: true })
    EffectiveTo?: Date | null;

    @Field(() => Boolean, { nullable: true })
    IsEnabled?: boolean;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Activity Sync Exclusions
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonActivitySyncExclusionViewResult {
    @Field(() => [mjBizAppsCommonActivitySyncExclusion_])
    Results: mjBizAppsCommonActivitySyncExclusion_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonActivitySyncExclusion_)
export class mjBizAppsCommonActivitySyncExclusionResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonActivitySyncExclusionViewResult)
    async RunmjBizAppsCommonActivitySyncExclusionViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivitySyncExclusionViewResult)
    async RunmjBizAppsCommonActivitySyncExclusionViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivitySyncExclusionViewResult)
    async RunmjBizAppsCommonActivitySyncExclusionDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Activity Sync Exclusions';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonActivitySyncExclusion_, { nullable: true })
    async mjBizAppsCommonActivitySyncExclusion(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonActivitySyncExclusion_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Activity Sync Exclusions', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwActivitySyncExclusions')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Activity Sync Exclusions', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Activity Sync Exclusions', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonActivitySyncExclusion_)
    async CreatemjBizAppsCommonActivitySyncExclusion(
        @Arg('input', () => CreatemjBizAppsCommonActivitySyncExclusionInput) input: CreatemjBizAppsCommonActivitySyncExclusionInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Activity Sync Exclusions', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonActivitySyncExclusion_)
    async UpdatemjBizAppsCommonActivitySyncExclusion(
        @Arg('input', () => UpdatemjBizAppsCommonActivitySyncExclusionInput) input: UpdatemjBizAppsCommonActivitySyncExclusionInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Activity Sync Exclusions', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonActivitySyncExclusion_)
    async DeletemjBizAppsCommonActivitySyncExclusion(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Activity Sync Exclusions', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Activity Sync Extensions
//****************************************************************************
@ObjectType({ description: `Registration of an in-process enrichment plugin that runs inside the Activity write transaction. Common ships this table; each consumer app ships its own rows, so a downstream app adds links (a deal, a campaign) without Common knowing it exists. Extensions ENRICH — they never veto an activity, because qualification has already run and capture must not depend on which apps are installed.` })
export class mjBizAppsCommonActivitySyncExtension_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field() 
    @MaxLength(200)
    Name: string;
        
    @Field({nullable: true}) 
    Description?: string;
        
    @Field() 
    @MaxLength(200)
    DriverClass: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    ActivitySyncConnectionID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    ActivitySyncProviderTypeID?: string;
        
    @Field(() => Int, {description: `Ascending run order. REQUIRED rather than incidental: two extensions both adding links must not depend on registration order, which varies with package load order and is not reproducible.`}) 
    Sequence: number;
        
    @Field({description: `What happens when this extension throws. Skip (the default) records the error and commits the activity without the enrichment; Abort rolls the whole write back. Skip is the default because the activity is worth more than the enrichment, and one buggy consumer app must not be able to halt ingestion for every other app on the host.`}) 
    @MaxLength(20)
    FailurePolicy: string;
        
    @Field(() => Int) 
    TimeoutMS: number;
        
    @Field(() => Boolean) 
    IsEnabled: boolean;
        
    @Field({nullable: true}) 
    LastRunAt?: Date;
        
    @Field({nullable: true}) 
    LastError?: string;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
    @Field({nullable: true}) 
    @MaxLength(200)
    ActivitySyncConnection?: string;
        
    @Field({nullable: true}) 
    @MaxLength(100)
    ActivitySyncProviderType?: string;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Sync Extensions
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonActivitySyncExtensionInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description: string | null;

    @Field({ nullable: true })
    DriverClass?: string;

    @Field({ nullable: true })
    ActivitySyncConnectionID: string | null;

    @Field({ nullable: true })
    ActivitySyncProviderTypeID: string | null;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field({ nullable: true })
    FailurePolicy?: string;

    @Field(() => Int, { nullable: true })
    TimeoutMS?: number;

    @Field(() => Boolean, { nullable: true })
    IsEnabled?: boolean;

    @Field({ nullable: true })
    LastRunAt: Date | null;

    @Field({ nullable: true })
    LastError: string | null;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Sync Extensions
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonActivitySyncExtensionInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description?: string | null;

    @Field({ nullable: true })
    DriverClass?: string;

    @Field({ nullable: true })
    ActivitySyncConnectionID?: string | null;

    @Field({ nullable: true })
    ActivitySyncProviderTypeID?: string | null;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field({ nullable: true })
    FailurePolicy?: string;

    @Field(() => Int, { nullable: true })
    TimeoutMS?: number;

    @Field(() => Boolean, { nullable: true })
    IsEnabled?: boolean;

    @Field({ nullable: true })
    LastRunAt?: Date | null;

    @Field({ nullable: true })
    LastError?: string | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Activity Sync Extensions
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonActivitySyncExtensionViewResult {
    @Field(() => [mjBizAppsCommonActivitySyncExtension_])
    Results: mjBizAppsCommonActivitySyncExtension_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonActivitySyncExtension_)
export class mjBizAppsCommonActivitySyncExtensionResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonActivitySyncExtensionViewResult)
    async RunmjBizAppsCommonActivitySyncExtensionViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivitySyncExtensionViewResult)
    async RunmjBizAppsCommonActivitySyncExtensionViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivitySyncExtensionViewResult)
    async RunmjBizAppsCommonActivitySyncExtensionDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Activity Sync Extensions';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonActivitySyncExtension_, { nullable: true })
    async mjBizAppsCommonActivitySyncExtension(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonActivitySyncExtension_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Activity Sync Extensions', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwActivitySyncExtensions')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Activity Sync Extensions', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Activity Sync Extensions', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonActivitySyncExtension_)
    async CreatemjBizAppsCommonActivitySyncExtension(
        @Arg('input', () => CreatemjBizAppsCommonActivitySyncExtensionInput) input: CreatemjBizAppsCommonActivitySyncExtensionInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Activity Sync Extensions', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonActivitySyncExtension_)
    async UpdatemjBizAppsCommonActivitySyncExtension(
        @Arg('input', () => UpdatemjBizAppsCommonActivitySyncExtensionInput) input: UpdatemjBizAppsCommonActivitySyncExtensionInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Activity Sync Extensions', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonActivitySyncExtension_)
    async DeletemjBizAppsCommonActivitySyncExtension(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Activity Sync Extensions', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Activity Sync Provider Types
//****************************************************************************
@ObjectType({ description: `A kind of activity source (Microsoft365, Gmail, Twilio SMS, LinkedIn, …). Provider identity is DATA, not a CHECK constraint, so a new source is a new plugin package plus a metadata row — never a migration to Common. Also carries the DEFAULTS an operator should set once per provider rather than per mailbox: storage, encryption key, attachment cap, and what an undecided qualification verdict means.` })
export class mjBizAppsCommonActivitySyncProviderType_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field() 
    @MaxLength(60)
    Code: string;
        
    @Field() 
    @MaxLength(100)
    Name: string;
        
    @Field({nullable: true}) 
    Description?: string;
        
    @Field({nullable: true}) 
    @MaxLength(200)
    DriverClass?: string;
        
    @Field({nullable: true}) 
    @MaxLength(100)
    IconClass?: string;
        
    @Field({nullable: true}) 
    SupportedKinds?: string;
        
    @Field({description: `What an Undecided qualification verdict means for this provider once every rule stage has abstained. Exclude (the default) fails CLOSED — correct for anything mailbox-shaped, where capturing a private message is worse than missing a business one.`}) 
    @MaxLength(20)
    DefaultQualificationPolicy: string;
        
    @Field({description: `Whether a SKIPPED message may have content retained for audit, and how much. None keeps only the opaque external id and the decision. SubjectEncrypted and FullEncrypted additionally keep ciphertext, and are only valid with DefaultEncryptionKeyID set — enforced by CK_ActivitySyncProviderType_KeyRequired. Overridable per connection.`}) 
    @MaxLength(20)
    DefaultSkippedContentPolicy: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    DefaultEncryptionKeyID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    DefaultStorageProviderID?: string;
        
    @Field(() => Int, {nullable: true}) 
    DefaultMaxAttachmentBytes?: number;
        
    @Field(() => Int) 
    Sequence: number;
        
    @Field(() => Boolean) 
    IsSystem: boolean;
        
    @Field(() => Boolean) 
    IsActive: boolean;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
    @Field({nullable: true}) 
    @MaxLength(100)
    DefaultEncryptionKey?: string;
        
    @Field({nullable: true}) 
    @MaxLength(50)
    DefaultStorageProvider?: string;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Sync Provider Types
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonActivitySyncProviderTypeInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    Code?: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description: string | null;

    @Field({ nullable: true })
    DriverClass: string | null;

    @Field({ nullable: true })
    IconClass: string | null;

    @Field({ nullable: true })
    SupportedKinds: string | null;

    @Field({ nullable: true })
    DefaultQualificationPolicy?: string;

    @Field({ nullable: true })
    DefaultSkippedContentPolicy?: string;

    @Field({ nullable: true })
    DefaultEncryptionKeyID: string | null;

    @Field({ nullable: true })
    DefaultStorageProviderID: string | null;

    @Field(() => Int, { nullable: true })
    DefaultMaxAttachmentBytes: number | null;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field(() => Boolean, { nullable: true })
    IsSystem?: boolean;

    @Field(() => Boolean, { nullable: true })
    IsActive?: boolean;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Sync Provider Types
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonActivitySyncProviderTypeInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    Code?: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description?: string | null;

    @Field({ nullable: true })
    DriverClass?: string | null;

    @Field({ nullable: true })
    IconClass?: string | null;

    @Field({ nullable: true })
    SupportedKinds?: string | null;

    @Field({ nullable: true })
    DefaultQualificationPolicy?: string;

    @Field({ nullable: true })
    DefaultSkippedContentPolicy?: string;

    @Field({ nullable: true })
    DefaultEncryptionKeyID?: string | null;

    @Field({ nullable: true })
    DefaultStorageProviderID?: string | null;

    @Field(() => Int, { nullable: true })
    DefaultMaxAttachmentBytes?: number | null;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field(() => Boolean, { nullable: true })
    IsSystem?: boolean;

    @Field(() => Boolean, { nullable: true })
    IsActive?: boolean;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Activity Sync Provider Types
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonActivitySyncProviderTypeViewResult {
    @Field(() => [mjBizAppsCommonActivitySyncProviderType_])
    Results: mjBizAppsCommonActivitySyncProviderType_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonActivitySyncProviderType_)
export class mjBizAppsCommonActivitySyncProviderTypeResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonActivitySyncProviderTypeViewResult)
    async RunmjBizAppsCommonActivitySyncProviderTypeViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivitySyncProviderTypeViewResult)
    async RunmjBizAppsCommonActivitySyncProviderTypeViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivitySyncProviderTypeViewResult)
    async RunmjBizAppsCommonActivitySyncProviderTypeDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Activity Sync Provider Types';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonActivitySyncProviderType_, { nullable: true })
    async mjBizAppsCommonActivitySyncProviderType(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonActivitySyncProviderType_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Activity Sync Provider Types', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwActivitySyncProviderTypes')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Activity Sync Provider Types', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Activity Sync Provider Types', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonActivitySyncProviderType_)
    async CreatemjBizAppsCommonActivitySyncProviderType(
        @Arg('input', () => CreatemjBizAppsCommonActivitySyncProviderTypeInput) input: CreatemjBizAppsCommonActivitySyncProviderTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Activity Sync Provider Types', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonActivitySyncProviderType_)
    async UpdatemjBizAppsCommonActivitySyncProviderType(
        @Arg('input', () => UpdatemjBizAppsCommonActivitySyncProviderTypeInput) input: UpdatemjBizAppsCommonActivitySyncProviderTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Activity Sync Provider Types', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonActivitySyncProviderType_)
    async DeletemjBizAppsCommonActivitySyncProviderType(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Activity Sync Provider Types', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Activity Sync Rule Sets
//****************************************************************************
@ObjectType({ description: `A NAMED, REUSABLE set of rules bound to many connections. Rules used to hang off a single connection, so an org-wide prohibition had to be retyped for every mailbox and a new mailbox started with none — governance by copy-paste. A rule set is authored once and bound wherever it applies.` })
export class mjBizAppsCommonActivitySyncRuleSet_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field() 
    @MaxLength(200)
    Name: string;
        
    @Field({nullable: true}) 
    Description?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    ActivitySyncProviderTypeID?: string;
        
    @Field({nullable: true, description: `JSON array of the domains this deployment considers INTERNAL, e.g. ["bluecypress.io"]. Required for any rule using ParticipantScope: "internal" is a property of the deployment, not of a message. Held on the rule set so one definition serves every mailbox bound to it.`}) 
    InternalDomains?: string;
        
    @Field(() => Int) 
    Sequence: number;
        
    @Field(() => Boolean) 
    IsEnabled: boolean;
        
    @Field(() => Boolean) 
    IsSystem: boolean;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
    @Field({nullable: true}) 
    @MaxLength(100)
    ActivitySyncProviderType?: string;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Sync Rule Sets
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonActivitySyncRuleSetInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description: string | null;

    @Field({ nullable: true })
    ActivitySyncProviderTypeID: string | null;

    @Field({ nullable: true })
    InternalDomains: string | null;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field(() => Boolean, { nullable: true })
    IsEnabled?: boolean;

    @Field(() => Boolean, { nullable: true })
    IsSystem?: boolean;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Sync Rule Sets
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonActivitySyncRuleSetInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description?: string | null;

    @Field({ nullable: true })
    ActivitySyncProviderTypeID?: string | null;

    @Field({ nullable: true })
    InternalDomains?: string | null;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field(() => Boolean, { nullable: true })
    IsEnabled?: boolean;

    @Field(() => Boolean, { nullable: true })
    IsSystem?: boolean;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Activity Sync Rule Sets
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonActivitySyncRuleSetViewResult {
    @Field(() => [mjBizAppsCommonActivitySyncRuleSet_])
    Results: mjBizAppsCommonActivitySyncRuleSet_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonActivitySyncRuleSet_)
export class mjBizAppsCommonActivitySyncRuleSetResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonActivitySyncRuleSetViewResult)
    async RunmjBizAppsCommonActivitySyncRuleSetViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivitySyncRuleSetViewResult)
    async RunmjBizAppsCommonActivitySyncRuleSetViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivitySyncRuleSetViewResult)
    async RunmjBizAppsCommonActivitySyncRuleSetDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Activity Sync Rule Sets';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonActivitySyncRuleSet_, { nullable: true })
    async mjBizAppsCommonActivitySyncRuleSet(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonActivitySyncRuleSet_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Activity Sync Rule Sets', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwActivitySyncRuleSets')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Activity Sync Rule Sets', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Activity Sync Rule Sets', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonActivitySyncRuleSet_)
    async CreatemjBizAppsCommonActivitySyncRuleSet(
        @Arg('input', () => CreatemjBizAppsCommonActivitySyncRuleSetInput) input: CreatemjBizAppsCommonActivitySyncRuleSetInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Activity Sync Rule Sets', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonActivitySyncRuleSet_)
    async UpdatemjBizAppsCommonActivitySyncRuleSet(
        @Arg('input', () => UpdatemjBizAppsCommonActivitySyncRuleSetInput) input: UpdatemjBizAppsCommonActivitySyncRuleSetInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Activity Sync Rule Sets', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonActivitySyncRuleSet_)
    async DeletemjBizAppsCommonActivitySyncRuleSet(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Activity Sync Rule Sets', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Activity Sync Rules
//****************************************************************************
@ObjectType({ description: `Include/exclude rule for an ActivitySyncConnection: type, direction, date window, attachments, plus a JSON Filter (folders, domains, participant-must-match-ContactMethod).` })
export class mjBizAppsCommonActivitySyncRule_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    ActivitySyncConnectionID?: string;
        
    @Field({description: `Display name of the rule.`}) 
    @MaxLength(200)
    Name: string;
        
    @Field(() => Boolean, {description: `0 skips the rule without deleting it.`}) 
    IsEnabled: boolean;
        
    @Field(() => Int, {description: `Evaluation order within the connection. Lower first.`}) 
    Sequence: number;
        
    @Field({description: `Include or Exclude matching items. With no rules, the engine syncs everything the connection can see.`}) 
    @MaxLength(20)
    Action: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    ActivityTypeID?: string;
        
    @Field({nullable: true, description: `Optional direction filter (Inbound / Outbound / Internal). Null = any.`}) 
    @MaxLength(20)
    Direction?: string;
        
    @Field({nullable: true, description: `Inclusive lower bound of the sync window. Null = no lower bound.`}) 
    DateFrom?: Date;
        
    @Field({nullable: true, description: `Inclusive upper bound of the sync window. Null = no upper bound.`}) 
    DateTo?: Date;
        
    @Field(() => Boolean, {description: `1 = also pull attachments into ActivityFile rows.`}) 
    IncludeAttachments: boolean;
        
    @Field({nullable: true, description: `JSON match extras: Folders, ExcludeFolders, Domains, ExcludeDomains, ParticipantMustMatchContactMethod, SubjectContains, SubjectExcludes. See ActivitySyncRuleFilter.`}) 
    Filter?: string;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
    @Field({nullable: true, description: `The rule set this rule belongs to. Exactly one of ActivitySyncRuleSetID and ActivitySyncConnectionID is set (CK_ActivitySyncRule_Owner) — the connection form is the deprecated original and remains only so existing rows stay valid.`}) 
    @MaxLength(36)
    ActivitySyncRuleSetID?: string;
        
    @Field({nullable: true, description: `Which participants must be present for this rule to apply — the internal/external control. AllInternal excludes purely internal chatter; HasExternal catches a thread with any outside party on it; Mixed is the case an all-or-nothing rule gets wrong. Requires the rule set to define InternalDomains. Null means the rule does not test participants.`}) 
    @MaxLength(30)
    ParticipantScope?: string;
        
    @Field(() => Int, {nullable: true}) 
    MaxAttachmentBytes?: number;
        
    @Field({nullable: true}) 
    @MaxLength(200)
    ActivitySyncConnection?: string;
        
    @Field({nullable: true}) 
    @MaxLength(100)
    ActivityType?: string;
        
    @Field({nullable: true}) 
    @MaxLength(200)
    ActivitySyncRuleSet?: string;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Sync Rules
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonActivitySyncRuleInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    ActivitySyncConnectionID: string | null;

    @Field({ nullable: true })
    Name?: string;

    @Field(() => Boolean, { nullable: true })
    IsEnabled?: boolean;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field({ nullable: true })
    Action?: string;

    @Field({ nullable: true })
    ActivityTypeID: string | null;

    @Field({ nullable: true })
    Direction: string | null;

    @Field({ nullable: true })
    DateFrom: Date | null;

    @Field({ nullable: true })
    DateTo: Date | null;

    @Field(() => Boolean, { nullable: true })
    IncludeAttachments?: boolean;

    @Field({ nullable: true })
    Filter: string | null;

    @Field({ nullable: true })
    ActivitySyncRuleSetID: string | null;

    @Field({ nullable: true })
    ParticipantScope: string | null;

    @Field(() => Int, { nullable: true })
    MaxAttachmentBytes: number | null;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Sync Rules
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonActivitySyncRuleInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    ActivitySyncConnectionID?: string | null;

    @Field({ nullable: true })
    Name?: string;

    @Field(() => Boolean, { nullable: true })
    IsEnabled?: boolean;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field({ nullable: true })
    Action?: string;

    @Field({ nullable: true })
    ActivityTypeID?: string | null;

    @Field({ nullable: true })
    Direction?: string | null;

    @Field({ nullable: true })
    DateFrom?: Date | null;

    @Field({ nullable: true })
    DateTo?: Date | null;

    @Field(() => Boolean, { nullable: true })
    IncludeAttachments?: boolean;

    @Field({ nullable: true })
    Filter?: string | null;

    @Field({ nullable: true })
    ActivitySyncRuleSetID?: string | null;

    @Field({ nullable: true })
    ParticipantScope?: string | null;

    @Field(() => Int, { nullable: true })
    MaxAttachmentBytes?: number | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Activity Sync Rules
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonActivitySyncRuleViewResult {
    @Field(() => [mjBizAppsCommonActivitySyncRule_])
    Results: mjBizAppsCommonActivitySyncRule_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonActivitySyncRule_)
export class mjBizAppsCommonActivitySyncRuleResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonActivitySyncRuleViewResult)
    async RunmjBizAppsCommonActivitySyncRuleViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivitySyncRuleViewResult)
    async RunmjBizAppsCommonActivitySyncRuleViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivitySyncRuleViewResult)
    async RunmjBizAppsCommonActivitySyncRuleDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Activity Sync Rules';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonActivitySyncRule_, { nullable: true })
    async mjBizAppsCommonActivitySyncRule(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonActivitySyncRule_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Activity Sync Rules', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwActivitySyncRules')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Activity Sync Rules', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Activity Sync Rules', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonActivitySyncRule_)
    async CreatemjBizAppsCommonActivitySyncRule(
        @Arg('input', () => CreatemjBizAppsCommonActivitySyncRuleInput) input: CreatemjBizAppsCommonActivitySyncRuleInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Activity Sync Rules', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonActivitySyncRule_)
    async UpdatemjBizAppsCommonActivitySyncRule(
        @Arg('input', () => UpdatemjBizAppsCommonActivitySyncRuleInput) input: UpdatemjBizAppsCommonActivitySyncRuleInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Activity Sync Rules', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonActivitySyncRule_)
    async DeletemjBizAppsCommonActivitySyncRule(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Activity Sync Rules', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Activity Sync Run Details
//****************************************************************************
@ObjectType({ description: `The decision made about ONE message, written for every item considered INCLUDING every skip — which is what makes "why did my email not appear" answerable. ExternalID and the decision are always safe to keep: an opaque provider id and the name of a rule, not content. CapturedContent is different in kind and is governed by the effective SkippedContentPolicy. Give this entity permissions DISTINCT from Activity: it can hold fragments of messages that were deliberately not ingested.` })
export class mjBizAppsCommonActivitySyncRunDetail_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field() 
    @MaxLength(36)
    ActivitySyncRunID: string;
        
    @Field() 
    @MaxLength(400)
    ExternalID: string;
        
    @Field({nullable: true}) 
    @MaxLength(400)
    ExternalThreadID?: string;
        
    @Field({nullable: true}) 
    OccurredAt?: Date;
        
    @Field() 
    @MaxLength(20)
    Decision: string;
        
    @Field({nullable: true, description: `Which stage of the qualification cascade decided — a rule set name, KnownParticipant, Inference, or DefaultPolicy. Paired with Reason it explains an outcome without retaining the message that produced it.`}) 
    @MaxLength(100)
    DecidedByStage?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    ActivitySyncRuleID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    ActivitySyncExclusionID?: string;
        
    @Field({nullable: true}) 
    Reason?: string;
        
    @Field(() => Float, {nullable: true}) 
    Confidence?: number;
        
    @Field({nullable: true, description: `The MJ: AI Prompt Run behind an inference-stage verdict. Non-null only when a model actually decided this item, which is the audit trail for every automated judgement the engine makes.`}) 
    @MaxLength(36)
    AIPromptRunID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    ActivityID?: string;
        
    @Field({nullable: true, description: `Ciphertext, always — never plaintext, whatever the policy. Present only when the effective SkippedContentPolicy allows retention, and always paired with the EncryptionKeyID that opens it (CK_ActivitySyncRunDetail_ContentKey). Encrypted through MJ's EncryptionEngine against an MJ: Encryption Keys row; this app never implements its own crypto.`}) 
    CapturedContent?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    EncryptionKeyID?: string;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
    @Field({nullable: true}) 
    @MaxLength(200)
    ActivitySyncRule?: string;
        
    @Field({nullable: true}) 
    @MaxLength(500)
    Activity?: string;
        
    @Field({nullable: true}) 
    @MaxLength(100)
    EncryptionKey?: string;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Sync Run Details
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonActivitySyncRunDetailInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    ActivitySyncRunID?: string;

    @Field({ nullable: true })
    ExternalID?: string;

    @Field({ nullable: true })
    ExternalThreadID: string | null;

    @Field({ nullable: true })
    OccurredAt: Date | null;

    @Field({ nullable: true })
    Decision?: string;

    @Field({ nullable: true })
    DecidedByStage: string | null;

    @Field({ nullable: true })
    ActivitySyncRuleID: string | null;

    @Field({ nullable: true })
    ActivitySyncExclusionID: string | null;

    @Field({ nullable: true })
    Reason: string | null;

    @Field(() => Float, { nullable: true })
    Confidence: number | null;

    @Field({ nullable: true })
    AIPromptRunID: string | null;

    @Field({ nullable: true })
    ActivityID: string | null;

    @Field({ nullable: true })
    CapturedContent: string | null;

    @Field({ nullable: true })
    EncryptionKeyID: string | null;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Sync Run Details
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonActivitySyncRunDetailInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    ActivitySyncRunID?: string;

    @Field({ nullable: true })
    ExternalID?: string;

    @Field({ nullable: true })
    ExternalThreadID?: string | null;

    @Field({ nullable: true })
    OccurredAt?: Date | null;

    @Field({ nullable: true })
    Decision?: string;

    @Field({ nullable: true })
    DecidedByStage?: string | null;

    @Field({ nullable: true })
    ActivitySyncRuleID?: string | null;

    @Field({ nullable: true })
    ActivitySyncExclusionID?: string | null;

    @Field({ nullable: true })
    Reason?: string | null;

    @Field(() => Float, { nullable: true })
    Confidence?: number | null;

    @Field({ nullable: true })
    AIPromptRunID?: string | null;

    @Field({ nullable: true })
    ActivityID?: string | null;

    @Field({ nullable: true })
    CapturedContent?: string | null;

    @Field({ nullable: true })
    EncryptionKeyID?: string | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Activity Sync Run Details
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonActivitySyncRunDetailViewResult {
    @Field(() => [mjBizAppsCommonActivitySyncRunDetail_])
    Results: mjBizAppsCommonActivitySyncRunDetail_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonActivitySyncRunDetail_)
export class mjBizAppsCommonActivitySyncRunDetailResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonActivitySyncRunDetailViewResult)
    async RunmjBizAppsCommonActivitySyncRunDetailViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivitySyncRunDetailViewResult)
    async RunmjBizAppsCommonActivitySyncRunDetailViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivitySyncRunDetailViewResult)
    async RunmjBizAppsCommonActivitySyncRunDetailDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Activity Sync Run Details';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonActivitySyncRunDetail_, { nullable: true })
    async mjBizAppsCommonActivitySyncRunDetail(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonActivitySyncRunDetail_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Activity Sync Run Details', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwActivitySyncRunDetails')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Activity Sync Run Details', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Activity Sync Run Details', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonActivitySyncRunDetail_)
    async CreatemjBizAppsCommonActivitySyncRunDetail(
        @Arg('input', () => CreatemjBizAppsCommonActivitySyncRunDetailInput) input: CreatemjBizAppsCommonActivitySyncRunDetailInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Activity Sync Run Details', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonActivitySyncRunDetail_)
    async UpdatemjBizAppsCommonActivitySyncRunDetail(
        @Arg('input', () => UpdatemjBizAppsCommonActivitySyncRunDetailInput) input: UpdatemjBizAppsCommonActivitySyncRunDetailInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Activity Sync Run Details', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonActivitySyncRunDetail_)
    async DeletemjBizAppsCommonActivitySyncRunDetail(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Activity Sync Run Details', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Activity Sync Runs
//****************************************************************************
@ObjectType({ description: `One sync pass over one connection: what it fetched, what it decided, and whether it earned the right to move the watermark. A dry run is a real row with IsDryRun set — it evaluates and reports without writing an Activity or advancing the connection.` })
export class mjBizAppsCommonActivitySyncRun_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field() 
    @MaxLength(36)
    ActivitySyncConnectionID: string;
        
    @Field() 
    StartedAt: Date;
        
    @Field({nullable: true}) 
    EndedAt?: Date;
        
    @Field() 
    @MaxLength(20)
    Status: string;
        
    @Field() 
    @MaxLength(20)
    TriggerType: string;
        
    @Field(() => Boolean) 
    IsDryRun: boolean;
        
    @Field(() => Int) 
    Fetched: number;
        
    @Field(() => Int) 
    Included: number;
        
    @Field(() => Int) 
    Excluded: number;
        
    @Field(() => Int) 
    Duplicates: number;
        
    @Field(() => Int) 
    Failed: number;
        
    @Field(() => Int) 
    ExtensionErrors: number;
        
    @Field({nullable: true}) 
    WatermarkBefore?: Date;
        
    @Field({nullable: true}) 
    WatermarkAfter?: Date;
        
    @Field({nullable: true}) 
    ErrorMessage?: string;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
    @Field() 
    @MaxLength(200)
    ActivitySyncConnection: string;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Sync Runs
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonActivitySyncRunInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    ActivitySyncConnectionID?: string;

    @Field({ nullable: true })
    StartedAt?: Date;

    @Field({ nullable: true })
    EndedAt: Date | null;

    @Field({ nullable: true })
    Status?: string;

    @Field({ nullable: true })
    TriggerType?: string;

    @Field(() => Boolean, { nullable: true })
    IsDryRun?: boolean;

    @Field(() => Int, { nullable: true })
    Fetched?: number;

    @Field(() => Int, { nullable: true })
    Included?: number;

    @Field(() => Int, { nullable: true })
    Excluded?: number;

    @Field(() => Int, { nullable: true })
    Duplicates?: number;

    @Field(() => Int, { nullable: true })
    Failed?: number;

    @Field(() => Int, { nullable: true })
    ExtensionErrors?: number;

    @Field({ nullable: true })
    WatermarkBefore: Date | null;

    @Field({ nullable: true })
    WatermarkAfter: Date | null;

    @Field({ nullable: true })
    ErrorMessage: string | null;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Sync Runs
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonActivitySyncRunInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    ActivitySyncConnectionID?: string;

    @Field({ nullable: true })
    StartedAt?: Date;

    @Field({ nullable: true })
    EndedAt?: Date | null;

    @Field({ nullable: true })
    Status?: string;

    @Field({ nullable: true })
    TriggerType?: string;

    @Field(() => Boolean, { nullable: true })
    IsDryRun?: boolean;

    @Field(() => Int, { nullable: true })
    Fetched?: number;

    @Field(() => Int, { nullable: true })
    Included?: number;

    @Field(() => Int, { nullable: true })
    Excluded?: number;

    @Field(() => Int, { nullable: true })
    Duplicates?: number;

    @Field(() => Int, { nullable: true })
    Failed?: number;

    @Field(() => Int, { nullable: true })
    ExtensionErrors?: number;

    @Field({ nullable: true })
    WatermarkBefore?: Date | null;

    @Field({ nullable: true })
    WatermarkAfter?: Date | null;

    @Field({ nullable: true })
    ErrorMessage?: string | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Activity Sync Runs
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonActivitySyncRunViewResult {
    @Field(() => [mjBizAppsCommonActivitySyncRun_])
    Results: mjBizAppsCommonActivitySyncRun_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonActivitySyncRun_)
export class mjBizAppsCommonActivitySyncRunResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonActivitySyncRunViewResult)
    async RunmjBizAppsCommonActivitySyncRunViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivitySyncRunViewResult)
    async RunmjBizAppsCommonActivitySyncRunViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivitySyncRunViewResult)
    async RunmjBizAppsCommonActivitySyncRunDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Activity Sync Runs';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonActivitySyncRun_, { nullable: true })
    async mjBizAppsCommonActivitySyncRun(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonActivitySyncRun_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Activity Sync Runs', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwActivitySyncRuns')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Activity Sync Runs', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Activity Sync Runs', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonActivitySyncRun_)
    async CreatemjBizAppsCommonActivitySyncRun(
        @Arg('input', () => CreatemjBizAppsCommonActivitySyncRunInput) input: CreatemjBizAppsCommonActivitySyncRunInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Activity Sync Runs', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonActivitySyncRun_)
    async UpdatemjBizAppsCommonActivitySyncRun(
        @Arg('input', () => UpdatemjBizAppsCommonActivitySyncRunInput) input: UpdatemjBizAppsCommonActivitySyncRunInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Activity Sync Runs', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonActivitySyncRun_)
    async DeletemjBizAppsCommonActivitySyncRun(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Activity Sync Runs', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Activity Types
//****************************************************************************
@ObjectType({ description: `Lookup of interaction channels (Email, Call, Meeting, Note, SMS, Chat). Hierarchy is picker-only; direction lives on Activity. Code is the stable key — sync and code target Code, never Name.` })
export class mjBizAppsCommonActivityType_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field({description: `Stable key targeted by sync and code (Email, Call, Meeting, Note, SMS, Chat). Unique. Names can be renamed; codes cannot.`}) 
    @MaxLength(50)
    Code: string;
        
    @Field({description: `Display name for the picker and timeline.`}) 
    @MaxLength(100)
    Name: string;
        
    @Field({nullable: true, description: `Optional longer description of the type.`}) 
    Description?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    ParentID?: string;
        
    @Field({nullable: true, description: `Font Awesome class for timeline chrome (e.g. fa-solid fa-envelope).`}) 
    @MaxLength(100)
    IconClass?: string;
        
    @Field({nullable: true, description: `Optional categorical color for timeline chrome. Not a design-token — this is stored per type.`}) 
    @MaxLength(30)
    Color?: string;
        
    @Field(() => Int, {description: `Picker sort order. Lower first.`}) 
    Sequence: number;
        
    @Field(() => Boolean, {description: `1 = seeded system type the sync engine may assume (Email, Call, Meeting, Note, SMS, Chat). Clients add children with IsSystem = 0.`}) 
    IsSystem: boolean;
        
    @Field(() => Boolean, {description: `0 hides the type from the picker without deleting historical activities.`}) 
    IsActive: boolean;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
    @Field({nullable: true}) 
    @MaxLength(100)
    Parent?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    RootParentID?: string;
        
    @Field(() => Int, {nullable: true}) 
    ParentIDDepth?: number;
        
    @Field({nullable: true}) 
    ParentIDPath?: string;
        
    @Field(() => Boolean, {nullable: true}) 
    ParentIDIsLeaf?: boolean;
        
    @Field(() => Int, {nullable: true}) 
    ParentIDChildCount?: number;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Types
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonActivityTypeInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    Code?: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description: string | null;

    @Field({ nullable: true })
    ParentID: string | null;

    @Field({ nullable: true })
    IconClass: string | null;

    @Field({ nullable: true })
    Color: string | null;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field(() => Boolean, { nullable: true })
    IsSystem?: boolean;

    @Field(() => Boolean, { nullable: true })
    IsActive?: boolean;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Activity Types
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonActivityTypeInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    Code?: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description?: string | null;

    @Field({ nullable: true })
    ParentID?: string | null;

    @Field({ nullable: true })
    IconClass?: string | null;

    @Field({ nullable: true })
    Color?: string | null;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field(() => Boolean, { nullable: true })
    IsSystem?: boolean;

    @Field(() => Boolean, { nullable: true })
    IsActive?: boolean;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Activity Types
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonActivityTypeViewResult {
    @Field(() => [mjBizAppsCommonActivityType_])
    Results: mjBizAppsCommonActivityType_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonActivityType_)
export class mjBizAppsCommonActivityTypeResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonActivityTypeViewResult)
    async RunmjBizAppsCommonActivityTypeViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivityTypeViewResult)
    async RunmjBizAppsCommonActivityTypeViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonActivityTypeViewResult)
    async RunmjBizAppsCommonActivityTypeDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Activity Types';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonActivityType_, { nullable: true })
    async mjBizAppsCommonActivityType(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonActivityType_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Activity Types', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwActivityTypes')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Activity Types', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Activity Types', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonActivityType_)
    async CreatemjBizAppsCommonActivityType(
        @Arg('input', () => CreatemjBizAppsCommonActivityTypeInput) input: CreatemjBizAppsCommonActivityTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Activity Types', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonActivityType_)
    async UpdatemjBizAppsCommonActivityType(
        @Arg('input', () => UpdatemjBizAppsCommonActivityTypeInput) input: UpdatemjBizAppsCommonActivityTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Activity Types', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonActivityType_)
    async DeletemjBizAppsCommonActivityType(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Activity Types', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Address Links
//****************************************************************************
@ObjectType({ description: `Polymorphic link table connecting Address records to any entity record in the system via EntityID and RecordID` })
export class mjBizAppsCommonAddressLink_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field() 
    @MaxLength(36)
    AddressID: string;
        
    @Field() 
    @MaxLength(36)
    EntityID: string;
        
    @Field({description: `Primary key value(s) of the linked record. NVARCHAR(700) to support concatenated composite keys for entities without single-valued primary keys`}) 
    @MaxLength(700)
    RecordID: string;
        
    @Field() 
    @MaxLength(36)
    AddressTypeID: string;
        
    @Field(() => Boolean, {description: `Whether this is the primary address for the linked record. Only one address per entity record should be marked primary`}) 
    IsPrimary: boolean;
        
    @Field(() => Int, {nullable: true, description: `Sort order override for this specific link. When NULL, falls back to AddressType.DefaultRank. Lower values appear first`}) 
    Rank?: number;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
    @Field() 
    @MaxLength(255)
    Address: string;
        
    @Field() 
    @MaxLength(255)
    Entity: string;
        
    @Field() 
    @MaxLength(100)
    AddressType: string;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Address Links
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonAddressLinkInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    AddressID?: string;

    @Field({ nullable: true })
    EntityID?: string;

    @Field({ nullable: true })
    RecordID?: string;

    @Field({ nullable: true })
    AddressTypeID?: string;

    @Field(() => Boolean, { nullable: true })
    IsPrimary?: boolean;

    @Field(() => Int, { nullable: true })
    Rank: number | null;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Address Links
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonAddressLinkInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    AddressID?: string;

    @Field({ nullable: true })
    EntityID?: string;

    @Field({ nullable: true })
    RecordID?: string;

    @Field({ nullable: true })
    AddressTypeID?: string;

    @Field(() => Boolean, { nullable: true })
    IsPrimary?: boolean;

    @Field(() => Int, { nullable: true })
    Rank?: number | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Address Links
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonAddressLinkViewResult {
    @Field(() => [mjBizAppsCommonAddressLink_])
    Results: mjBizAppsCommonAddressLink_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonAddressLink_)
export class mjBizAppsCommonAddressLinkResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonAddressLinkViewResult)
    async RunmjBizAppsCommonAddressLinkViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonAddressLinkViewResult)
    async RunmjBizAppsCommonAddressLinkViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonAddressLinkViewResult)
    async RunmjBizAppsCommonAddressLinkDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Address Links';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonAddressLink_, { nullable: true })
    async mjBizAppsCommonAddressLink(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonAddressLink_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Address Links', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwAddressLinks')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Address Links', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Address Links', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonAddressLink_)
    async CreatemjBizAppsCommonAddressLink(
        @Arg('input', () => CreatemjBizAppsCommonAddressLinkInput) input: CreatemjBizAppsCommonAddressLinkInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Address Links', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonAddressLink_)
    async UpdatemjBizAppsCommonAddressLink(
        @Arg('input', () => UpdatemjBizAppsCommonAddressLinkInput) input: UpdatemjBizAppsCommonAddressLinkInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Address Links', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonAddressLink_)
    async DeletemjBizAppsCommonAddressLink(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Address Links', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Address Types
//****************************************************************************
@ObjectType({ description: `Categories of addresses such as Home, Work, Mailing, Billing` })
export class mjBizAppsCommonAddressType_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field({description: `Display name for the address type`}) 
    @MaxLength(100)
    Name: string;
        
    @Field({nullable: true, description: `Detailed description of this address type`}) 
    Description?: string;
        
    @Field({nullable: true, description: `Font Awesome icon class for UI display`}) 
    @MaxLength(100)
    IconClass?: string;
        
    @Field(() => Int, {description: `Default sort order for this address type in dropdown lists. Lower values appear first. Can be overridden per-record via AddressLink.Rank`}) 
    DefaultRank: number;
        
    @Field(() => Boolean, {description: `Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records`}) 
    IsActive: boolean;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Address Types
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonAddressTypeInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description: string | null;

    @Field({ nullable: true })
    IconClass: string | null;

    @Field(() => Int, { nullable: true })
    DefaultRank?: number;

    @Field(() => Boolean, { nullable: true })
    IsActive?: boolean;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Address Types
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonAddressTypeInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description?: string | null;

    @Field({ nullable: true })
    IconClass?: string | null;

    @Field(() => Int, { nullable: true })
    DefaultRank?: number;

    @Field(() => Boolean, { nullable: true })
    IsActive?: boolean;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Address Types
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonAddressTypeViewResult {
    @Field(() => [mjBizAppsCommonAddressType_])
    Results: mjBizAppsCommonAddressType_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonAddressType_)
export class mjBizAppsCommonAddressTypeResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonAddressTypeViewResult)
    async RunmjBizAppsCommonAddressTypeViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonAddressTypeViewResult)
    async RunmjBizAppsCommonAddressTypeViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonAddressTypeViewResult)
    async RunmjBizAppsCommonAddressTypeDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Address Types';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonAddressType_, { nullable: true })
    async mjBizAppsCommonAddressType(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonAddressType_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Address Types', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwAddressTypes')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Address Types', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Address Types', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonAddressType_)
    async CreatemjBizAppsCommonAddressType(
        @Arg('input', () => CreatemjBizAppsCommonAddressTypeInput) input: CreatemjBizAppsCommonAddressTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Address Types', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonAddressType_)
    async UpdatemjBizAppsCommonAddressType(
        @Arg('input', () => UpdatemjBizAppsCommonAddressTypeInput) input: UpdatemjBizAppsCommonAddressTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Address Types', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonAddressType_)
    async DeletemjBizAppsCommonAddressType(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Address Types', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Addresses
//****************************************************************************
@ObjectType({ description: `Standalone physical address records linked to entities via AddressLink for sharing across people and organizations` })
export class mjBizAppsCommonAddress_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field({description: `Street address line 1`}) 
    @MaxLength(255)
    Line1: string;
        
    @Field({nullable: true, description: `Street address line 2 (suite, apt, etc.)`}) 
    @MaxLength(255)
    Line2?: string;
        
    @Field({nullable: true, description: `Street address line 3 (additional detail)`}) 
    @MaxLength(255)
    Line3?: string;
        
    @Field({description: `City or locality name`}) 
    @MaxLength(100)
    City: string;
        
    @Field({nullable: true, description: `State, province, or region`}) 
    @MaxLength(100)
    StateProvince?: string;
        
    @Field({nullable: true, description: `Postal or ZIP code`}) 
    @MaxLength(20)
    PostalCode?: string;
        
    @Field({description: `Country code or name, defaults to US`}) 
    @MaxLength(100)
    Country: string;
        
    @Field(() => Float, {nullable: true, description: `Geographic latitude for mapping`}) 
    Latitude?: number;
        
    @Field(() => Float, {nullable: true, description: `Geographic longitude for mapping`}) 
    Longitude?: number;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Addresses
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonAddressInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    Line1?: string;

    @Field({ nullable: true })
    Line2: string | null;

    @Field({ nullable: true })
    Line3: string | null;

    @Field({ nullable: true })
    City?: string;

    @Field({ nullable: true })
    StateProvince: string | null;

    @Field({ nullable: true })
    PostalCode: string | null;

    @Field({ nullable: true })
    Country?: string;

    @Field(() => Float, { nullable: true })
    Latitude: number | null;

    @Field(() => Float, { nullable: true })
    Longitude: number | null;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Addresses
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonAddressInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    Line1?: string;

    @Field({ nullable: true })
    Line2?: string | null;

    @Field({ nullable: true })
    Line3?: string | null;

    @Field({ nullable: true })
    City?: string;

    @Field({ nullable: true })
    StateProvince?: string | null;

    @Field({ nullable: true })
    PostalCode?: string | null;

    @Field({ nullable: true })
    Country?: string;

    @Field(() => Float, { nullable: true })
    Latitude?: number | null;

    @Field(() => Float, { nullable: true })
    Longitude?: number | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Addresses
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonAddressViewResult {
    @Field(() => [mjBizAppsCommonAddress_])
    Results: mjBizAppsCommonAddress_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonAddress_)
export class mjBizAppsCommonAddressResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonAddressViewResult)
    async RunmjBizAppsCommonAddressViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonAddressViewResult)
    async RunmjBizAppsCommonAddressViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonAddressViewResult)
    async RunmjBizAppsCommonAddressDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Addresses';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonAddress_, { nullable: true })
    async mjBizAppsCommonAddress(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonAddress_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Addresses', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwAddresses')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Addresses', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Addresses', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonAddress_)
    async CreatemjBizAppsCommonAddress(
        @Arg('input', () => CreatemjBizAppsCommonAddressInput) input: CreatemjBizAppsCommonAddressInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Addresses', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonAddress_)
    async UpdatemjBizAppsCommonAddress(
        @Arg('input', () => UpdatemjBizAppsCommonAddressInput) input: UpdatemjBizAppsCommonAddressInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Addresses', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonAddress_)
    async DeletemjBizAppsCommonAddress(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Addresses', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Contact Methods
//****************************************************************************
@ObjectType({ description: `Additional contact methods for people and organizations beyond the primary email and phone fields` })
export class mjBizAppsCommonContactMethod_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    PersonID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    OrganizationID?: string;
        
    @Field() 
    @MaxLength(36)
    ContactTypeID: string;
        
    @Field({description: `The contact value: phone number, email address, URL, social media handle, etc.`}) 
    @MaxLength(500)
    Value: string;
        
    @Field({nullable: true, description: `Descriptive label such as Work cell, Personal Gmail, Corporate LinkedIn`}) 
    @MaxLength(100)
    Label?: string;
        
    @Field(() => Boolean, {description: `Whether this is the primary contact method of its type for the linked person or organization`}) 
    IsPrimary: boolean;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
    @Field({nullable: true}) 
    @MaxLength(201)
    Person?: string;
        
    @Field({nullable: true}) 
    @MaxLength(255)
    Organization?: string;
        
    @Field() 
    @MaxLength(100)
    ContactType: string;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Contact Methods
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonContactMethodInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    PersonID: string | null;

    @Field({ nullable: true })
    OrganizationID: string | null;

    @Field({ nullable: true })
    ContactTypeID?: string;

    @Field({ nullable: true })
    Value?: string;

    @Field({ nullable: true })
    Label: string | null;

    @Field(() => Boolean, { nullable: true })
    IsPrimary?: boolean;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Contact Methods
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonContactMethodInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    PersonID?: string | null;

    @Field({ nullable: true })
    OrganizationID?: string | null;

    @Field({ nullable: true })
    ContactTypeID?: string;

    @Field({ nullable: true })
    Value?: string;

    @Field({ nullable: true })
    Label?: string | null;

    @Field(() => Boolean, { nullable: true })
    IsPrimary?: boolean;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Contact Methods
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonContactMethodViewResult {
    @Field(() => [mjBizAppsCommonContactMethod_])
    Results: mjBizAppsCommonContactMethod_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonContactMethod_)
export class mjBizAppsCommonContactMethodResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonContactMethodViewResult)
    async RunmjBizAppsCommonContactMethodViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonContactMethodViewResult)
    async RunmjBizAppsCommonContactMethodViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonContactMethodViewResult)
    async RunmjBizAppsCommonContactMethodDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Contact Methods';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonContactMethod_, { nullable: true })
    async mjBizAppsCommonContactMethod(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonContactMethod_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Contact Methods', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwContactMethods')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Contact Methods', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Contact Methods', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonContactMethod_)
    async CreatemjBizAppsCommonContactMethod(
        @Arg('input', () => CreatemjBizAppsCommonContactMethodInput) input: CreatemjBizAppsCommonContactMethodInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Contact Methods', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonContactMethod_)
    async UpdatemjBizAppsCommonContactMethod(
        @Arg('input', () => UpdatemjBizAppsCommonContactMethodInput) input: UpdatemjBizAppsCommonContactMethodInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Contact Methods', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonContactMethod_)
    async DeletemjBizAppsCommonContactMethod(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Contact Methods', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Contact Types
//****************************************************************************
@ObjectType({ description: `Categories of contact methods such as Phone, Mobile, Email, LinkedIn, Website` })
export class mjBizAppsCommonContactType_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field({description: `Display name for the contact type`}) 
    @MaxLength(100)
    Name: string;
        
    @Field({nullable: true, description: `Detailed description of this contact type`}) 
    Description?: string;
        
    @Field({nullable: true, description: `Font Awesome icon class for UI display`}) 
    @MaxLength(100)
    IconClass?: string;
        
    @Field(() => Int, {description: `Sort order in dropdown lists. Lower values appear first`}) 
    DisplayRank: number;
        
    @Field(() => Boolean, {description: `Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records`}) 
    IsActive: boolean;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Contact Types
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonContactTypeInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description: string | null;

    @Field({ nullable: true })
    IconClass: string | null;

    @Field(() => Int, { nullable: true })
    DisplayRank?: number;

    @Field(() => Boolean, { nullable: true })
    IsActive?: boolean;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Contact Types
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonContactTypeInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description?: string | null;

    @Field({ nullable: true })
    IconClass?: string | null;

    @Field(() => Int, { nullable: true })
    DisplayRank?: number;

    @Field(() => Boolean, { nullable: true })
    IsActive?: boolean;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Contact Types
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonContactTypeViewResult {
    @Field(() => [mjBizAppsCommonContactType_])
    Results: mjBizAppsCommonContactType_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonContactType_)
export class mjBizAppsCommonContactTypeResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonContactTypeViewResult)
    async RunmjBizAppsCommonContactTypeViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonContactTypeViewResult)
    async RunmjBizAppsCommonContactTypeViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonContactTypeViewResult)
    async RunmjBizAppsCommonContactTypeDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Contact Types';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonContactType_, { nullable: true })
    async mjBizAppsCommonContactType(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonContactType_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Contact Types', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwContactTypes')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Contact Types', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Contact Types', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonContactType_)
    async CreatemjBizAppsCommonContactType(
        @Arg('input', () => CreatemjBizAppsCommonContactTypeInput) input: CreatemjBizAppsCommonContactTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Contact Types', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonContactType_)
    async UpdatemjBizAppsCommonContactType(
        @Arg('input', () => UpdatemjBizAppsCommonContactTypeInput) input: UpdatemjBizAppsCommonContactTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Contact Types', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonContactType_)
    async DeletemjBizAppsCommonContactType(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Contact Types', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Organization Types
//****************************************************************************
@ObjectType({ description: `Categories of organizations such as Company, Non-Profit, Association, Government` })
export class mjBizAppsCommonOrganizationType_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field({description: `Display name for the organization type`}) 
    @MaxLength(100)
    Name: string;
        
    @Field({nullable: true, description: `Detailed description of this organization type`}) 
    Description?: string;
        
    @Field({nullable: true, description: `Font Awesome icon class for UI display`}) 
    @MaxLength(100)
    IconClass?: string;
        
    @Field(() => Int, {description: `Sort order in dropdown lists. Lower values appear first`}) 
    DisplayRank: number;
        
    @Field(() => Boolean, {description: `Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records`}) 
    IsActive: boolean;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Organization Types
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonOrganizationTypeInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description: string | null;

    @Field({ nullable: true })
    IconClass: string | null;

    @Field(() => Int, { nullable: true })
    DisplayRank?: number;

    @Field(() => Boolean, { nullable: true })
    IsActive?: boolean;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Organization Types
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonOrganizationTypeInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description?: string | null;

    @Field({ nullable: true })
    IconClass?: string | null;

    @Field(() => Int, { nullable: true })
    DisplayRank?: number;

    @Field(() => Boolean, { nullable: true })
    IsActive?: boolean;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Organization Types
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonOrganizationTypeViewResult {
    @Field(() => [mjBizAppsCommonOrganizationType_])
    Results: mjBizAppsCommonOrganizationType_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonOrganizationType_)
export class mjBizAppsCommonOrganizationTypeResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonOrganizationTypeViewResult)
    async RunmjBizAppsCommonOrganizationTypeViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonOrganizationTypeViewResult)
    async RunmjBizAppsCommonOrganizationTypeViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonOrganizationTypeViewResult)
    async RunmjBizAppsCommonOrganizationTypeDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Organization Types';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonOrganizationType_, { nullable: true })
    async mjBizAppsCommonOrganizationType(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonOrganizationType_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Organization Types', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwOrganizationTypes')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Organization Types', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Organization Types', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonOrganizationType_)
    async CreatemjBizAppsCommonOrganizationType(
        @Arg('input', () => CreatemjBizAppsCommonOrganizationTypeInput) input: CreatemjBizAppsCommonOrganizationTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Organization Types', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonOrganizationType_)
    async UpdatemjBizAppsCommonOrganizationType(
        @Arg('input', () => UpdatemjBizAppsCommonOrganizationTypeInput) input: UpdatemjBizAppsCommonOrganizationTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Organization Types', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonOrganizationType_)
    async DeletemjBizAppsCommonOrganizationType(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Organization Types', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Organizations
//****************************************************************************
@ObjectType({ description: `Companies, associations, government bodies, and other organizations with hierarchy support` })
export class mjBizAppsCommonOrganization_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field({description: `Common or display name of the organization`}) 
    @MaxLength(255)
    Name: string;
        
    @Field({nullable: true, description: `Full legal name if different from display name`}) 
    @MaxLength(255)
    LegalName?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    OrganizationTypeID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    ParentID?: string;
        
    @Field({nullable: true, description: `Primary website URL`}) 
    @MaxLength(1000)
    Website?: string;
        
    @Field({nullable: true, description: `URL to organization logo image`}) 
    @MaxLength(1000)
    LogoURL?: string;
        
    @Field({nullable: true, description: `Description of the organization purpose and scope`}) 
    Description?: string;
        
    @Field({nullable: true, description: `Primary contact email address`}) 
    @MaxLength(255)
    Email?: string;
        
    @Field({nullable: true, description: `Primary phone number`}) 
    @MaxLength(50)
    Phone?: string;
        
    @Field({nullable: true, description: `Date the organization was founded or incorporated`}) 
    FoundedDate?: Date;
        
    @Field({nullable: true, description: `Tax identification number such as EIN`}) 
    @MaxLength(50)
    TaxID?: string;
        
    @Field({description: `Current status: Active, Inactive, or Dissolved`}) 
    @MaxLength(50)
    Status: string;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
    @Field({nullable: true}) 
    @MaxLength(100)
    OrganizationType?: string;
        
    @Field({nullable: true}) 
    @MaxLength(255)
    Parent?: string;
        
    @Field(() => Float, {nullable: true}) 
    _mj__Latitude?: number;
        
    @Field(() => Float, {nullable: true}) 
    _mj__Longitude?: number;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    RootParentID?: string;
        
    @Field(() => Int, {nullable: true}) 
    ParentIDDepth?: number;
        
    @Field({nullable: true}) 
    ParentIDPath?: string;
        
    @Field(() => Boolean, {nullable: true}) 
    ParentIDIsLeaf?: boolean;
        
    @Field(() => Int, {nullable: true}) 
    ParentIDChildCount?: number;
        
    @Field({nullable: true}) 
    @MaxLength(255)
    PrimaryAddressLine1?: string;
        
    @Field({nullable: true}) 
    @MaxLength(255)
    PrimaryAddressLine2?: string;
        
    @Field({nullable: true}) 
    @MaxLength(100)
    PrimaryAddressCity?: string;
        
    @Field({nullable: true}) 
    @MaxLength(100)
    PrimaryAddressState?: string;
        
    @Field({nullable: true}) 
    @MaxLength(20)
    PrimaryAddressPostalCode?: string;
        
    @Field({nullable: true}) 
    @MaxLength(100)
    PrimaryAddressCountry?: string;
        
    @Field({nullable: true}) 
    @MaxLength(100)
    PrimaryAddressType?: string;
        
    @Field({nullable: true}) 
    @MaxLength(500)
    PrimaryEmail?: string;
        
    @Field({nullable: true}) 
    @MaxLength(500)
    PrimaryPhone?: string;
        
    @Field(() => Int, {nullable: true}) 
    ActivePersonCount?: number;
        
    @Field(() => Int, {nullable: true}) 
    ChildOrgCount?: number;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Organizations
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonOrganizationInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    LegalName: string | null;

    @Field({ nullable: true })
    OrganizationTypeID: string | null;

    @Field({ nullable: true })
    ParentID: string | null;

    @Field({ nullable: true })
    Website: string | null;

    @Field({ nullable: true })
    LogoURL: string | null;

    @Field({ nullable: true })
    Description: string | null;

    @Field({ nullable: true })
    Email: string | null;

    @Field({ nullable: true })
    Phone: string | null;

    @Field({ nullable: true })
    FoundedDate: Date | null;

    @Field({ nullable: true })
    TaxID: string | null;

    @Field({ nullable: true })
    Status?: string;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Organizations
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonOrganizationInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    LegalName?: string | null;

    @Field({ nullable: true })
    OrganizationTypeID?: string | null;

    @Field({ nullable: true })
    ParentID?: string | null;

    @Field({ nullable: true })
    Website?: string | null;

    @Field({ nullable: true })
    LogoURL?: string | null;

    @Field({ nullable: true })
    Description?: string | null;

    @Field({ nullable: true })
    Email?: string | null;

    @Field({ nullable: true })
    Phone?: string | null;

    @Field({ nullable: true })
    FoundedDate?: Date | null;

    @Field({ nullable: true })
    TaxID?: string | null;

    @Field({ nullable: true })
    Status?: string;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Organizations
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonOrganizationViewResult {
    @Field(() => [mjBizAppsCommonOrganization_])
    Results: mjBizAppsCommonOrganization_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonOrganization_)
export class mjBizAppsCommonOrganizationResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonOrganizationViewResult)
    async RunmjBizAppsCommonOrganizationViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonOrganizationViewResult)
    async RunmjBizAppsCommonOrganizationViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonOrganizationViewResult)
    async RunmjBizAppsCommonOrganizationDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Organizations';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonOrganization_, { nullable: true })
    async mjBizAppsCommonOrganization(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonOrganization_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Organizations', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwOrganizations')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Organizations', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Organizations', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonOrganization_)
    async CreatemjBizAppsCommonOrganization(
        @Arg('input', () => CreatemjBizAppsCommonOrganizationInput) input: CreatemjBizAppsCommonOrganizationInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Organizations', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonOrganization_)
    async UpdatemjBizAppsCommonOrganization(
        @Arg('input', () => UpdatemjBizAppsCommonOrganizationInput) input: UpdatemjBizAppsCommonOrganizationInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Organizations', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonOrganization_)
    async DeletemjBizAppsCommonOrganization(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Organizations', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: People
//****************************************************************************
@ObjectType({ description: `Individual people, optionally linked to MJ system user accounts` })
export class mjBizAppsCommonPerson_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field({description: `First (given) name`}) 
    @MaxLength(100)
    FirstName: string;
        
    @Field({description: `Last (family) name`}) 
    @MaxLength(100)
    LastName: string;
        
    @Field({nullable: true, description: `Middle name or initial`}) 
    @MaxLength(100)
    MiddleName?: string;
        
    @Field({nullable: true, description: `Name prefix such as Dr., Mr., Ms., Rev.`}) 
    @MaxLength(20)
    Prefix?: string;
        
    @Field({nullable: true, description: `Name suffix such as Jr., III, PhD, Esq.`}) 
    @MaxLength(20)
    Suffix?: string;
        
    @Field({nullable: true, description: `Nickname or preferred name the person goes by`}) 
    @MaxLength(100)
    PreferredName?: string;
        
    @Field({nullable: true, description: `Professional or job title, e.g. VP of Engineering, Board Director`}) 
    @MaxLength(200)
    Title?: string;
        
    @Field({nullable: true, description: `Primary email address for this person`}) 
    @MaxLength(255)
    Email?: string;
        
    @Field({nullable: true, description: `Primary phone number for this person`}) 
    @MaxLength(50)
    Phone?: string;
        
    @Field({nullable: true, description: `Date of birth`}) 
    DateOfBirth?: Date;
        
    @Field({nullable: true, description: `Gender identity`}) 
    @MaxLength(50)
    Gender?: string;
        
    @Field({nullable: true, description: `URL to profile photo or avatar image`}) 
    @MaxLength(1000)
    PhotoURL?: string;
        
    @Field({nullable: true, description: `Biographical text or notes about this person`}) 
    Bio?: string;
        
    @Field({nullable: true, description: `DEPRECATED: Do not use. bizapps-common no longer reads or writes this column; person-to-MJ-User bindings are owned by platform-layer IS-A subtypes of Person (e.g., BCSaaS 'BC: People'). Retained only for backward compatibility and scheduled for removal in the next major release.`}) 
    @MaxLength(36)
    LinkedUserID?: string;
        
    @Field({description: `Current status: Active, Inactive, or Deceased`}) 
    @MaxLength(50)
    Status: string;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
    @Field() 
    @MaxLength(201)
    DisplayName: string;
        
    @Field({nullable: true}) 
    @MaxLength(100)
    LinkedUser?: string;
        
    @Field(() => Float, {nullable: true}) 
    _mj__Latitude?: number;
        
    @Field(() => Float, {nullable: true}) 
    _mj__Longitude?: number;
        
    @Field({nullable: true}) 
    @MaxLength(255)
    PrimaryAddressLine1?: string;
        
    @Field({nullable: true}) 
    @MaxLength(255)
    PrimaryAddressLine2?: string;
        
    @Field({nullable: true}) 
    @MaxLength(100)
    PrimaryAddressCity?: string;
        
    @Field({nullable: true}) 
    @MaxLength(100)
    PrimaryAddressState?: string;
        
    @Field({nullable: true}) 
    @MaxLength(20)
    PrimaryAddressPostalCode?: string;
        
    @Field({nullable: true}) 
    @MaxLength(100)
    PrimaryAddressCountry?: string;
        
    @Field(() => Float, {nullable: true}) 
    PrimaryAddressLatitude?: number;
        
    @Field(() => Float, {nullable: true}) 
    PrimaryAddressLongitude?: number;
        
    @Field({nullable: true}) 
    @MaxLength(100)
    PrimaryAddressType?: string;
        
    @Field({nullable: true}) 
    @MaxLength(500)
    PrimaryEmail?: string;
        
    @Field({nullable: true}) 
    @MaxLength(500)
    PrimaryPhone?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    CurrentOrganizationID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(255)
    CurrentOrganizationName?: string;
        
    @Field({nullable: true}) 
    @MaxLength(255)
    CurrentJobTitle?: string;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: People
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonPersonInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    FirstName?: string;

    @Field({ nullable: true })
    LastName?: string;

    @Field({ nullable: true })
    MiddleName: string | null;

    @Field({ nullable: true })
    Prefix: string | null;

    @Field({ nullable: true })
    Suffix: string | null;

    @Field({ nullable: true })
    PreferredName: string | null;

    @Field({ nullable: true })
    Title: string | null;

    @Field({ nullable: true })
    Email: string | null;

    @Field({ nullable: true })
    Phone: string | null;

    @Field({ nullable: true })
    DateOfBirth: Date | null;

    @Field({ nullable: true })
    Gender: string | null;

    @Field({ nullable: true })
    PhotoURL: string | null;

    @Field({ nullable: true })
    Bio: string | null;

    @Field({ nullable: true })
    LinkedUserID: string | null;

    @Field({ nullable: true })
    Status?: string;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: People
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonPersonInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    FirstName?: string;

    @Field({ nullable: true })
    LastName?: string;

    @Field({ nullable: true })
    MiddleName?: string | null;

    @Field({ nullable: true })
    Prefix?: string | null;

    @Field({ nullable: true })
    Suffix?: string | null;

    @Field({ nullable: true })
    PreferredName?: string | null;

    @Field({ nullable: true })
    Title?: string | null;

    @Field({ nullable: true })
    Email?: string | null;

    @Field({ nullable: true })
    Phone?: string | null;

    @Field({ nullable: true })
    DateOfBirth?: Date | null;

    @Field({ nullable: true })
    Gender?: string | null;

    @Field({ nullable: true })
    PhotoURL?: string | null;

    @Field({ nullable: true })
    Bio?: string | null;

    @Field({ nullable: true })
    LinkedUserID?: string | null;

    @Field({ nullable: true })
    Status?: string;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: People
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonPersonViewResult {
    @Field(() => [mjBizAppsCommonPerson_])
    Results: mjBizAppsCommonPerson_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonPerson_)
export class mjBizAppsCommonPersonResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonPersonViewResult)
    async RunmjBizAppsCommonPersonViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonPersonViewResult)
    async RunmjBizAppsCommonPersonViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonPersonViewResult)
    async RunmjBizAppsCommonPersonDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: People';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonPerson_, { nullable: true })
    async mjBizAppsCommonPerson(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonPerson_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: People', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwPeople')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: People', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: People', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonPerson_)
    async CreatemjBizAppsCommonPerson(
        @Arg('input', () => CreatemjBizAppsCommonPersonInput) input: CreatemjBizAppsCommonPersonInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: People', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonPerson_)
    async UpdatemjBizAppsCommonPerson(
        @Arg('input', () => UpdatemjBizAppsCommonPersonInput) input: UpdatemjBizAppsCommonPersonInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: People', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonPerson_)
    async DeletemjBizAppsCommonPerson(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: People', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Relationship Types
//****************************************************************************
@ObjectType({ description: `Defines types of relationships between people and organizations with directionality and labeling` })
export class mjBizAppsCommonRelationshipType_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field({description: `Display name for the relationship type, e.g. Employee, Spouse, Partner`}) 
    @MaxLength(100)
    Name: string;
        
    @Field({nullable: true, description: `Detailed description of this relationship type`}) 
    Description?: string;
        
    @Field({description: `Which entity types this relationship connects: PersonToPerson, PersonToOrganization, or OrganizationToOrganization`}) 
    @MaxLength(50)
    Category: string;
        
    @Field(() => Boolean, {description: `Whether the relationship has a direction. False for symmetric relationships like Spouse or Partner`}) 
    IsDirectional: boolean;
        
    @Field({nullable: true, description: `Label describing the From-to-To direction, e.g. is employee of, is parent of`}) 
    @MaxLength(100)
    ForwardLabel?: string;
        
    @Field({nullable: true, description: `Label describing the To-to-From direction, e.g. employs, is child of`}) 
    @MaxLength(100)
    ReverseLabel?: string;
        
    @Field(() => Boolean, {description: `Whether this type is available for selection in the UI. Inactive types are hidden from dropdowns but preserved for existing records`}) 
    IsActive: boolean;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Relationship Types
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonRelationshipTypeInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description: string | null;

    @Field({ nullable: true })
    Category?: string;

    @Field(() => Boolean, { nullable: true })
    IsDirectional?: boolean;

    @Field({ nullable: true })
    ForwardLabel: string | null;

    @Field({ nullable: true })
    ReverseLabel: string | null;

    @Field(() => Boolean, { nullable: true })
    IsActive?: boolean;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Relationship Types
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonRelationshipTypeInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description?: string | null;

    @Field({ nullable: true })
    Category?: string;

    @Field(() => Boolean, { nullable: true })
    IsDirectional?: boolean;

    @Field({ nullable: true })
    ForwardLabel?: string | null;

    @Field({ nullable: true })
    ReverseLabel?: string | null;

    @Field(() => Boolean, { nullable: true })
    IsActive?: boolean;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Relationship Types
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonRelationshipTypeViewResult {
    @Field(() => [mjBizAppsCommonRelationshipType_])
    Results: mjBizAppsCommonRelationshipType_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonRelationshipType_)
export class mjBizAppsCommonRelationshipTypeResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonRelationshipTypeViewResult)
    async RunmjBizAppsCommonRelationshipTypeViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonRelationshipTypeViewResult)
    async RunmjBizAppsCommonRelationshipTypeViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonRelationshipTypeViewResult)
    async RunmjBizAppsCommonRelationshipTypeDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Relationship Types';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonRelationshipType_, { nullable: true })
    async mjBizAppsCommonRelationshipType(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonRelationshipType_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Relationship Types', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwRelationshipTypes')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Relationship Types', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Relationship Types', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonRelationshipType_)
    async CreatemjBizAppsCommonRelationshipType(
        @Arg('input', () => CreatemjBizAppsCommonRelationshipTypeInput) input: CreatemjBizAppsCommonRelationshipTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Relationship Types', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonRelationshipType_)
    async UpdatemjBizAppsCommonRelationshipType(
        @Arg('input', () => UpdatemjBizAppsCommonRelationshipTypeInput) input: UpdatemjBizAppsCommonRelationshipTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Relationship Types', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonRelationshipType_)
    async DeletemjBizAppsCommonRelationshipType(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Relationship Types', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for MJ_BizApps_Common: Relationships
//****************************************************************************
@ObjectType({ description: `Typed, directional links between people and organizations supporting Person-to-Person, Person-to-Organization, and Organization-to-Organization relationships` })
export class mjBizAppsCommonRelationship_ {
    @Field() 
    @MaxLength(36)
    ID: string;
        
    @Field() 
    @MaxLength(36)
    RelationshipTypeID: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    FromPersonID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    FromOrganizationID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    ToPersonID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(36)
    ToOrganizationID?: string;
        
    @Field({nullable: true, description: `Contextual title for this specific relationship, e.g. CEO, Primary Contact, Founding Member`}) 
    @MaxLength(255)
    Title?: string;
        
    @Field({nullable: true, description: `Date the relationship began`}) 
    StartDate?: Date;
        
    @Field({nullable: true, description: `Date the relationship ended, if applicable`}) 
    EndDate?: Date;
        
    @Field({description: `Current status: Active, Inactive, or Ended`}) 
    @MaxLength(50)
    Status: string;
        
    @Field({nullable: true, description: `Additional notes about this relationship`}) 
    Notes?: string;
        
    @Field() 
    _mj__CreatedAt: Date;
        
    @Field() 
    _mj__UpdatedAt: Date;
        
    @Field() 
    @MaxLength(100)
    RelationshipType: string;
        
    @Field({nullable: true}) 
    @MaxLength(201)
    FromPerson?: string;
        
    @Field({nullable: true}) 
    @MaxLength(255)
    FromOrganization?: string;
        
    @Field({nullable: true}) 
    @MaxLength(201)
    ToPerson?: string;
        
    @Field({nullable: true}) 
    @MaxLength(255)
    ToOrganization?: string;
        
}

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Relationships
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonRelationshipInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    RelationshipTypeID?: string;

    @Field({ nullable: true })
    FromPersonID: string | null;

    @Field({ nullable: true })
    FromOrganizationID: string | null;

    @Field({ nullable: true })
    ToPersonID: string | null;

    @Field({ nullable: true })
    ToOrganizationID: string | null;

    @Field({ nullable: true })
    Title: string | null;

    @Field({ nullable: true })
    StartDate: Date | null;

    @Field({ nullable: true })
    EndDate: Date | null;

    @Field({ nullable: true })
    Status?: string;

    @Field({ nullable: true })
    Notes: string | null;

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    

//****************************************************************************
// INPUT TYPE for MJ_BizApps_Common: Relationships
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonRelationshipInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    RelationshipTypeID?: string;

    @Field({ nullable: true })
    FromPersonID?: string | null;

    @Field({ nullable: true })
    FromOrganizationID?: string | null;

    @Field({ nullable: true })
    ToPersonID?: string | null;

    @Field({ nullable: true })
    ToOrganizationID?: string | null;

    @Field({ nullable: true })
    Title?: string | null;

    @Field({ nullable: true })
    StartDate?: Date | null;

    @Field({ nullable: true })
    EndDate?: Date | null;

    @Field({ nullable: true })
    Status?: string;

    @Field({ nullable: true })
    Notes?: string | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];

    @Field(() => RestoreContextInput, { nullable: true })
    RestoreContext___?: RestoreContextInput;
}
    
//****************************************************************************
// RESOLVER for MJ_BizApps_Common: Relationships
//****************************************************************************
@ObjectType()
export class RunmjBizAppsCommonRelationshipViewResult {
    @Field(() => [mjBizAppsCommonRelationship_])
    Results: mjBizAppsCommonRelationship_[];

    @Field(() => String, {nullable: true})
    UserViewRunID?: string;

    @Field(() => Int, {nullable: true})
    RowCount: number;

    @Field(() => Int, {nullable: true})
    TotalRowCount: number;

    @Field(() => Int, {nullable: true})
    ExecutionTime: number;

    @Field({nullable: true})
    ErrorMessage?: string;

    @Field(() => Boolean, {nullable: false})
    Success: boolean;
}

@Resolver(mjBizAppsCommonRelationship_)
export class mjBizAppsCommonRelationshipResolver extends ResolverBase {
    @Query(() => RunmjBizAppsCommonRelationshipViewResult)
    async RunmjBizAppsCommonRelationshipViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonRelationshipViewResult)
    async RunmjBizAppsCommonRelationshipViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjBizAppsCommonRelationshipViewResult)
    async RunmjBizAppsCommonRelationshipDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'MJ_BizApps_Common: Relationships';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonRelationship_, { nullable: true })
    async mjBizAppsCommonRelationship(@Arg('ID', () => String) ID: string, @Ctx() { userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonRelationship_ | null> {
        this.CheckUserReadPermissions('MJ_BizApps_Common: Relationships', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM ${provider.QuoteSchemaAndView('__mj_BizAppsCommon', 'vwRelationships')} WHERE ${provider.QuoteIdentifier('ID')}=${provider.BuildParameterPlaceholder(0)} ` + this.getRowLevelSecurityWhereClause(provider, 'MJ_BizApps_Common: Relationships', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await provider.ExecuteSQL(sSQL, [ID], undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('MJ_BizApps_Common: Relationships', rows && rows.length > 0 ? rows[0] : null, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonRelationship_)
    async CreatemjBizAppsCommonRelationship(
        @Arg('input', () => CreatemjBizAppsCommonRelationshipInput) input: CreatemjBizAppsCommonRelationshipInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('MJ_BizApps_Common: Relationships', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonRelationship_)
    async UpdatemjBizAppsCommonRelationship(
        @Arg('input', () => UpdatemjBizAppsCommonRelationshipInput) input: UpdatemjBizAppsCommonRelationshipInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('MJ_BizApps_Common: Relationships', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonRelationship_)
    async DeletemjBizAppsCommonRelationship(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('MJ_BizApps_Common: Relationships', key, options, provider, userPayload, pubSub);
    }
    
}