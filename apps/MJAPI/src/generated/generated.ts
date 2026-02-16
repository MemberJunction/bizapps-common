/********************************************************************************
* ALL ENTITIES - TypeGraphQL Type Class Definition - AUTO GENERATED FILE
* Generated Entities and Resolvers for Server
*
*   >>> DO NOT MODIFY THIS FILE!!!!!!!!!!!!
*   >>> YOUR CHANGES WILL BE OVERWRITTEN
*   >>> THE NEXT TIME THIS FILE IS GENERATED
*
**********************************************************************************/
import { Arg, Ctx, Int, Query, Resolver, Field, Float, ObjectType, FieldResolver, Root, InputType, Mutation,
            PubSub, PubSubEngine, ResolverBase, RunViewByIDInput, RunViewByNameInput, RunDynamicViewInput,
            AppContext, KeyValuePairInput, DeleteOptionsInput, GraphQLTimestamp as Timestamp,
            GetReadOnlyDataSource, GetReadWriteDataSource, GetReadOnlyProvider, GetReadWriteProvider } from '@memberjunction/server';
import { SQLServerDataProvider } from '@memberjunction/sqlserver-dataprovider';
import { Metadata, EntityPermissionType, CompositeKey, UserInfo } from '@memberjunction/core'

import { MaxLength } from 'class-validator';
import * as mj_core_schema_server_object_types from '@memberjunction/server'


import { ActionItemEntity, AgendaItemEntity, ArtifactTypeEntity, ArtifactEntity, AttendanceEntity, CommitteeEntity, MeetingEntity, MembershipEntity, MinuteEntity, MotionEntity, RoleEntity, TermEntity, TypeEntity, VoteEntity, AddressLinkEntity, AddressTypeEntity, AddressEntity, ContactMethodEntity, ContactTypeEntity, OrganizationTypeEntity, OrganizationEntity, PersonEntity, RelationshipTypeEntity, RelationshipEntity } from 'mj_generatedentities';
    

//****************************************************************************
// ENTITY CLASS for Committees: Action Items
//****************************************************************************
@ObjectType({ description: `Tasks and action items assigned from committees or meetings` })
export class mjCommitteesActionItem_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field() 
    @MaxLength(16)
    CommitteeID: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    MeetingID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    AgendaItemID?: string;
        
    @Field({description: `Title of the action item`}) 
    @MaxLength(510)
    Title: string;
        
    @Field({nullable: true, description: `Detailed description of what needs to be done`}) 
    Description?: string;
        
    @Field() 
    @MaxLength(16)
    AssignedToPersonID: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    AssignedByPersonID?: string;
        
    @Field({nullable: true, description: `Due date for completion`}) 
    @MaxLength(3)
    DueDate?: Date;
        
    @Field({description: `Priority level: Low, Medium, High, Critical`}) 
    @MaxLength(40)
    Priority: string;
        
    @Field({description: `Current status: Open, InProgress, Blocked, Completed, Cancelled`}) 
    @MaxLength(100)
    Status: string;
        
    @Field({nullable: true, description: `Timestamp when the action item was completed`}) 
    @MaxLength(10)
    CompletedAt?: Date;
        
    @Field({nullable: true, description: `Notes about how the item was completed`}) 
    CompletionNotes?: string;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field() 
    @MaxLength(510)
    Committee: string;
        
    @Field(() => [mjCommitteesArtifact_])
    Committees_Artifacts_ActionItemIDArray: mjCommitteesArtifact_[]; // Link to Committees_Artifacts
    
}

//****************************************************************************
// INPUT TYPE for Committees: Action Items
//****************************************************************************
@InputType()
export class CreatemjCommitteesActionItemInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    CommitteeID?: string;

    @Field({ nullable: true })
    MeetingID: string | null;

    @Field({ nullable: true })
    AgendaItemID: string | null;

    @Field({ nullable: true })
    Title?: string;

    @Field({ nullable: true })
    Description: string | null;

    @Field({ nullable: true })
    AssignedToPersonID?: string;

    @Field({ nullable: true })
    AssignedByPersonID: string | null;

    @Field({ nullable: true })
    DueDate: Date | null;

    @Field({ nullable: true })
    Priority?: string;

    @Field({ nullable: true })
    Status?: string;

    @Field({ nullable: true })
    CompletedAt: Date | null;

    @Field({ nullable: true })
    CompletionNotes: string | null;
}
    

//****************************************************************************
// INPUT TYPE for Committees: Action Items
//****************************************************************************
@InputType()
export class UpdatemjCommitteesActionItemInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    CommitteeID?: string;

    @Field({ nullable: true })
    MeetingID?: string | null;

    @Field({ nullable: true })
    AgendaItemID?: string | null;

    @Field({ nullable: true })
    Title?: string;

    @Field({ nullable: true })
    Description?: string | null;

    @Field({ nullable: true })
    AssignedToPersonID?: string;

    @Field({ nullable: true })
    AssignedByPersonID?: string | null;

    @Field({ nullable: true })
    DueDate?: Date | null;

    @Field({ nullable: true })
    Priority?: string;

    @Field({ nullable: true })
    Status?: string;

    @Field({ nullable: true })
    CompletedAt?: Date | null;

    @Field({ nullable: true })
    CompletionNotes?: string | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];
}
    
//****************************************************************************
// RESOLVER for Committees: Action Items
//****************************************************************************
@ObjectType()
export class RunmjCommitteesActionItemViewResult {
    @Field(() => [mjCommitteesActionItem_])
    Results: mjCommitteesActionItem_[];

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

@Resolver(mjCommitteesActionItem_)
export class mjCommitteesActionItemResolver extends ResolverBase {
    @Query(() => RunmjCommitteesActionItemViewResult)
    async RunmjCommitteesActionItemViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesActionItemViewResult)
    async RunmjCommitteesActionItemViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesActionItemViewResult)
    async RunmjCommitteesActionItemDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'Committees: Action Items';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjCommitteesActionItem_, { nullable: true })
    async mjCommitteesActionItem(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjCommitteesActionItem_ | null> {
        this.CheckUserReadPermissions('Committees: Action Items', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwActionItems] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Action Items', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Committees: Action Items', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @FieldResolver(() => [mjCommitteesArtifact_])
    async Committees_Artifacts_ActionItemIDArray(@Root() mjcommitteesactionitem_: mjCommitteesActionItem_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Artifacts', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwArtifacts] WHERE [ActionItemID]='${mjcommitteesactionitem_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Artifacts', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Artifacts', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @Mutation(() => mjCommitteesActionItem_)
    async CreatemjCommitteesActionItem(
        @Arg('input', () => CreatemjCommitteesActionItemInput) input: CreatemjCommitteesActionItemInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Committees: Action Items', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjCommitteesActionItem_)
    async UpdatemjCommitteesActionItem(
        @Arg('input', () => UpdatemjCommitteesActionItemInput) input: UpdatemjCommitteesActionItemInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Committees: Action Items', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjCommitteesActionItem_)
    async DeletemjCommitteesActionItem(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Committees: Action Items', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Committees: Agenda Items
//****************************************************************************
@ObjectType({ description: `Structured agenda items for meetings with hierarchy support` })
export class mjCommitteesAgendaItem_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field() 
    @MaxLength(16)
    MeetingID: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    ParentAgendaItemID?: string;
        
    @Field(() => Int, {description: `Display order within the meeting agenda`}) 
    Sequence: number;
        
    @Field({description: `Title of the agenda item`}) 
    @MaxLength(510)
    Title: string;
        
    @Field({nullable: true, description: `Detailed description of the agenda item`}) 
    Description?: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    PresenterPersonID?: string;
        
    @Field(() => Int, {nullable: true, description: `Estimated duration in minutes`}) 
    DurationMinutes?: number;
        
    @Field({description: `Type of item: Information, Discussion, Action, Vote, Report, Other`}) 
    @MaxLength(100)
    ItemType: string;
        
    @Field({nullable: true, description: `URL to related document for this item`}) 
    @MaxLength(2000)
    RelatedDocumentURL?: string;
        
    @Field({description: `Current status: Pending, Discussed, Tabled, Completed, Skipped`}) 
    @MaxLength(100)
    Status: string;
        
    @Field({nullable: true, description: `Discussion notes and outcomes captured during the meeting`}) 
    Notes?: string;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    RootParentAgendaItemID?: string;
        
    @Field(() => [mjCommitteesMotion_])
    Committees_Motions_AgendaItemIDArray: mjCommitteesMotion_[]; // Link to Committees_Motions
    
    @Field(() => [mjCommitteesAgendaItem_])
    Committees_AgendaItems_ParentAgendaItemIDArray: mjCommitteesAgendaItem_[]; // Link to Committees_AgendaItems
    
    @Field(() => [mjCommitteesArtifact_])
    Committees_Artifacts_AgendaItemIDArray: mjCommitteesArtifact_[]; // Link to Committees_Artifacts
    
    @Field(() => [mjCommitteesActionItem_])
    Committees_ActionItems_AgendaItemIDArray: mjCommitteesActionItem_[]; // Link to Committees_ActionItems
    
}

//****************************************************************************
// INPUT TYPE for Committees: Agenda Items
//****************************************************************************
@InputType()
export class CreatemjCommitteesAgendaItemInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    MeetingID?: string;

    @Field({ nullable: true })
    ParentAgendaItemID: string | null;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field({ nullable: true })
    Title?: string;

    @Field({ nullable: true })
    Description: string | null;

    @Field({ nullable: true })
    PresenterPersonID: string | null;

    @Field(() => Int, { nullable: true })
    DurationMinutes: number | null;

    @Field({ nullable: true })
    ItemType?: string;

    @Field({ nullable: true })
    RelatedDocumentURL: string | null;

    @Field({ nullable: true })
    Status?: string;

    @Field({ nullable: true })
    Notes: string | null;
}
    

//****************************************************************************
// INPUT TYPE for Committees: Agenda Items
//****************************************************************************
@InputType()
export class UpdatemjCommitteesAgendaItemInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    MeetingID?: string;

    @Field({ nullable: true })
    ParentAgendaItemID?: string | null;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field({ nullable: true })
    Title?: string;

    @Field({ nullable: true })
    Description?: string | null;

    @Field({ nullable: true })
    PresenterPersonID?: string | null;

    @Field(() => Int, { nullable: true })
    DurationMinutes?: number | null;

    @Field({ nullable: true })
    ItemType?: string;

    @Field({ nullable: true })
    RelatedDocumentURL?: string | null;

    @Field({ nullable: true })
    Status?: string;

    @Field({ nullable: true })
    Notes?: string | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];
}
    
//****************************************************************************
// RESOLVER for Committees: Agenda Items
//****************************************************************************
@ObjectType()
export class RunmjCommitteesAgendaItemViewResult {
    @Field(() => [mjCommitteesAgendaItem_])
    Results: mjCommitteesAgendaItem_[];

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

@Resolver(mjCommitteesAgendaItem_)
export class mjCommitteesAgendaItemResolver extends ResolverBase {
    @Query(() => RunmjCommitteesAgendaItemViewResult)
    async RunmjCommitteesAgendaItemViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesAgendaItemViewResult)
    async RunmjCommitteesAgendaItemViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesAgendaItemViewResult)
    async RunmjCommitteesAgendaItemDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'Committees: Agenda Items';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjCommitteesAgendaItem_, { nullable: true })
    async mjCommitteesAgendaItem(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjCommitteesAgendaItem_ | null> {
        this.CheckUserReadPermissions('Committees: Agenda Items', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwAgendaItems] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Agenda Items', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Committees: Agenda Items', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @FieldResolver(() => [mjCommitteesMotion_])
    async Committees_Motions_AgendaItemIDArray(@Root() mjcommitteesagendaitem_: mjCommitteesAgendaItem_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Motions', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwMotions] WHERE [AgendaItemID]='${mjcommitteesagendaitem_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Motions', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Motions', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesAgendaItem_])
    async Committees_AgendaItems_ParentAgendaItemIDArray(@Root() mjcommitteesagendaitem_: mjCommitteesAgendaItem_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Agenda Items', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwAgendaItems] WHERE [ParentAgendaItemID]='${mjcommitteesagendaitem_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Agenda Items', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Agenda Items', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesArtifact_])
    async Committees_Artifacts_AgendaItemIDArray(@Root() mjcommitteesagendaitem_: mjCommitteesAgendaItem_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Artifacts', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwArtifacts] WHERE [AgendaItemID]='${mjcommitteesagendaitem_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Artifacts', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Artifacts', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesActionItem_])
    async Committees_ActionItems_AgendaItemIDArray(@Root() mjcommitteesagendaitem_: mjCommitteesAgendaItem_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Action Items', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwActionItems] WHERE [AgendaItemID]='${mjcommitteesagendaitem_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Action Items', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Action Items', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @Mutation(() => mjCommitteesAgendaItem_)
    async CreatemjCommitteesAgendaItem(
        @Arg('input', () => CreatemjCommitteesAgendaItemInput) input: CreatemjCommitteesAgendaItemInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Committees: Agenda Items', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjCommitteesAgendaItem_)
    async UpdatemjCommitteesAgendaItem(
        @Arg('input', () => UpdatemjCommitteesAgendaItemInput) input: UpdatemjCommitteesAgendaItemInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Committees: Agenda Items', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjCommitteesAgendaItem_)
    async DeletemjCommitteesAgendaItem(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Committees: Agenda Items', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Committees: Artifact Types
//****************************************************************************
@ObjectType({ description: `Categories of committee artifacts with optional extension entity for type-specific fields` })
export class mjCommitteesArtifactType_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field({description: `Display name for the artifact type`}) 
    @MaxLength(200)
    Name: string;
        
    @Field({nullable: true, description: `Detailed description of this artifact type`}) 
    Description?: string;
        
    @Field({nullable: true, description: `Optional reference to an MJ Entity that provides additional fields for this artifact type via a 1:1 extension table`}) 
    @MaxLength(16)
    ExtendedEntityID?: string;
        
    @Field({nullable: true, description: `Font Awesome icon class for UI display`}) 
    @MaxLength(200)
    IconClass?: string;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field({nullable: true}) 
    @MaxLength(510)
    ExtendedEntity?: string;
        
    @Field(() => [mjCommitteesArtifact_])
    Committees_Artifacts_ArtifactTypeIDArray: mjCommitteesArtifact_[]; // Link to Committees_Artifacts
    
}

//****************************************************************************
// INPUT TYPE for Committees: Artifact Types
//****************************************************************************
@InputType()
export class CreatemjCommitteesArtifactTypeInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description: string | null;

    @Field({ nullable: true })
    ExtendedEntityID: string | null;

    @Field({ nullable: true })
    IconClass: string | null;
}
    

//****************************************************************************
// INPUT TYPE for Committees: Artifact Types
//****************************************************************************
@InputType()
export class UpdatemjCommitteesArtifactTypeInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description?: string | null;

    @Field({ nullable: true })
    ExtendedEntityID?: string | null;

    @Field({ nullable: true })
    IconClass?: string | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];
}
    
//****************************************************************************
// RESOLVER for Committees: Artifact Types
//****************************************************************************
@ObjectType()
export class RunmjCommitteesArtifactTypeViewResult {
    @Field(() => [mjCommitteesArtifactType_])
    Results: mjCommitteesArtifactType_[];

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

@Resolver(mjCommitteesArtifactType_)
export class mjCommitteesArtifactTypeResolver extends ResolverBase {
    @Query(() => RunmjCommitteesArtifactTypeViewResult)
    async RunmjCommitteesArtifactTypeViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesArtifactTypeViewResult)
    async RunmjCommitteesArtifactTypeViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesArtifactTypeViewResult)
    async RunmjCommitteesArtifactTypeDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'Committees: Artifact Types';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjCommitteesArtifactType_, { nullable: true })
    async mjCommitteesArtifactType(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjCommitteesArtifactType_ | null> {
        this.CheckUserReadPermissions('Committees: Artifact Types', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwArtifactTypes] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Artifact Types', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Committees: Artifact Types', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @FieldResolver(() => [mjCommitteesArtifact_])
    async Committees_Artifacts_ArtifactTypeIDArray(@Root() mjcommitteesartifacttype_: mjCommitteesArtifactType_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Artifacts', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwArtifacts] WHERE [ArtifactTypeID]='${mjcommitteesartifacttype_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Artifacts', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Artifacts', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @Mutation(() => mjCommitteesArtifactType_)
    async CreatemjCommitteesArtifactType(
        @Arg('input', () => CreatemjCommitteesArtifactTypeInput) input: CreatemjCommitteesArtifactTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Committees: Artifact Types', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjCommitteesArtifactType_)
    async UpdatemjCommitteesArtifactType(
        @Arg('input', () => UpdatemjCommitteesArtifactTypeInput) input: UpdatemjCommitteesArtifactTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Committees: Artifact Types', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjCommitteesArtifactType_)
    async DeletemjCommitteesArtifactType(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Committees: Artifact Types', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Committees: Artifacts
//****************************************************************************
@ObjectType({ description: `Links to external documents and files from various providers` })
export class mjCommitteesArtifact_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    CommitteeID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    MeetingID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    AgendaItemID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    ActionItemID?: string;
        
    @Field({description: `Display title for the artifact`}) 
    @MaxLength(510)
    Title: string;
        
    @Field({nullable: true, description: `Description of the artifact contents`}) 
    Description?: string;
        
    @Field() 
    @MaxLength(16)
    ArtifactTypeID: string;
        
    @Field({description: `Storage provider: GoogleDrive, SharePoint, Box, OneDrive, Dropbox, URL`}) 
    @MaxLength(100)
    Provider: string;
        
    @Field({nullable: true, description: `Provider-specific document or file ID`}) 
    @MaxLength(1000)
    ExternalID?: string;
        
    @Field({description: `Direct URL to access the artifact`}) 
    @MaxLength(4000)
    URL: string;
        
    @Field({nullable: true, description: `MIME type of the file`}) 
    @MaxLength(200)
    MimeType?: string;
        
    @Field(() => Int, {nullable: true, description: `File size in bytes`}) 
    FileSize?: number;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    UploadedByPersonID?: string;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field({nullable: true}) 
    @MaxLength(510)
    Committee?: string;
        
    @Field() 
    @MaxLength(200)
    ArtifactType: string;
        
    @Field(() => [mjCommitteesMinute_])
    Committees_Minutes_ArtifactIDArray: mjCommitteesMinute_[]; // Link to Committees_Minutes
    
}

//****************************************************************************
// INPUT TYPE for Committees: Artifacts
//****************************************************************************
@InputType()
export class CreatemjCommitteesArtifactInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    CommitteeID: string | null;

    @Field({ nullable: true })
    MeetingID: string | null;

    @Field({ nullable: true })
    AgendaItemID: string | null;

    @Field({ nullable: true })
    ActionItemID: string | null;

    @Field({ nullable: true })
    Title?: string;

    @Field({ nullable: true })
    Description: string | null;

    @Field({ nullable: true })
    ArtifactTypeID?: string;

    @Field({ nullable: true })
    Provider?: string;

    @Field({ nullable: true })
    ExternalID: string | null;

    @Field({ nullable: true })
    URL?: string;

    @Field({ nullable: true })
    MimeType: string | null;

    @Field(() => Int, { nullable: true })
    FileSize: number | null;

    @Field({ nullable: true })
    UploadedByPersonID: string | null;
}
    

//****************************************************************************
// INPUT TYPE for Committees: Artifacts
//****************************************************************************
@InputType()
export class UpdatemjCommitteesArtifactInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    CommitteeID?: string | null;

    @Field({ nullable: true })
    MeetingID?: string | null;

    @Field({ nullable: true })
    AgendaItemID?: string | null;

    @Field({ nullable: true })
    ActionItemID?: string | null;

    @Field({ nullable: true })
    Title?: string;

    @Field({ nullable: true })
    Description?: string | null;

    @Field({ nullable: true })
    ArtifactTypeID?: string;

    @Field({ nullable: true })
    Provider?: string;

    @Field({ nullable: true })
    ExternalID?: string | null;

    @Field({ nullable: true })
    URL?: string;

    @Field({ nullable: true })
    MimeType?: string | null;

    @Field(() => Int, { nullable: true })
    FileSize?: number | null;

    @Field({ nullable: true })
    UploadedByPersonID?: string | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];
}
    
//****************************************************************************
// RESOLVER for Committees: Artifacts
//****************************************************************************
@ObjectType()
export class RunmjCommitteesArtifactViewResult {
    @Field(() => [mjCommitteesArtifact_])
    Results: mjCommitteesArtifact_[];

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

@Resolver(mjCommitteesArtifact_)
export class mjCommitteesArtifactResolver extends ResolverBase {
    @Query(() => RunmjCommitteesArtifactViewResult)
    async RunmjCommitteesArtifactViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesArtifactViewResult)
    async RunmjCommitteesArtifactViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesArtifactViewResult)
    async RunmjCommitteesArtifactDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'Committees: Artifacts';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjCommitteesArtifact_, { nullable: true })
    async mjCommitteesArtifact(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjCommitteesArtifact_ | null> {
        this.CheckUserReadPermissions('Committees: Artifacts', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwArtifacts] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Artifacts', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Committees: Artifacts', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @FieldResolver(() => [mjCommitteesMinute_])
    async Committees_Minutes_ArtifactIDArray(@Root() mjcommitteesartifact_: mjCommitteesArtifact_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Minutes', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwMinutes] WHERE [ArtifactID]='${mjcommitteesartifact_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Minutes', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Minutes', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @Mutation(() => mjCommitteesArtifact_)
    async CreatemjCommitteesArtifact(
        @Arg('input', () => CreatemjCommitteesArtifactInput) input: CreatemjCommitteesArtifactInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Committees: Artifacts', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjCommitteesArtifact_)
    async UpdatemjCommitteesArtifact(
        @Arg('input', () => UpdatemjCommitteesArtifactInput) input: UpdatemjCommitteesArtifactInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Committees: Artifacts', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjCommitteesArtifact_)
    async DeletemjCommitteesArtifact(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Committees: Artifacts', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Committees: Attendances
//****************************************************************************
@ObjectType({ description: `Meeting attendance records for committee members` })
export class mjCommitteesAttendance_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field() 
    @MaxLength(16)
    MeetingID: string;
        
    @Field() 
    @MaxLength(16)
    PersonID: string;
        
    @Field({description: `Attendance status: Expected, Present, Absent, Excused, Partial`}) 
    @MaxLength(100)
    AttendanceStatus: string;
        
    @Field({nullable: true, description: `Timestamp when the attendee joined the meeting`}) 
    @MaxLength(10)
    JoinedAt?: Date;
        
    @Field({nullable: true, description: `Timestamp when the attendee left the meeting`}) 
    @MaxLength(10)
    LeftAt?: Date;
        
    @Field({nullable: true, description: `Additional notes about attendance`}) 
    @MaxLength(1000)
    Notes?: string;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
}

//****************************************************************************
// INPUT TYPE for Committees: Attendances
//****************************************************************************
@InputType()
export class CreatemjCommitteesAttendanceInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    MeetingID?: string;

    @Field({ nullable: true })
    PersonID?: string;

    @Field({ nullable: true })
    AttendanceStatus?: string;

    @Field({ nullable: true })
    JoinedAt: Date | null;

    @Field({ nullable: true })
    LeftAt: Date | null;

    @Field({ nullable: true })
    Notes: string | null;
}
    

//****************************************************************************
// INPUT TYPE for Committees: Attendances
//****************************************************************************
@InputType()
export class UpdatemjCommitteesAttendanceInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    MeetingID?: string;

    @Field({ nullable: true })
    PersonID?: string;

    @Field({ nullable: true })
    AttendanceStatus?: string;

    @Field({ nullable: true })
    JoinedAt?: Date | null;

    @Field({ nullable: true })
    LeftAt?: Date | null;

    @Field({ nullable: true })
    Notes?: string | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];
}
    
//****************************************************************************
// RESOLVER for Committees: Attendances
//****************************************************************************
@ObjectType()
export class RunmjCommitteesAttendanceViewResult {
    @Field(() => [mjCommitteesAttendance_])
    Results: mjCommitteesAttendance_[];

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

@Resolver(mjCommitteesAttendance_)
export class mjCommitteesAttendanceResolver extends ResolverBase {
    @Query(() => RunmjCommitteesAttendanceViewResult)
    async RunmjCommitteesAttendanceViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesAttendanceViewResult)
    async RunmjCommitteesAttendanceViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesAttendanceViewResult)
    async RunmjCommitteesAttendanceDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'Committees: Attendances';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjCommitteesAttendance_, { nullable: true })
    async mjCommitteesAttendance(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjCommitteesAttendance_ | null> {
        this.CheckUserReadPermissions('Committees: Attendances', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwAttendances] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Attendances', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Committees: Attendances', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjCommitteesAttendance_)
    async CreatemjCommitteesAttendance(
        @Arg('input', () => CreatemjCommitteesAttendanceInput) input: CreatemjCommitteesAttendanceInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Committees: Attendances', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjCommitteesAttendance_)
    async UpdatemjCommitteesAttendance(
        @Arg('input', () => UpdatemjCommitteesAttendanceInput) input: UpdatemjCommitteesAttendanceInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Committees: Attendances', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjCommitteesAttendance_)
    async DeletemjCommitteesAttendance(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Committees: Attendances', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Committees: Committees
//****************************************************************************
@ObjectType({ description: `Core committee records with hierarchy support` })
export class mjCommitteesCommittee_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field({description: `Official name of the committee`}) 
    @MaxLength(510)
    Name: string;
        
    @Field({nullable: true, description: `Detailed description of the committee purpose and scope`}) 
    Description?: string;
        
    @Field() 
    @MaxLength(16)
    TypeID: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    ParentCommitteeID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    OrganizationID?: string;
        
    @Field({nullable: true, description: `URL to the committee charter document`}) 
    @MaxLength(2000)
    CharterDocumentURL?: string;
        
    @Field({nullable: true, description: `Brief statement of the committee mission`}) 
    MissionStatement?: string;
        
    @Field({description: `Current status: Active, Inactive, Pending, or Dissolved`}) 
    @MaxLength(100)
    Status: string;
        
    @Field(() => Boolean, {description: `Whether the committee is visible to all users`}) 
    IsPublic: boolean;
        
    @Field({nullable: true, description: `Date the committee was formed`}) 
    @MaxLength(3)
    FormationDate?: Date;
        
    @Field({nullable: true, description: `Date the committee was dissolved, if applicable`}) 
    @MaxLength(3)
    DissolutionDate?: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field() 
    @MaxLength(200)
    Type: string;
        
    @Field({nullable: true}) 
    @MaxLength(510)
    ParentCommittee?: string;
        
    @Field({nullable: true}) 
    @MaxLength(510)
    Organization?: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    RootParentCommitteeID?: string;
        
    @Field(() => [mjCommitteesMeeting_])
    Committees_Meetings_CommitteeIDArray: mjCommitteesMeeting_[]; // Link to Committees_Meetings
    
    @Field(() => [mjCommitteesCommittee_])
    Committees_Committees_ParentCommitteeIDArray: mjCommitteesCommittee_[]; // Link to Committees_Committees
    
    @Field(() => [mjCommitteesActionItem_])
    Committees_ActionItems_CommitteeIDArray: mjCommitteesActionItem_[]; // Link to Committees_ActionItems
    
    @Field(() => [mjCommitteesTerm_])
    Committees_Terms_CommitteeIDArray: mjCommitteesTerm_[]; // Link to Committees_Terms
    
    @Field(() => [mjCommitteesMembership_])
    Committees_Memberships_CommitteeIDArray: mjCommitteesMembership_[]; // Link to Committees_Memberships
    
    @Field(() => [mjCommitteesArtifact_])
    Committees_Artifacts_CommitteeIDArray: mjCommitteesArtifact_[]; // Link to Committees_Artifacts
    
}

//****************************************************************************
// INPUT TYPE for Committees: Committees
//****************************************************************************
@InputType()
export class CreatemjCommitteesCommitteeInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description: string | null;

    @Field({ nullable: true })
    TypeID?: string;

    @Field({ nullable: true })
    ParentCommitteeID: string | null;

    @Field({ nullable: true })
    OrganizationID: string | null;

    @Field({ nullable: true })
    CharterDocumentURL: string | null;

    @Field({ nullable: true })
    MissionStatement: string | null;

    @Field({ nullable: true })
    Status?: string;

    @Field(() => Boolean, { nullable: true })
    IsPublic?: boolean;

    @Field({ nullable: true })
    FormationDate: Date | null;

    @Field({ nullable: true })
    DissolutionDate: Date | null;
}
    

//****************************************************************************
// INPUT TYPE for Committees: Committees
//****************************************************************************
@InputType()
export class UpdatemjCommitteesCommitteeInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description?: string | null;

    @Field({ nullable: true })
    TypeID?: string;

    @Field({ nullable: true })
    ParentCommitteeID?: string | null;

    @Field({ nullable: true })
    OrganizationID?: string | null;

    @Field({ nullable: true })
    CharterDocumentURL?: string | null;

    @Field({ nullable: true })
    MissionStatement?: string | null;

    @Field({ nullable: true })
    Status?: string;

    @Field(() => Boolean, { nullable: true })
    IsPublic?: boolean;

    @Field({ nullable: true })
    FormationDate?: Date | null;

    @Field({ nullable: true })
    DissolutionDate?: Date | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];
}
    
//****************************************************************************
// RESOLVER for Committees: Committees
//****************************************************************************
@ObjectType()
export class RunmjCommitteesCommitteeViewResult {
    @Field(() => [mjCommitteesCommittee_])
    Results: mjCommitteesCommittee_[];

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

@Resolver(mjCommitteesCommittee_)
export class mjCommitteesCommitteeResolver extends ResolverBase {
    @Query(() => RunmjCommitteesCommitteeViewResult)
    async RunmjCommitteesCommitteeViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesCommitteeViewResult)
    async RunmjCommitteesCommitteeViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesCommitteeViewResult)
    async RunmjCommitteesCommitteeDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'Committees: Committees';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjCommitteesCommittee_, { nullable: true })
    async mjCommitteesCommittee(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjCommitteesCommittee_ | null> {
        this.CheckUserReadPermissions('Committees: Committees', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwCommittees] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Committees', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Committees: Committees', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @FieldResolver(() => [mjCommitteesMeeting_])
    async Committees_Meetings_CommitteeIDArray(@Root() mjcommitteescommittee_: mjCommitteesCommittee_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Meetings', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwMeetings] WHERE [CommitteeID]='${mjcommitteescommittee_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Meetings', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Meetings', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesCommittee_])
    async Committees_Committees_ParentCommitteeIDArray(@Root() mjcommitteescommittee_: mjCommitteesCommittee_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Committees', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwCommittees] WHERE [ParentCommitteeID]='${mjcommitteescommittee_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Committees', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Committees', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesActionItem_])
    async Committees_ActionItems_CommitteeIDArray(@Root() mjcommitteescommittee_: mjCommitteesCommittee_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Action Items', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwActionItems] WHERE [CommitteeID]='${mjcommitteescommittee_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Action Items', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Action Items', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesTerm_])
    async Committees_Terms_CommitteeIDArray(@Root() mjcommitteescommittee_: mjCommitteesCommittee_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Terms', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwTerms] WHERE [CommitteeID]='${mjcommitteescommittee_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Terms', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Terms', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesMembership_])
    async Committees_Memberships_CommitteeIDArray(@Root() mjcommitteescommittee_: mjCommitteesCommittee_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Memberships', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwMemberships] WHERE [CommitteeID]='${mjcommitteescommittee_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Memberships', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Memberships', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesArtifact_])
    async Committees_Artifacts_CommitteeIDArray(@Root() mjcommitteescommittee_: mjCommitteesCommittee_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Artifacts', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwArtifacts] WHERE [CommitteeID]='${mjcommitteescommittee_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Artifacts', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Artifacts', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @Mutation(() => mjCommitteesCommittee_)
    async CreatemjCommitteesCommittee(
        @Arg('input', () => CreatemjCommitteesCommitteeInput) input: CreatemjCommitteesCommitteeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Committees: Committees', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjCommitteesCommittee_)
    async UpdatemjCommitteesCommittee(
        @Arg('input', () => UpdatemjCommitteesCommitteeInput) input: UpdatemjCommitteesCommitteeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Committees: Committees', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjCommitteesCommittee_)
    async DeletemjCommitteesCommittee(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Committees: Committees', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Committees: Meetings
//****************************************************************************
@ObjectType({ description: `Committee meeting records with scheduling and video conferencing info` })
export class mjCommitteesMeeting_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field() 
    @MaxLength(16)
    CommitteeID: string;
        
    @Field({description: `Title of the meeting`}) 
    @MaxLength(510)
    Title: string;
        
    @Field({nullable: true, description: `Detailed description or purpose of the meeting`}) 
    Description?: string;
        
    @Field({description: `Scheduled start date and time with timezone offset`}) 
    @MaxLength(10)
    StartDateTime: Date;
        
    @Field({nullable: true, description: `Scheduled end date and time with timezone offset`}) 
    @MaxLength(10)
    EndDateTime?: Date;
        
    @Field({description: `IANA timezone identifier for the meeting`}) 
    @MaxLength(100)
    TimeZone: string;
        
    @Field({description: `Meeting format: Virtual, InPerson, or Hybrid`}) 
    @MaxLength(100)
    LocationType: string;
        
    @Field({nullable: true, description: `Physical address or room name for in-person meetings`}) 
    @MaxLength(1000)
    LocationText?: string;
        
    @Field({nullable: true, description: `Video conferencing provider: Zoom, Teams, Meet, etc.`}) 
    @MaxLength(100)
    VideoProvider?: string;
        
    @Field({nullable: true, description: `External meeting ID from the video provider`}) 
    @MaxLength(510)
    VideoMeetingID?: string;
        
    @Field({nullable: true, description: `URL to join the video meeting`}) 
    @MaxLength(2000)
    VideoJoinURL?: string;
        
    @Field({nullable: true, description: `URL to the meeting recording after completion`}) 
    @MaxLength(2000)
    VideoRecordingURL?: string;
        
    @Field({nullable: true, description: `URL to the meeting transcript`}) 
    @MaxLength(2000)
    TranscriptURL?: string;
        
    @Field({description: `Current status: Draft, Scheduled, InProgress, Completed, Cancelled, Postponed`}) 
    @MaxLength(100)
    Status: string;
        
    @Field({nullable: true, description: `External calendar event ID for sync purposes`}) 
    @MaxLength(510)
    CalendarEventID?: string;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field() 
    @MaxLength(510)
    Committee: string;
        
    @Field(() => [mjCommitteesMinute_])
    Committees_Minutes_ApprovedByMeetingIDArray: mjCommitteesMinute_[]; // Link to Committees_Minutes
    
    @Field(() => [mjCommitteesAttendance_])
    Committees_Attendances_MeetingIDArray: mjCommitteesAttendance_[]; // Link to Committees_Attendances
    
    @Field(() => [mjCommitteesAgendaItem_])
    Committees_AgendaItems_MeetingIDArray: mjCommitteesAgendaItem_[]; // Link to Committees_AgendaItems
    
    @Field(() => [mjCommitteesMotion_])
    Committees_Motions_MeetingIDArray: mjCommitteesMotion_[]; // Link to Committees_Motions
    
    @Field(() => [mjCommitteesActionItem_])
    Committees_ActionItems_MeetingIDArray: mjCommitteesActionItem_[]; // Link to Committees_ActionItems
    
    @Field(() => [mjCommitteesArtifact_])
    Committees_Artifacts_MeetingIDArray: mjCommitteesArtifact_[]; // Link to Committees_Artifacts
    
}

//****************************************************************************
// INPUT TYPE for Committees: Meetings
//****************************************************************************
@InputType()
export class CreatemjCommitteesMeetingInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    CommitteeID?: string;

    @Field({ nullable: true })
    Title?: string;

    @Field({ nullable: true })
    Description: string | null;

    @Field({ nullable: true })
    StartDateTime?: Date;

    @Field({ nullable: true })
    EndDateTime: Date | null;

    @Field({ nullable: true })
    TimeZone?: string;

    @Field({ nullable: true })
    LocationType?: string;

    @Field({ nullable: true })
    LocationText: string | null;

    @Field({ nullable: true })
    VideoProvider: string | null;

    @Field({ nullable: true })
    VideoMeetingID: string | null;

    @Field({ nullable: true })
    VideoJoinURL: string | null;

    @Field({ nullable: true })
    VideoRecordingURL: string | null;

    @Field({ nullable: true })
    TranscriptURL: string | null;

    @Field({ nullable: true })
    Status?: string;

    @Field({ nullable: true })
    CalendarEventID: string | null;
}
    

//****************************************************************************
// INPUT TYPE for Committees: Meetings
//****************************************************************************
@InputType()
export class UpdatemjCommitteesMeetingInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    CommitteeID?: string;

    @Field({ nullable: true })
    Title?: string;

    @Field({ nullable: true })
    Description?: string | null;

    @Field({ nullable: true })
    StartDateTime?: Date;

    @Field({ nullable: true })
    EndDateTime?: Date | null;

    @Field({ nullable: true })
    TimeZone?: string;

    @Field({ nullable: true })
    LocationType?: string;

    @Field({ nullable: true })
    LocationText?: string | null;

    @Field({ nullable: true })
    VideoProvider?: string | null;

    @Field({ nullable: true })
    VideoMeetingID?: string | null;

    @Field({ nullable: true })
    VideoJoinURL?: string | null;

    @Field({ nullable: true })
    VideoRecordingURL?: string | null;

    @Field({ nullable: true })
    TranscriptURL?: string | null;

    @Field({ nullable: true })
    Status?: string;

    @Field({ nullable: true })
    CalendarEventID?: string | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];
}
    
//****************************************************************************
// RESOLVER for Committees: Meetings
//****************************************************************************
@ObjectType()
export class RunmjCommitteesMeetingViewResult {
    @Field(() => [mjCommitteesMeeting_])
    Results: mjCommitteesMeeting_[];

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

@Resolver(mjCommitteesMeeting_)
export class mjCommitteesMeetingResolver extends ResolverBase {
    @Query(() => RunmjCommitteesMeetingViewResult)
    async RunmjCommitteesMeetingViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesMeetingViewResult)
    async RunmjCommitteesMeetingViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesMeetingViewResult)
    async RunmjCommitteesMeetingDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'Committees: Meetings';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjCommitteesMeeting_, { nullable: true })
    async mjCommitteesMeeting(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjCommitteesMeeting_ | null> {
        this.CheckUserReadPermissions('Committees: Meetings', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwMeetings] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Meetings', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Committees: Meetings', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @FieldResolver(() => [mjCommitteesMinute_])
    async Committees_Minutes_ApprovedByMeetingIDArray(@Root() mjcommitteesmeeting_: mjCommitteesMeeting_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Minutes', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwMinutes] WHERE [ApprovedByMeetingID]='${mjcommitteesmeeting_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Minutes', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Minutes', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesAttendance_])
    async Committees_Attendances_MeetingIDArray(@Root() mjcommitteesmeeting_: mjCommitteesMeeting_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Attendances', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwAttendances] WHERE [MeetingID]='${mjcommitteesmeeting_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Attendances', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Attendances', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesAgendaItem_])
    async Committees_AgendaItems_MeetingIDArray(@Root() mjcommitteesmeeting_: mjCommitteesMeeting_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Agenda Items', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwAgendaItems] WHERE [MeetingID]='${mjcommitteesmeeting_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Agenda Items', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Agenda Items', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesMotion_])
    async Committees_Motions_MeetingIDArray(@Root() mjcommitteesmeeting_: mjCommitteesMeeting_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Motions', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwMotions] WHERE [MeetingID]='${mjcommitteesmeeting_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Motions', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Motions', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesActionItem_])
    async Committees_ActionItems_MeetingIDArray(@Root() mjcommitteesmeeting_: mjCommitteesMeeting_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Action Items', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwActionItems] WHERE [MeetingID]='${mjcommitteesmeeting_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Action Items', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Action Items', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesArtifact_])
    async Committees_Artifacts_MeetingIDArray(@Root() mjcommitteesmeeting_: mjCommitteesMeeting_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Artifacts', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwArtifacts] WHERE [MeetingID]='${mjcommitteesmeeting_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Artifacts', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Artifacts', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @Mutation(() => mjCommitteesMeeting_)
    async CreatemjCommitteesMeeting(
        @Arg('input', () => CreatemjCommitteesMeetingInput) input: CreatemjCommitteesMeetingInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Committees: Meetings', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjCommitteesMeeting_)
    async UpdatemjCommitteesMeeting(
        @Arg('input', () => UpdatemjCommitteesMeetingInput) input: UpdatemjCommitteesMeetingInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Committees: Meetings', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjCommitteesMeeting_)
    async DeletemjCommitteesMeeting(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Committees: Meetings', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Committees: Memberships
//****************************************************************************
@ObjectType({ description: `Person assignments to committees with roles and terms` })
export class mjCommitteesMembership_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field() 
    @MaxLength(16)
    CommitteeID: string;
        
    @Field() 
    @MaxLength(16)
    PersonID: string;
        
    @Field() 
    @MaxLength(16)
    RoleID: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    TermID?: string;
        
    @Field({description: `Date the membership started`}) 
    @MaxLength(3)
    StartDate: Date;
        
    @Field({nullable: true, description: `Date the membership ended, if applicable`}) 
    @MaxLength(3)
    EndDate?: Date;
        
    @Field({description: `Current status: Active, Pending, Ended, or Suspended`}) 
    @MaxLength(100)
    Status: string;
        
    @Field({nullable: true, description: `Reason the membership ended: Term ended, Resigned, Removed, etc.`}) 
    @MaxLength(200)
    EndReason?: string;
        
    @Field({nullable: true, description: `Additional notes about this membership`}) 
    Notes?: string;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field() 
    @MaxLength(510)
    Committee: string;
        
    @Field() 
    @MaxLength(200)
    Role: string;
        
    @Field({nullable: true}) 
    @MaxLength(200)
    Term?: string;
        
    @Field(() => [mjCommitteesMotion_])
    Committees_Motions_MovedByMembershipIDArray: mjCommitteesMotion_[]; // Link to Committees_Motions
    
    @Field(() => [mjCommitteesVote_])
    Committees_Votes_MembershipIDArray: mjCommitteesVote_[]; // Link to Committees_Votes
    
    @Field(() => [mjCommitteesMotion_])
    Committees_Motions_SecondedByMembershipIDArray: mjCommitteesMotion_[]; // Link to Committees_Motions
    
}

//****************************************************************************
// INPUT TYPE for Committees: Memberships
//****************************************************************************
@InputType()
export class CreatemjCommitteesMembershipInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    CommitteeID?: string;

    @Field({ nullable: true })
    PersonID?: string;

    @Field({ nullable: true })
    RoleID?: string;

    @Field({ nullable: true })
    TermID: string | null;

    @Field({ nullable: true })
    StartDate?: Date;

    @Field({ nullable: true })
    EndDate: Date | null;

    @Field({ nullable: true })
    Status?: string;

    @Field({ nullable: true })
    EndReason: string | null;

    @Field({ nullable: true })
    Notes: string | null;
}
    

//****************************************************************************
// INPUT TYPE for Committees: Memberships
//****************************************************************************
@InputType()
export class UpdatemjCommitteesMembershipInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    CommitteeID?: string;

    @Field({ nullable: true })
    PersonID?: string;

    @Field({ nullable: true })
    RoleID?: string;

    @Field({ nullable: true })
    TermID?: string | null;

    @Field({ nullable: true })
    StartDate?: Date;

    @Field({ nullable: true })
    EndDate?: Date | null;

    @Field({ nullable: true })
    Status?: string;

    @Field({ nullable: true })
    EndReason?: string | null;

    @Field({ nullable: true })
    Notes?: string | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];
}
    
//****************************************************************************
// RESOLVER for Committees: Memberships
//****************************************************************************
@ObjectType()
export class RunmjCommitteesMembershipViewResult {
    @Field(() => [mjCommitteesMembership_])
    Results: mjCommitteesMembership_[];

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

@Resolver(mjCommitteesMembership_)
export class mjCommitteesMembershipResolver extends ResolverBase {
    @Query(() => RunmjCommitteesMembershipViewResult)
    async RunmjCommitteesMembershipViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesMembershipViewResult)
    async RunmjCommitteesMembershipViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesMembershipViewResult)
    async RunmjCommitteesMembershipDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'Committees: Memberships';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjCommitteesMembership_, { nullable: true })
    async mjCommitteesMembership(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjCommitteesMembership_ | null> {
        this.CheckUserReadPermissions('Committees: Memberships', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwMemberships] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Memberships', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Committees: Memberships', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @FieldResolver(() => [mjCommitteesMotion_])
    async Committees_Motions_MovedByMembershipIDArray(@Root() mjcommitteesmembership_: mjCommitteesMembership_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Motions', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwMotions] WHERE [MovedByMembershipID]='${mjcommitteesmembership_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Motions', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Motions', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesVote_])
    async Committees_Votes_MembershipIDArray(@Root() mjcommitteesmembership_: mjCommitteesMembership_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Votes', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwVotes] WHERE [MembershipID]='${mjcommitteesmembership_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Votes', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Votes', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesMotion_])
    async Committees_Motions_SecondedByMembershipIDArray(@Root() mjcommitteesmembership_: mjCommitteesMembership_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Motions', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwMotions] WHERE [SecondedByMembershipID]='${mjcommitteesmembership_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Motions', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Motions', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @Mutation(() => mjCommitteesMembership_)
    async CreatemjCommitteesMembership(
        @Arg('input', () => CreatemjCommitteesMembershipInput) input: CreatemjCommitteesMembershipInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Committees: Memberships', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjCommitteesMembership_)
    async UpdatemjCommitteesMembership(
        @Arg('input', () => UpdatemjCommitteesMembershipInput) input: UpdatemjCommitteesMembershipInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Committees: Memberships', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjCommitteesMembership_)
    async DeletemjCommitteesMembership(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Committees: Memberships', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Committees: Minutes
//****************************************************************************
@ObjectType({ description: `Extension entity for Minutes artifacts with approval tracking` })
export class mjCommitteesMinute_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field() 
    @MaxLength(16)
    ArtifactID: string;
        
    @Field({description: `Current approval status: Draft, PendingApproval, Approved, Rejected`}) 
    @MaxLength(100)
    ApprovalStatus: string;
        
    @Field({nullable: true, description: `Timestamp when the minutes were approved`}) 
    @MaxLength(10)
    ApprovedAt?: Date;
        
    @Field({nullable: true, description: `Reference to the meeting at which these minutes were approved (typically the next meeting)`}) 
    @MaxLength(16)
    ApprovedByMeetingID?: string;
        
    @Field({nullable: true, description: `Additional notes about the minutes`}) 
    Notes?: string;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
}

//****************************************************************************
// INPUT TYPE for Committees: Minutes
//****************************************************************************
@InputType()
export class CreatemjCommitteesMinuteInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    ArtifactID?: string;

    @Field({ nullable: true })
    ApprovalStatus?: string;

    @Field({ nullable: true })
    ApprovedAt: Date | null;

    @Field({ nullable: true })
    ApprovedByMeetingID: string | null;

    @Field({ nullable: true })
    Notes: string | null;
}
    

//****************************************************************************
// INPUT TYPE for Committees: Minutes
//****************************************************************************
@InputType()
export class UpdatemjCommitteesMinuteInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    ArtifactID?: string;

    @Field({ nullable: true })
    ApprovalStatus?: string;

    @Field({ nullable: true })
    ApprovedAt?: Date | null;

    @Field({ nullable: true })
    ApprovedByMeetingID?: string | null;

    @Field({ nullable: true })
    Notes?: string | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];
}
    
//****************************************************************************
// RESOLVER for Committees: Minutes
//****************************************************************************
@ObjectType()
export class RunmjCommitteesMinuteViewResult {
    @Field(() => [mjCommitteesMinute_])
    Results: mjCommitteesMinute_[];

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

@Resolver(mjCommitteesMinute_)
export class mjCommitteesMinuteResolver extends ResolverBase {
    @Query(() => RunmjCommitteesMinuteViewResult)
    async RunmjCommitteesMinuteViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesMinuteViewResult)
    async RunmjCommitteesMinuteViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesMinuteViewResult)
    async RunmjCommitteesMinuteDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'Committees: Minutes';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjCommitteesMinute_, { nullable: true })
    async mjCommitteesMinute(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjCommitteesMinute_ | null> {
        this.CheckUserReadPermissions('Committees: Minutes', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwMinutes] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Minutes', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Committees: Minutes', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjCommitteesMinute_)
    async CreatemjCommitteesMinute(
        @Arg('input', () => CreatemjCommitteesMinuteInput) input: CreatemjCommitteesMinuteInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Committees: Minutes', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjCommitteesMinute_)
    async UpdatemjCommitteesMinute(
        @Arg('input', () => UpdatemjCommitteesMinuteInput) input: UpdatemjCommitteesMinuteInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Committees: Minutes', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjCommitteesMinute_)
    async DeletemjCommitteesMinute(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Committees: Minutes', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Committees: Motions
//****************************************************************************
@ObjectType({ description: `Formal motions put to vote during committee meetings` })
export class mjCommitteesMotion_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field() 
    @MaxLength(16)
    MeetingID: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    AgendaItemID?: string;
        
    @Field(() => Int, {description: `Display order when multiple motions exist for the same agenda item`}) 
    Sequence: number;
        
    @Field({description: `Title of the motion`}) 
    @MaxLength(510)
    Title: string;
        
    @Field({nullable: true, description: `Full text or description of the motion`}) 
    Description?: string;
        
    @Field({nullable: true, description: `The committee member who made the motion`}) 
    @MaxLength(16)
    MovedByMembershipID?: string;
        
    @Field({nullable: true, description: `The committee member who seconded the motion`}) 
    @MaxLength(16)
    SecondedByMembershipID?: string;
        
    @Field({description: `Outcome of the vote: Pending, Passed, Failed, Tabled, Withdrawn`}) 
    @MaxLength(100)
    Result: string;
        
    @Field({nullable: true, description: `Human-readable vote tally, e.g. 7-2-1 or Passed unanimously`}) 
    @MaxLength(510)
    ResultSummary?: string;
        
    @Field(() => Int, {nullable: true, description: `Number of Yes votes`}) 
    YesCount?: number;
        
    @Field(() => Int, {nullable: true, description: `Number of No votes`}) 
    NoCount?: number;
        
    @Field(() => Int, {nullable: true, description: `Number of Abstain votes`}) 
    AbstainCount?: number;
        
    @Field({nullable: true, description: `Additional notes about the motion or vote`}) 
    Notes?: string;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field(() => [mjCommitteesVote_])
    Committees_Votes_MotionIDArray: mjCommitteesVote_[]; // Link to Committees_Votes
    
}

//****************************************************************************
// INPUT TYPE for Committees: Motions
//****************************************************************************
@InputType()
export class CreatemjCommitteesMotionInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    MeetingID?: string;

    @Field({ nullable: true })
    AgendaItemID: string | null;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field({ nullable: true })
    Title?: string;

    @Field({ nullable: true })
    Description: string | null;

    @Field({ nullable: true })
    MovedByMembershipID: string | null;

    @Field({ nullable: true })
    SecondedByMembershipID: string | null;

    @Field({ nullable: true })
    Result?: string;

    @Field({ nullable: true })
    ResultSummary: string | null;

    @Field(() => Int, { nullable: true })
    YesCount: number | null;

    @Field(() => Int, { nullable: true })
    NoCount: number | null;

    @Field(() => Int, { nullable: true })
    AbstainCount: number | null;

    @Field({ nullable: true })
    Notes: string | null;
}
    

//****************************************************************************
// INPUT TYPE for Committees: Motions
//****************************************************************************
@InputType()
export class UpdatemjCommitteesMotionInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    MeetingID?: string;

    @Field({ nullable: true })
    AgendaItemID?: string | null;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field({ nullable: true })
    Title?: string;

    @Field({ nullable: true })
    Description?: string | null;

    @Field({ nullable: true })
    MovedByMembershipID?: string | null;

    @Field({ nullable: true })
    SecondedByMembershipID?: string | null;

    @Field({ nullable: true })
    Result?: string;

    @Field({ nullable: true })
    ResultSummary?: string | null;

    @Field(() => Int, { nullable: true })
    YesCount?: number | null;

    @Field(() => Int, { nullable: true })
    NoCount?: number | null;

    @Field(() => Int, { nullable: true })
    AbstainCount?: number | null;

    @Field({ nullable: true })
    Notes?: string | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];
}
    
//****************************************************************************
// RESOLVER for Committees: Motions
//****************************************************************************
@ObjectType()
export class RunmjCommitteesMotionViewResult {
    @Field(() => [mjCommitteesMotion_])
    Results: mjCommitteesMotion_[];

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

@Resolver(mjCommitteesMotion_)
export class mjCommitteesMotionResolver extends ResolverBase {
    @Query(() => RunmjCommitteesMotionViewResult)
    async RunmjCommitteesMotionViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesMotionViewResult)
    async RunmjCommitteesMotionViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesMotionViewResult)
    async RunmjCommitteesMotionDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'Committees: Motions';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjCommitteesMotion_, { nullable: true })
    async mjCommitteesMotion(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjCommitteesMotion_ | null> {
        this.CheckUserReadPermissions('Committees: Motions', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwMotions] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Motions', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Committees: Motions', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @FieldResolver(() => [mjCommitteesVote_])
    async Committees_Votes_MotionIDArray(@Root() mjcommitteesmotion_: mjCommitteesMotion_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Votes', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwVotes] WHERE [MotionID]='${mjcommitteesmotion_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Votes', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Votes', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @Mutation(() => mjCommitteesMotion_)
    async CreatemjCommitteesMotion(
        @Arg('input', () => CreatemjCommitteesMotionInput) input: CreatemjCommitteesMotionInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Committees: Motions', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjCommitteesMotion_)
    async UpdatemjCommitteesMotion(
        @Arg('input', () => UpdatemjCommitteesMotionInput) input: UpdatemjCommitteesMotionInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Committees: Motions', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjCommitteesMotion_)
    async DeletemjCommitteesMotion(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Committees: Motions', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Committees: Roles
//****************************************************************************
@ObjectType({ description: `Roles that members can hold on committees` })
export class mjCommitteesRole_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field({description: `Display name for the role`}) 
    @MaxLength(200)
    Name: string;
        
    @Field({nullable: true, description: `Detailed description of role responsibilities`}) 
    Description?: string;
        
    @Field(() => Boolean, {description: `Whether this is an officer role like Chair or Secretary`}) 
    IsOfficer: boolean;
        
    @Field(() => Boolean, {description: `Whether members in this role can vote`}) 
    IsVotingRole: boolean;
        
    @Field({nullable: true, description: `JSON object defining default permissions for this role`}) 
    DefaultPermissionsJSON?: string;
        
    @Field(() => Int, {description: `Display order for sorting roles`}) 
    Sequence: number;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field(() => [mjCommitteesMembership_])
    Committees_Memberships_RoleIDArray: mjCommitteesMembership_[]; // Link to Committees_Memberships
    
}

//****************************************************************************
// INPUT TYPE for Committees: Roles
//****************************************************************************
@InputType()
export class CreatemjCommitteesRoleInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description: string | null;

    @Field(() => Boolean, { nullable: true })
    IsOfficer?: boolean;

    @Field(() => Boolean, { nullable: true })
    IsVotingRole?: boolean;

    @Field({ nullable: true })
    DefaultPermissionsJSON: string | null;

    @Field(() => Int, { nullable: true })
    Sequence?: number;
}
    

//****************************************************************************
// INPUT TYPE for Committees: Roles
//****************************************************************************
@InputType()
export class UpdatemjCommitteesRoleInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description?: string | null;

    @Field(() => Boolean, { nullable: true })
    IsOfficer?: boolean;

    @Field(() => Boolean, { nullable: true })
    IsVotingRole?: boolean;

    @Field({ nullable: true })
    DefaultPermissionsJSON?: string | null;

    @Field(() => Int, { nullable: true })
    Sequence?: number;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];
}
    
//****************************************************************************
// RESOLVER for Committees: Roles
//****************************************************************************
@ObjectType()
export class RunmjCommitteesRoleViewResult {
    @Field(() => [mjCommitteesRole_])
    Results: mjCommitteesRole_[];

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

@Resolver(mjCommitteesRole_)
export class mjCommitteesRoleResolver extends ResolverBase {
    @Query(() => RunmjCommitteesRoleViewResult)
    async RunmjCommitteesRoleViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesRoleViewResult)
    async RunmjCommitteesRoleViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesRoleViewResult)
    async RunmjCommitteesRoleDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'Committees: Roles';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjCommitteesRole_, { nullable: true })
    async mjCommitteesRole(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjCommitteesRole_ | null> {
        this.CheckUserReadPermissions('Committees: Roles', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwRoles] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Roles', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Committees: Roles', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @FieldResolver(() => [mjCommitteesMembership_])
    async Committees_Memberships_RoleIDArray(@Root() mjcommitteesrole_: mjCommitteesRole_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Memberships', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwMemberships] WHERE [RoleID]='${mjcommitteesrole_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Memberships', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Memberships', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @Mutation(() => mjCommitteesRole_)
    async CreatemjCommitteesRole(
        @Arg('input', () => CreatemjCommitteesRoleInput) input: CreatemjCommitteesRoleInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Committees: Roles', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjCommitteesRole_)
    async UpdatemjCommitteesRole(
        @Arg('input', () => UpdatemjCommitteesRoleInput) input: UpdatemjCommitteesRoleInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Committees: Roles', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjCommitteesRole_)
    async DeletemjCommitteesRole(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Committees: Roles', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Committees: Terms
//****************************************************************************
@ObjectType({ description: `Time periods for committee membership cycles` })
export class mjCommitteesTerm_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field() 
    @MaxLength(16)
    CommitteeID: string;
        
    @Field({description: `Display name for the term, e.g. 2025-2026`}) 
    @MaxLength(200)
    Name: string;
        
    @Field({description: `Start date of the term`}) 
    @MaxLength(3)
    StartDate: Date;
        
    @Field({nullable: true, description: `End date of the term`}) 
    @MaxLength(3)
    EndDate?: Date;
        
    @Field({description: `Current status: Active, Upcoming, or Completed`}) 
    @MaxLength(100)
    Status: string;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field() 
    @MaxLength(510)
    Committee: string;
        
    @Field(() => [mjCommitteesMembership_])
    Committees_Memberships_TermIDArray: mjCommitteesMembership_[]; // Link to Committees_Memberships
    
}

//****************************************************************************
// INPUT TYPE for Committees: Terms
//****************************************************************************
@InputType()
export class CreatemjCommitteesTermInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    CommitteeID?: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    StartDate?: Date;

    @Field({ nullable: true })
    EndDate: Date | null;

    @Field({ nullable: true })
    Status?: string;
}
    

//****************************************************************************
// INPUT TYPE for Committees: Terms
//****************************************************************************
@InputType()
export class UpdatemjCommitteesTermInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    CommitteeID?: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    StartDate?: Date;

    @Field({ nullable: true })
    EndDate?: Date | null;

    @Field({ nullable: true })
    Status?: string;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];
}
    
//****************************************************************************
// RESOLVER for Committees: Terms
//****************************************************************************
@ObjectType()
export class RunmjCommitteesTermViewResult {
    @Field(() => [mjCommitteesTerm_])
    Results: mjCommitteesTerm_[];

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

@Resolver(mjCommitteesTerm_)
export class mjCommitteesTermResolver extends ResolverBase {
    @Query(() => RunmjCommitteesTermViewResult)
    async RunmjCommitteesTermViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesTermViewResult)
    async RunmjCommitteesTermViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesTermViewResult)
    async RunmjCommitteesTermDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'Committees: Terms';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjCommitteesTerm_, { nullable: true })
    async mjCommitteesTerm(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjCommitteesTerm_ | null> {
        this.CheckUserReadPermissions('Committees: Terms', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwTerms] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Terms', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Committees: Terms', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @FieldResolver(() => [mjCommitteesMembership_])
    async Committees_Memberships_TermIDArray(@Root() mjcommitteesterm_: mjCommitteesTerm_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Memberships', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwMemberships] WHERE [TermID]='${mjcommitteesterm_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Memberships', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Memberships', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @Mutation(() => mjCommitteesTerm_)
    async CreatemjCommitteesTerm(
        @Arg('input', () => CreatemjCommitteesTermInput) input: CreatemjCommitteesTermInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Committees: Terms', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjCommitteesTerm_)
    async UpdatemjCommitteesTerm(
        @Arg('input', () => UpdatemjCommitteesTermInput) input: UpdatemjCommitteesTermInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Committees: Terms', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjCommitteesTerm_)
    async DeletemjCommitteesTerm(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Committees: Terms', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Committees: Types
//****************************************************************************
@ObjectType({ description: `Categories of committees such as Board, Standing, Ad Hoc, Workgroup` })
export class mjCommitteesType_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field({description: `Display name for the committee type`}) 
    @MaxLength(200)
    Name: string;
        
    @Field({nullable: true, description: `Detailed description of this committee type`}) 
    Description?: string;
        
    @Field(() => Boolean, {description: `Whether this type is for standards development committees`}) 
    IsStandards: boolean;
        
    @Field(() => Int, {nullable: true, description: `Default term length in months for committees of this type`}) 
    DefaultTermMonths?: number;
        
    @Field({nullable: true, description: `Font Awesome icon class for UI display`}) 
    @MaxLength(200)
    IconClass?: string;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field(() => [mjCommitteesCommittee_])
    Committees_Committees_TypeIDArray: mjCommitteesCommittee_[]; // Link to Committees_Committees
    
}

//****************************************************************************
// INPUT TYPE for Committees: Types
//****************************************************************************
@InputType()
export class CreatemjCommitteesTypeInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description: string | null;

    @Field(() => Boolean, { nullable: true })
    IsStandards?: boolean;

    @Field(() => Int, { nullable: true })
    DefaultTermMonths: number | null;

    @Field({ nullable: true })
    IconClass: string | null;
}
    

//****************************************************************************
// INPUT TYPE for Committees: Types
//****************************************************************************
@InputType()
export class UpdatemjCommitteesTypeInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description?: string | null;

    @Field(() => Boolean, { nullable: true })
    IsStandards?: boolean;

    @Field(() => Int, { nullable: true })
    DefaultTermMonths?: number | null;

    @Field({ nullable: true })
    IconClass?: string | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];
}
    
//****************************************************************************
// RESOLVER for Committees: Types
//****************************************************************************
@ObjectType()
export class RunmjCommitteesTypeViewResult {
    @Field(() => [mjCommitteesType_])
    Results: mjCommitteesType_[];

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

@Resolver(mjCommitteesType_)
export class mjCommitteesTypeResolver extends ResolverBase {
    @Query(() => RunmjCommitteesTypeViewResult)
    async RunmjCommitteesTypeViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesTypeViewResult)
    async RunmjCommitteesTypeViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesTypeViewResult)
    async RunmjCommitteesTypeDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'Committees: Types';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjCommitteesType_, { nullable: true })
    async mjCommitteesType(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjCommitteesType_ | null> {
        this.CheckUserReadPermissions('Committees: Types', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwTypes] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Types', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Committees: Types', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @FieldResolver(() => [mjCommitteesCommittee_])
    async Committees_Committees_TypeIDArray(@Root() mjcommitteestype_: mjCommitteesType_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Committees', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwCommittees] WHERE [TypeID]='${mjcommitteestype_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Committees', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Committees', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @Mutation(() => mjCommitteesType_)
    async CreatemjCommitteesType(
        @Arg('input', () => CreatemjCommitteesTypeInput) input: CreatemjCommitteesTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Committees: Types', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjCommitteesType_)
    async UpdatemjCommitteesType(
        @Arg('input', () => UpdatemjCommitteesTypeInput) input: UpdatemjCommitteesTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Committees: Types', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjCommitteesType_)
    async DeletemjCommitteesType(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Committees: Types', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Committees: Votes
//****************************************************************************
@ObjectType({ description: `Individual vote records for committee motions` })
export class mjCommitteesVote_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field() 
    @MaxLength(16)
    MotionID: string;
        
    @Field() 
    @MaxLength(16)
    MembershipID: string;
        
    @Field({description: `The vote cast: Yes, No, Abstain, or Absent`}) 
    @MaxLength(40)
    VoteValue: string;
        
    @Field({nullable: true, description: `Optional notes explaining the vote`}) 
    @MaxLength(1000)
    Notes?: string;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
}

//****************************************************************************
// INPUT TYPE for Committees: Votes
//****************************************************************************
@InputType()
export class CreatemjCommitteesVoteInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    MotionID?: string;

    @Field({ nullable: true })
    MembershipID?: string;

    @Field({ nullable: true })
    VoteValue?: string;

    @Field({ nullable: true })
    Notes: string | null;
}
    

//****************************************************************************
// INPUT TYPE for Committees: Votes
//****************************************************************************
@InputType()
export class UpdatemjCommitteesVoteInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    MotionID?: string;

    @Field({ nullable: true })
    MembershipID?: string;

    @Field({ nullable: true })
    VoteValue?: string;

    @Field({ nullable: true })
    Notes?: string | null;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];
}
    
//****************************************************************************
// RESOLVER for Committees: Votes
//****************************************************************************
@ObjectType()
export class RunmjCommitteesVoteViewResult {
    @Field(() => [mjCommitteesVote_])
    Results: mjCommitteesVote_[];

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

@Resolver(mjCommitteesVote_)
export class mjCommitteesVoteResolver extends ResolverBase {
    @Query(() => RunmjCommitteesVoteViewResult)
    async RunmjCommitteesVoteViewByID(@Arg('input', () => RunViewByIDInput) input: RunViewByIDInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByIDGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesVoteViewResult)
    async RunmjCommitteesVoteViewByName(@Arg('input', () => RunViewByNameInput) input: RunViewByNameInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        return super.RunViewByNameGeneric(input, provider, userPayload, pubSub);
    }

    @Query(() => RunmjCommitteesVoteViewResult)
    async RunmjCommitteesVoteDynamicView(@Arg('input', () => RunDynamicViewInput) input: RunDynamicViewInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        input.EntityName = 'Committees: Votes';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjCommitteesVote_, { nullable: true })
    async mjCommitteesVote(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjCommitteesVote_ | null> {
        this.CheckUserReadPermissions('Committees: Votes', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwVotes] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Votes', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Committees: Votes', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjCommitteesVote_)
    async CreatemjCommitteesVote(
        @Arg('input', () => CreatemjCommitteesVoteInput) input: CreatemjCommitteesVoteInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Committees: Votes', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjCommitteesVote_)
    async UpdatemjCommitteesVote(
        @Arg('input', () => UpdatemjCommitteesVoteInput) input: UpdatemjCommitteesVoteInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Committees: Votes', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjCommitteesVote_)
    async DeletemjCommitteesVote(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Committees: Votes', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Common: Address Links
//****************************************************************************
@ObjectType({ description: `Polymorphic link table connecting Address records to any entity record in the system via EntityID and RecordID` })
export class mjBizAppsCommonAddressLink_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field() 
    @MaxLength(16)
    AddressID: string;
        
    @Field() 
    @MaxLength(16)
    EntityID: string;
        
    @Field({description: `Primary key value(s) of the linked record. NVARCHAR(700) to support concatenated composite keys for entities without single-valued primary keys`}) 
    @MaxLength(1400)
    RecordID: string;
        
    @Field() 
    @MaxLength(16)
    AddressTypeID: string;
        
    @Field(() => Boolean, {description: `Whether this is the primary address for the linked record. Only one address per entity record should be marked primary`}) 
    IsPrimary: boolean;
        
    @Field(() => Int, {nullable: true, description: `Sort order override for this specific link. When NULL, falls back to AddressType.DefaultRank. Lower values appear first`}) 
    Rank?: number;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field() 
    @MaxLength(510)
    Entity: string;
        
    @Field() 
    @MaxLength(200)
    AddressType: string;
        
}

//****************************************************************************
// INPUT TYPE for Common: Address Links
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
}
    

//****************************************************************************
// INPUT TYPE for Common: Address Links
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
}
    
//****************************************************************************
// RESOLVER for Common: Address Links
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
        input.EntityName = 'Common: Address Links';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonAddressLink_, { nullable: true })
    async mjBizAppsCommonAddressLink(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonAddressLink_ | null> {
        this.CheckUserReadPermissions('Common: Address Links', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwAddressLinks] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Address Links', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Common: Address Links', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonAddressLink_)
    async CreatemjBizAppsCommonAddressLink(
        @Arg('input', () => CreatemjBizAppsCommonAddressLinkInput) input: CreatemjBizAppsCommonAddressLinkInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Common: Address Links', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonAddressLink_)
    async UpdatemjBizAppsCommonAddressLink(
        @Arg('input', () => UpdatemjBizAppsCommonAddressLinkInput) input: UpdatemjBizAppsCommonAddressLinkInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Common: Address Links', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonAddressLink_)
    async DeletemjBizAppsCommonAddressLink(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Common: Address Links', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Common: Address Types
//****************************************************************************
@ObjectType({ description: `Categories of addresses such as Home, Work, Mailing, Billing` })
export class mjBizAppsCommonAddressType_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field({description: `Display name for the address type`}) 
    @MaxLength(200)
    Name: string;
        
    @Field({nullable: true, description: `Detailed description of this address type`}) 
    Description?: string;
        
    @Field(() => Int, {description: `Default sort order for this address type in dropdown lists. Lower values appear first. Can be overridden per-record via AddressLink.Rank`}) 
    DefaultRank: number;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field(() => [mjBizAppsCommonAddressLink_])
    Common_AddressLinks_AddressTypeIDArray: mjBizAppsCommonAddressLink_[]; // Link to Common_AddressLinks
    
}

//****************************************************************************
// INPUT TYPE for Common: Address Types
//****************************************************************************
@InputType()
export class CreatemjBizAppsCommonAddressTypeInput {
    @Field({ nullable: true })
    ID?: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description: string | null;

    @Field(() => Int, { nullable: true })
    DefaultRank?: number;
}
    

//****************************************************************************
// INPUT TYPE for Common: Address Types
//****************************************************************************
@InputType()
export class UpdatemjBizAppsCommonAddressTypeInput {
    @Field()
    ID: string;

    @Field({ nullable: true })
    Name?: string;

    @Field({ nullable: true })
    Description?: string | null;

    @Field(() => Int, { nullable: true })
    DefaultRank?: number;

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];
}
    
//****************************************************************************
// RESOLVER for Common: Address Types
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
        input.EntityName = 'Common: Address Types';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonAddressType_, { nullable: true })
    async mjBizAppsCommonAddressType(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonAddressType_ | null> {
        this.CheckUserReadPermissions('Common: Address Types', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwAddressTypes] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Address Types', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Common: Address Types', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @FieldResolver(() => [mjBizAppsCommonAddressLink_])
    async Common_AddressLinks_AddressTypeIDArray(@Root() mjbizappscommonaddresstype_: mjBizAppsCommonAddressType_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Common: Address Links', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwAddressLinks] WHERE [AddressTypeID]='${mjbizappscommonaddresstype_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Address Links', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Common: Address Links', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @Mutation(() => mjBizAppsCommonAddressType_)
    async CreatemjBizAppsCommonAddressType(
        @Arg('input', () => CreatemjBizAppsCommonAddressTypeInput) input: CreatemjBizAppsCommonAddressTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Common: Address Types', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonAddressType_)
    async UpdatemjBizAppsCommonAddressType(
        @Arg('input', () => UpdatemjBizAppsCommonAddressTypeInput) input: UpdatemjBizAppsCommonAddressTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Common: Address Types', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonAddressType_)
    async DeletemjBizAppsCommonAddressType(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Common: Address Types', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Common: Addresses
//****************************************************************************
@ObjectType({ description: `Standalone physical address records linked to entities via AddressLink for sharing across people and organizations` })
export class mjBizAppsCommonAddress_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field({description: `Street address line 1`}) 
    @MaxLength(510)
    Line1: string;
        
    @Field({nullable: true, description: `Street address line 2 (suite, apt, etc.)`}) 
    @MaxLength(510)
    Line2?: string;
        
    @Field({nullable: true, description: `Street address line 3 (additional detail)`}) 
    @MaxLength(510)
    Line3?: string;
        
    @Field({description: `City or locality name`}) 
    @MaxLength(200)
    City: string;
        
    @Field({nullable: true, description: `State, province, or region`}) 
    @MaxLength(200)
    StateProvince?: string;
        
    @Field({nullable: true, description: `Postal or ZIP code`}) 
    @MaxLength(40)
    PostalCode?: string;
        
    @Field({description: `Country code or name, defaults to US`}) 
    @MaxLength(200)
    Country: string;
        
    @Field(() => Float, {nullable: true, description: `Geographic latitude for mapping`}) 
    Latitude?: number;
        
    @Field(() => Float, {nullable: true, description: `Geographic longitude for mapping`}) 
    Longitude?: number;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field(() => [mjBizAppsCommonAddressLink_])
    Common_AddressLinks_AddressIDArray: mjBizAppsCommonAddressLink_[]; // Link to Common_AddressLinks
    
}

//****************************************************************************
// INPUT TYPE for Common: Addresses
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
}
    

//****************************************************************************
// INPUT TYPE for Common: Addresses
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
}
    
//****************************************************************************
// RESOLVER for Common: Addresses
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
        input.EntityName = 'Common: Addresses';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonAddress_, { nullable: true })
    async mjBizAppsCommonAddress(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonAddress_ | null> {
        this.CheckUserReadPermissions('Common: Addresses', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwAddresses] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Addresses', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Common: Addresses', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @FieldResolver(() => [mjBizAppsCommonAddressLink_])
    async Common_AddressLinks_AddressIDArray(@Root() mjbizappscommonaddress_: mjBizAppsCommonAddress_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Common: Address Links', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwAddressLinks] WHERE [AddressID]='${mjbizappscommonaddress_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Address Links', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Common: Address Links', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @Mutation(() => mjBizAppsCommonAddress_)
    async CreatemjBizAppsCommonAddress(
        @Arg('input', () => CreatemjBizAppsCommonAddressInput) input: CreatemjBizAppsCommonAddressInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Common: Addresses', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonAddress_)
    async UpdatemjBizAppsCommonAddress(
        @Arg('input', () => UpdatemjBizAppsCommonAddressInput) input: UpdatemjBizAppsCommonAddressInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Common: Addresses', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonAddress_)
    async DeletemjBizAppsCommonAddress(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Common: Addresses', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Common: Contact Methods
//****************************************************************************
@ObjectType({ description: `Additional contact methods for people and organizations beyond the primary email and phone fields` })
export class mjBizAppsCommonContactMethod_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    PersonID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    OrganizationID?: string;
        
    @Field() 
    @MaxLength(16)
    ContactTypeID: string;
        
    @Field({description: `The contact value: phone number, email address, URL, social media handle, etc.`}) 
    @MaxLength(1000)
    Value: string;
        
    @Field({nullable: true, description: `Descriptive label such as Work cell, Personal Gmail, Corporate LinkedIn`}) 
    @MaxLength(200)
    Label?: string;
        
    @Field(() => Boolean, {description: `Whether this is the primary contact method of its type for the linked person or organization`}) 
    IsPrimary: boolean;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field({nullable: true}) 
    @MaxLength(510)
    Organization?: string;
        
    @Field() 
    @MaxLength(200)
    ContactType: string;
        
}

//****************************************************************************
// INPUT TYPE for Common: Contact Methods
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
}
    

//****************************************************************************
// INPUT TYPE for Common: Contact Methods
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
}
    
//****************************************************************************
// RESOLVER for Common: Contact Methods
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
        input.EntityName = 'Common: Contact Methods';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonContactMethod_, { nullable: true })
    async mjBizAppsCommonContactMethod(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonContactMethod_ | null> {
        this.CheckUserReadPermissions('Common: Contact Methods', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwContactMethods] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Contact Methods', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Common: Contact Methods', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonContactMethod_)
    async CreatemjBizAppsCommonContactMethod(
        @Arg('input', () => CreatemjBizAppsCommonContactMethodInput) input: CreatemjBizAppsCommonContactMethodInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Common: Contact Methods', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonContactMethod_)
    async UpdatemjBizAppsCommonContactMethod(
        @Arg('input', () => UpdatemjBizAppsCommonContactMethodInput) input: UpdatemjBizAppsCommonContactMethodInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Common: Contact Methods', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonContactMethod_)
    async DeletemjBizAppsCommonContactMethod(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Common: Contact Methods', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Common: Contact Types
//****************************************************************************
@ObjectType({ description: `Categories of contact methods such as Phone, Mobile, Email, LinkedIn, Website` })
export class mjBizAppsCommonContactType_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field({description: `Display name for the contact type`}) 
    @MaxLength(200)
    Name: string;
        
    @Field({nullable: true, description: `Detailed description of this contact type`}) 
    Description?: string;
        
    @Field({nullable: true, description: `Font Awesome icon class for UI display`}) 
    @MaxLength(200)
    IconClass?: string;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field(() => [mjBizAppsCommonContactMethod_])
    Common_ContactMethods_ContactTypeIDArray: mjBizAppsCommonContactMethod_[]; // Link to Common_ContactMethods
    
}

//****************************************************************************
// INPUT TYPE for Common: Contact Types
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
}
    

//****************************************************************************
// INPUT TYPE for Common: Contact Types
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

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];
}
    
//****************************************************************************
// RESOLVER for Common: Contact Types
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
        input.EntityName = 'Common: Contact Types';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonContactType_, { nullable: true })
    async mjBizAppsCommonContactType(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonContactType_ | null> {
        this.CheckUserReadPermissions('Common: Contact Types', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwContactTypes] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Contact Types', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Common: Contact Types', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @FieldResolver(() => [mjBizAppsCommonContactMethod_])
    async Common_ContactMethods_ContactTypeIDArray(@Root() mjbizappscommoncontacttype_: mjBizAppsCommonContactType_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Common: Contact Methods', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwContactMethods] WHERE [ContactTypeID]='${mjbizappscommoncontacttype_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Contact Methods', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Common: Contact Methods', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @Mutation(() => mjBizAppsCommonContactType_)
    async CreatemjBizAppsCommonContactType(
        @Arg('input', () => CreatemjBizAppsCommonContactTypeInput) input: CreatemjBizAppsCommonContactTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Common: Contact Types', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonContactType_)
    async UpdatemjBizAppsCommonContactType(
        @Arg('input', () => UpdatemjBizAppsCommonContactTypeInput) input: UpdatemjBizAppsCommonContactTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Common: Contact Types', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonContactType_)
    async DeletemjBizAppsCommonContactType(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Common: Contact Types', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Common: Organization Types
//****************************************************************************
@ObjectType({ description: `Categories of organizations such as Company, Non-Profit, Association, Government` })
export class mjBizAppsCommonOrganizationType_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field({description: `Display name for the organization type`}) 
    @MaxLength(200)
    Name: string;
        
    @Field({nullable: true, description: `Detailed description of this organization type`}) 
    Description?: string;
        
    @Field({nullable: true, description: `Font Awesome icon class for UI display`}) 
    @MaxLength(200)
    IconClass?: string;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field(() => [mjBizAppsCommonOrganization_])
    Common_Organizations_OrganizationTypeIDArray: mjBizAppsCommonOrganization_[]; // Link to Common_Organizations
    
}

//****************************************************************************
// INPUT TYPE for Common: Organization Types
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
}
    

//****************************************************************************
// INPUT TYPE for Common: Organization Types
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

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];
}
    
//****************************************************************************
// RESOLVER for Common: Organization Types
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
        input.EntityName = 'Common: Organization Types';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonOrganizationType_, { nullable: true })
    async mjBizAppsCommonOrganizationType(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonOrganizationType_ | null> {
        this.CheckUserReadPermissions('Common: Organization Types', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwOrganizationTypes] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Organization Types', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Common: Organization Types', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @FieldResolver(() => [mjBizAppsCommonOrganization_])
    async Common_Organizations_OrganizationTypeIDArray(@Root() mjbizappscommonorganizationtype_: mjBizAppsCommonOrganizationType_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Common: Organizations', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwOrganizations] WHERE [OrganizationTypeID]='${mjbizappscommonorganizationtype_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Organizations', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Common: Organizations', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @Mutation(() => mjBizAppsCommonOrganizationType_)
    async CreatemjBizAppsCommonOrganizationType(
        @Arg('input', () => CreatemjBizAppsCommonOrganizationTypeInput) input: CreatemjBizAppsCommonOrganizationTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Common: Organization Types', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonOrganizationType_)
    async UpdatemjBizAppsCommonOrganizationType(
        @Arg('input', () => UpdatemjBizAppsCommonOrganizationTypeInput) input: UpdatemjBizAppsCommonOrganizationTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Common: Organization Types', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonOrganizationType_)
    async DeletemjBizAppsCommonOrganizationType(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Common: Organization Types', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Common: Organizations
//****************************************************************************
@ObjectType({ description: `Companies, associations, government bodies, and other organizations with hierarchy support` })
export class mjBizAppsCommonOrganization_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field({description: `Common or display name of the organization`}) 
    @MaxLength(510)
    Name: string;
        
    @Field({nullable: true, description: `Full legal name if different from display name`}) 
    @MaxLength(510)
    LegalName?: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    OrganizationTypeID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    ParentID?: string;
        
    @Field({nullable: true, description: `Primary website URL`}) 
    @MaxLength(2000)
    Website?: string;
        
    @Field({nullable: true, description: `URL to organization logo image`}) 
    @MaxLength(2000)
    LogoURL?: string;
        
    @Field({nullable: true, description: `Description of the organization purpose and scope`}) 
    Description?: string;
        
    @Field({nullable: true, description: `Primary contact email address`}) 
    @MaxLength(510)
    Email?: string;
        
    @Field({nullable: true, description: `Primary phone number`}) 
    @MaxLength(100)
    Phone?: string;
        
    @Field({nullable: true, description: `Date the organization was founded or incorporated`}) 
    @MaxLength(3)
    FoundedDate?: Date;
        
    @Field({nullable: true, description: `Tax identification number such as EIN`}) 
    @MaxLength(100)
    TaxID?: string;
        
    @Field({description: `Current status: Active, Inactive, or Dissolved`}) 
    @MaxLength(100)
    Status: string;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field({nullable: true}) 
    @MaxLength(200)
    OrganizationType?: string;
        
    @Field({nullable: true}) 
    @MaxLength(510)
    Parent?: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    RootParentID?: string;
        
    @Field(() => [mjBizAppsCommonOrganization_])
    Common_Organizations_ParentIDArray: mjBizAppsCommonOrganization_[]; // Link to Common_Organizations
    
    @Field(() => [mjBizAppsCommonContactMethod_])
    Common_ContactMethods_OrganizationIDArray: mjBizAppsCommonContactMethod_[]; // Link to Common_ContactMethods
    
    @Field(() => [mjCommitteesCommittee_])
    Committees_Committees_OrganizationIDArray: mjCommitteesCommittee_[]; // Link to Committees_Committees
    
    @Field(() => [mjBizAppsCommonRelationship_])
    Common_Relationships_ToOrganizationIDArray: mjBizAppsCommonRelationship_[]; // Link to Common_Relationships
    
    @Field(() => [mjBizAppsCommonRelationship_])
    Common_Relationships_FromOrganizationIDArray: mjBizAppsCommonRelationship_[]; // Link to Common_Relationships
    
}

//****************************************************************************
// INPUT TYPE for Common: Organizations
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
}
    

//****************************************************************************
// INPUT TYPE for Common: Organizations
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
}
    
//****************************************************************************
// RESOLVER for Common: Organizations
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
        input.EntityName = 'Common: Organizations';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonOrganization_, { nullable: true })
    async mjBizAppsCommonOrganization(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonOrganization_ | null> {
        this.CheckUserReadPermissions('Common: Organizations', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwOrganizations] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Organizations', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Common: Organizations', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @FieldResolver(() => [mjBizAppsCommonOrganization_])
    async Common_Organizations_ParentIDArray(@Root() mjbizappscommonorganization_: mjBizAppsCommonOrganization_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Common: Organizations', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwOrganizations] WHERE [ParentID]='${mjbizappscommonorganization_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Organizations', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Common: Organizations', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjBizAppsCommonContactMethod_])
    async Common_ContactMethods_OrganizationIDArray(@Root() mjbizappscommonorganization_: mjBizAppsCommonOrganization_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Common: Contact Methods', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwContactMethods] WHERE [OrganizationID]='${mjbizappscommonorganization_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Contact Methods', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Common: Contact Methods', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesCommittee_])
    async Committees_Committees_OrganizationIDArray(@Root() mjbizappscommonorganization_: mjBizAppsCommonOrganization_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Committees', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwCommittees] WHERE [OrganizationID]='${mjbizappscommonorganization_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Committees', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Committees', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjBizAppsCommonRelationship_])
    async Common_Relationships_ToOrganizationIDArray(@Root() mjbizappscommonorganization_: mjBizAppsCommonOrganization_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Common: Relationships', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwRelationships] WHERE [ToOrganizationID]='${mjbizappscommonorganization_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Relationships', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Common: Relationships', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjBizAppsCommonRelationship_])
    async Common_Relationships_FromOrganizationIDArray(@Root() mjbizappscommonorganization_: mjBizAppsCommonOrganization_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Common: Relationships', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwRelationships] WHERE [FromOrganizationID]='${mjbizappscommonorganization_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Relationships', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Common: Relationships', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @Mutation(() => mjBizAppsCommonOrganization_)
    async CreatemjBizAppsCommonOrganization(
        @Arg('input', () => CreatemjBizAppsCommonOrganizationInput) input: CreatemjBizAppsCommonOrganizationInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Common: Organizations', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonOrganization_)
    async UpdatemjBizAppsCommonOrganization(
        @Arg('input', () => UpdatemjBizAppsCommonOrganizationInput) input: UpdatemjBizAppsCommonOrganizationInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Common: Organizations', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonOrganization_)
    async DeletemjBizAppsCommonOrganization(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Common: Organizations', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Common: People
//****************************************************************************
@ObjectType({ description: `Individual people, optionally linked to MJ system user accounts` })
export class mjBizAppsCommonPerson_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field({description: `First (given) name`}) 
    @MaxLength(200)
    FirstName: string;
        
    @Field({description: `Last (family) name`}) 
    @MaxLength(200)
    LastName: string;
        
    @Field({nullable: true, description: `Middle name or initial`}) 
    @MaxLength(200)
    MiddleName?: string;
        
    @Field({nullable: true, description: `Name prefix such as Dr., Mr., Ms., Rev.`}) 
    @MaxLength(40)
    Prefix?: string;
        
    @Field({nullable: true, description: `Name suffix such as Jr., III, PhD, Esq.`}) 
    @MaxLength(40)
    Suffix?: string;
        
    @Field({nullable: true, description: `Nickname or preferred name the person goes by`}) 
    @MaxLength(200)
    PreferredName?: string;
        
    @Field({nullable: true, description: `Professional or job title, e.g. VP of Engineering, Board Director`}) 
    @MaxLength(400)
    Title?: string;
        
    @Field({nullable: true, description: `Primary email address for this person`}) 
    @MaxLength(510)
    Email?: string;
        
    @Field({nullable: true, description: `Primary phone number for this person`}) 
    @MaxLength(100)
    Phone?: string;
        
    @Field({nullable: true, description: `Date of birth`}) 
    @MaxLength(3)
    DateOfBirth?: Date;
        
    @Field({nullable: true, description: `Gender identity`}) 
    @MaxLength(100)
    Gender?: string;
        
    @Field({nullable: true, description: `URL to profile photo or avatar image`}) 
    @MaxLength(2000)
    PhotoURL?: string;
        
    @Field({nullable: true, description: `Biographical text or notes about this person`}) 
    Bio?: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    LinkedUserID?: string;
        
    @Field({description: `Current status: Active, Inactive, or Deceased`}) 
    @MaxLength(100)
    Status: string;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field({nullable: true}) 
    @MaxLength(200)
    LinkedUser?: string;
        
    @Field(() => [mjBizAppsCommonRelationship_])
    Common_Relationships_FromPersonIDArray: mjBizAppsCommonRelationship_[]; // Link to Common_Relationships
    
    @Field(() => [mjCommitteesAttendance_])
    Committees_Attendances_PersonIDArray: mjCommitteesAttendance_[]; // Link to Committees_Attendances
    
    @Field(() => [mjBizAppsCommonContactMethod_])
    Common_ContactMethods_PersonIDArray: mjBizAppsCommonContactMethod_[]; // Link to Common_ContactMethods
    
    @Field(() => [mjCommitteesAgendaItem_])
    Committees_AgendaItems_PresenterPersonIDArray: mjCommitteesAgendaItem_[]; // Link to Committees_AgendaItems
    
    @Field(() => [mjCommitteesActionItem_])
    Committees_ActionItems_AssignedByPersonIDArray: mjCommitteesActionItem_[]; // Link to Committees_ActionItems
    
    @Field(() => [mjBizAppsCommonRelationship_])
    Common_Relationships_ToPersonIDArray: mjBizAppsCommonRelationship_[]; // Link to Common_Relationships
    
    @Field(() => [mjCommitteesMembership_])
    Committees_Memberships_PersonIDArray: mjCommitteesMembership_[]; // Link to Committees_Memberships
    
    @Field(() => [mjCommitteesArtifact_])
    Committees_Artifacts_UploadedByPersonIDArray: mjCommitteesArtifact_[]; // Link to Committees_Artifacts
    
    @Field(() => [mjCommitteesActionItem_])
    Committees_ActionItems_AssignedToPersonIDArray: mjCommitteesActionItem_[]; // Link to Committees_ActionItems
    
}

//****************************************************************************
// INPUT TYPE for Common: People
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
}
    

//****************************************************************************
// INPUT TYPE for Common: People
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
}
    
//****************************************************************************
// RESOLVER for Common: People
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
        input.EntityName = 'Common: People';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonPerson_, { nullable: true })
    async mjBizAppsCommonPerson(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonPerson_ | null> {
        this.CheckUserReadPermissions('Common: People', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwPeople] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: People', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Common: People', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @FieldResolver(() => [mjBizAppsCommonRelationship_])
    async Common_Relationships_FromPersonIDArray(@Root() mjbizappscommonperson_: mjBizAppsCommonPerson_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Common: Relationships', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwRelationships] WHERE [FromPersonID]='${mjbizappscommonperson_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Relationships', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Common: Relationships', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesAttendance_])
    async Committees_Attendances_PersonIDArray(@Root() mjbizappscommonperson_: mjBizAppsCommonPerson_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Attendances', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwAttendances] WHERE [PersonID]='${mjbizappscommonperson_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Attendances', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Attendances', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjBizAppsCommonContactMethod_])
    async Common_ContactMethods_PersonIDArray(@Root() mjbizappscommonperson_: mjBizAppsCommonPerson_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Common: Contact Methods', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwContactMethods] WHERE [PersonID]='${mjbizappscommonperson_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Contact Methods', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Common: Contact Methods', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesAgendaItem_])
    async Committees_AgendaItems_PresenterPersonIDArray(@Root() mjbizappscommonperson_: mjBizAppsCommonPerson_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Agenda Items', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwAgendaItems] WHERE [PresenterPersonID]='${mjbizappscommonperson_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Agenda Items', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Agenda Items', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesActionItem_])
    async Committees_ActionItems_AssignedByPersonIDArray(@Root() mjbizappscommonperson_: mjBizAppsCommonPerson_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Action Items', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwActionItems] WHERE [AssignedByPersonID]='${mjbizappscommonperson_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Action Items', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Action Items', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjBizAppsCommonRelationship_])
    async Common_Relationships_ToPersonIDArray(@Root() mjbizappscommonperson_: mjBizAppsCommonPerson_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Common: Relationships', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwRelationships] WHERE [ToPersonID]='${mjbizappscommonperson_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Relationships', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Common: Relationships', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesMembership_])
    async Committees_Memberships_PersonIDArray(@Root() mjbizappscommonperson_: mjBizAppsCommonPerson_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Memberships', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwMemberships] WHERE [PersonID]='${mjbizappscommonperson_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Memberships', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Memberships', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesArtifact_])
    async Committees_Artifacts_UploadedByPersonIDArray(@Root() mjbizappscommonperson_: mjBizAppsCommonPerson_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Artifacts', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwArtifacts] WHERE [UploadedByPersonID]='${mjbizappscommonperson_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Artifacts', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Artifacts', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @FieldResolver(() => [mjCommitteesActionItem_])
    async Committees_ActionItems_AssignedToPersonIDArray(@Root() mjbizappscommonperson_: mjBizAppsCommonPerson_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Committees: Action Items', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_Committees].[vwActionItems] WHERE [AssignedToPersonID]='${mjbizappscommonperson_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Committees: Action Items', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Committees: Action Items', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @Mutation(() => mjBizAppsCommonPerson_)
    async CreatemjBizAppsCommonPerson(
        @Arg('input', () => CreatemjBizAppsCommonPersonInput) input: CreatemjBizAppsCommonPersonInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Common: People', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonPerson_)
    async UpdatemjBizAppsCommonPerson(
        @Arg('input', () => UpdatemjBizAppsCommonPersonInput) input: UpdatemjBizAppsCommonPersonInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Common: People', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonPerson_)
    async DeletemjBizAppsCommonPerson(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Common: People', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Common: Relationship Types
//****************************************************************************
@ObjectType({ description: `Defines types of relationships between people and organizations with directionality and labeling` })
export class mjBizAppsCommonRelationshipType_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field({description: `Display name for the relationship type, e.g. Employee, Spouse, Partner`}) 
    @MaxLength(200)
    Name: string;
        
    @Field({nullable: true, description: `Detailed description of this relationship type`}) 
    Description?: string;
        
    @Field({description: `Which entity types this relationship connects: PersonToPerson, PersonToOrganization, or OrganizationToOrganization`}) 
    @MaxLength(100)
    Category: string;
        
    @Field(() => Boolean, {description: `Whether the relationship has a direction. False for symmetric relationships like Spouse or Partner`}) 
    IsDirectional: boolean;
        
    @Field({nullable: true, description: `Label describing the From-to-To direction, e.g. is employee of, is parent of`}) 
    @MaxLength(200)
    ForwardLabel?: string;
        
    @Field({nullable: true, description: `Label describing the To-to-From direction, e.g. employs, is child of`}) 
    @MaxLength(200)
    ReverseLabel?: string;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field(() => [mjBizAppsCommonRelationship_])
    Common_Relationships_RelationshipTypeIDArray: mjBizAppsCommonRelationship_[]; // Link to Common_Relationships
    
}

//****************************************************************************
// INPUT TYPE for Common: Relationship Types
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
}
    

//****************************************************************************
// INPUT TYPE for Common: Relationship Types
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

    @Field(() => [KeyValuePairInput], { nullable: true })
    OldValues___?: KeyValuePairInput[];
}
    
//****************************************************************************
// RESOLVER for Common: Relationship Types
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
        input.EntityName = 'Common: Relationship Types';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonRelationshipType_, { nullable: true })
    async mjBizAppsCommonRelationshipType(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonRelationshipType_ | null> {
        this.CheckUserReadPermissions('Common: Relationship Types', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwRelationshipTypes] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Relationship Types', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Common: Relationship Types', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @FieldResolver(() => [mjBizAppsCommonRelationship_])
    async Common_Relationships_RelationshipTypeIDArray(@Root() mjbizappscommonrelationshiptype_: mjBizAppsCommonRelationshipType_, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine) {
        this.CheckUserReadPermissions('Common: Relationships', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwRelationships] WHERE [RelationshipTypeID]='${mjbizappscommonrelationshiptype_.ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Relationships', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.ArrayMapFieldNamesToCodeNames('Common: Relationships', rows, this.GetUserFromPayload(userPayload));
        return result;
    }
        
    @Mutation(() => mjBizAppsCommonRelationshipType_)
    async CreatemjBizAppsCommonRelationshipType(
        @Arg('input', () => CreatemjBizAppsCommonRelationshipTypeInput) input: CreatemjBizAppsCommonRelationshipTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Common: Relationship Types', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonRelationshipType_)
    async UpdatemjBizAppsCommonRelationshipType(
        @Arg('input', () => UpdatemjBizAppsCommonRelationshipTypeInput) input: UpdatemjBizAppsCommonRelationshipTypeInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Common: Relationship Types', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonRelationshipType_)
    async DeletemjBizAppsCommonRelationshipType(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Common: Relationship Types', key, options, provider, userPayload, pubSub);
    }
    
}

//****************************************************************************
// ENTITY CLASS for Common: Relationships
//****************************************************************************
@ObjectType({ description: `Typed, directional links between people and organizations supporting Person-to-Person, Person-to-Organization, and Organization-to-Organization relationships` })
export class mjBizAppsCommonRelationship_ {
    @Field() 
    @MaxLength(16)
    ID: string;
        
    @Field() 
    @MaxLength(16)
    RelationshipTypeID: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    FromPersonID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    FromOrganizationID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    ToPersonID?: string;
        
    @Field({nullable: true}) 
    @MaxLength(16)
    ToOrganizationID?: string;
        
    @Field({nullable: true, description: `Contextual title for this specific relationship, e.g. CEO, Primary Contact, Founding Member`}) 
    @MaxLength(510)
    Title?: string;
        
    @Field({nullable: true, description: `Date the relationship began`}) 
    @MaxLength(3)
    StartDate?: Date;
        
    @Field({nullable: true, description: `Date the relationship ended, if applicable`}) 
    @MaxLength(3)
    EndDate?: Date;
        
    @Field({description: `Current status: Active, Inactive, or Ended`}) 
    @MaxLength(100)
    Status: string;
        
    @Field({nullable: true, description: `Additional notes about this relationship`}) 
    Notes?: string;
        
    @Field() 
    @MaxLength(10)
    _mj__CreatedAt: Date;
        
    @Field() 
    @MaxLength(10)
    _mj__UpdatedAt: Date;
        
    @Field() 
    @MaxLength(200)
    RelationshipType: string;
        
    @Field({nullable: true}) 
    @MaxLength(510)
    FromOrganization?: string;
        
    @Field({nullable: true}) 
    @MaxLength(510)
    ToOrganization?: string;
        
}

//****************************************************************************
// INPUT TYPE for Common: Relationships
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
}
    

//****************************************************************************
// INPUT TYPE for Common: Relationships
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
}
    
//****************************************************************************
// RESOLVER for Common: Relationships
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
        input.EntityName = 'Common: Relationships';
        return super.RunDynamicViewGeneric(input, provider, userPayload, pubSub);
    }
    @Query(() => mjBizAppsCommonRelationship_, { nullable: true })
    async mjBizAppsCommonRelationship(@Arg('ID', () => String) ID: string, @Ctx() { dataSources, userPayload, providers }: AppContext, @PubSub() pubSub: PubSubEngine): Promise<mjBizAppsCommonRelationship_ | null> {
        this.CheckUserReadPermissions('Common: Relationships', userPayload);
        const provider = GetReadOnlyProvider(providers, { allowFallbackToReadWrite: true });
        const connPool = GetReadOnlyDataSource(dataSources, { allowFallbackToReadWrite: true });
        const sSQL = `SELECT * FROM [__mj_BizAppsCommon].[vwRelationships] WHERE [ID]='${ID}' ` + this.getRowLevelSecurityWhereClause(provider, 'Common: Relationships', userPayload, EntityPermissionType.Read, 'AND');
        const rows = await SQLServerDataProvider.ExecuteSQLWithPool(connPool, sSQL, undefined, this.GetUserFromPayload(userPayload));
        const result = await this.MapFieldNamesToCodeNames('Common: Relationships', rows && rows.length > 0 ? rows[0] : {}, this.GetUserFromPayload(userPayload));
        return result;
    }
    
    @Mutation(() => mjBizAppsCommonRelationship_)
    async CreatemjBizAppsCommonRelationship(
        @Arg('input', () => CreatemjBizAppsCommonRelationshipInput) input: CreatemjBizAppsCommonRelationshipInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.CreateRecord('Common: Relationships', input, provider, userPayload, pubSub)
    }
        
    @Mutation(() => mjBizAppsCommonRelationship_)
    async UpdatemjBizAppsCommonRelationship(
        @Arg('input', () => UpdatemjBizAppsCommonRelationshipInput) input: UpdatemjBizAppsCommonRelationshipInput,
        @Ctx() { providers, userPayload }: AppContext,
        @PubSub() pubSub: PubSubEngine
    ) {
        const provider = GetReadWriteProvider(providers);
        return this.UpdateRecord('Common: Relationships', input, provider, userPayload, pubSub);
    }
    
    @Mutation(() => mjBizAppsCommonRelationship_)
    async DeletemjBizAppsCommonRelationship(@Arg('ID', () => String) ID: string, @Arg('options___', () => DeleteOptionsInput) options: DeleteOptionsInput, @Ctx() { providers, userPayload }: AppContext, @PubSub() pubSub: PubSubEngine) {
        const provider = GetReadWriteProvider(providers);
        const key = new CompositeKey([{FieldName: 'ID', Value: ID}]);
        return this.DeleteRecord('Common: Relationships', key, options, provider, userPayload, pubSub);
    }
    
}