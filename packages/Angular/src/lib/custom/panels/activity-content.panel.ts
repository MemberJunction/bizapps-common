import { Component, ChangeDetectionStrategy, ChangeDetectorRef, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel, BaseFormsModule } from '@memberjunction/ng-base-forms';
import type { mjBizAppsCommonActivityEntity } from '@mj-biz-apps/common-entities';

/**
 * Rich Activity Notes & Full Text Panel.
 *
 * Placed as a primary lead section above Details in the left rail.
 * Renders the full activity description, meeting notes, call takeaways, or email excerpts
 * in an elevated reading view with typography, text stats, copy actions,
 * and expand/collapse reading mode.
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:Activities:content',
    metadata: {
        entity: 'MJ_BizApps_Common: Activities',
        slot: 'after-fields',
        sortKey: 150,
        contributionKey: 'content',
        inclusion: 'Primary',
    },
})
@Component({
    selector: 'bizapps-activity-content-panel',
    standalone: true,
    imports: [CommonModule, FormsModule, BaseFormsModule],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        <mj-collapsible-panel
            SectionKey="activityContent"
            SectionName="Notes"
            Icon="fa-solid fa-note-sticky"
            [Form]="FormComponent"
            [FormContext]="FormContext"
            [DefaultExpanded]="true">

            <div class="mja-content">
                @if (EditMode) {
                    <!-- EDIT MODE: Rich textarea -->
                    <div class="mja-content__edit">
                        <label class="mja-content__label" for="activity-notes-input">
                            <span>Activity Notes &amp; Text</span>
                            <span class="mja-content__stats-pill">{{ WordCount }} words &bull; {{ CharacterCount }} chars</span>
                        </label>
                        <textarea
                            id="activity-notes-input"
                            class="mja-content__textarea"
                            rows="10"
                            placeholder="Add call notes, meeting takeaways, email excerpts, or action items..."
                            [ngModel]="Record.Description"
                            (ngModelChange)="OnTextChange($event)">
                        </textarea>
                    </div>
                } @else {
                    <!-- READ MODE: Formatted reader pane -->
                    @if (HasContent) {
                        <div class="mja-content__reader">
                            <div class="mja-content__toolbar">
                                <div class="mja-content__stats">
                                    <span class="mja-pill">
                                        <i class="fa-solid fa-file-lines"></i>
                                        {{ WordCount }} words
                                    </span>
                                    <span class="mja-pill mja-pill--muted">
                                        {{ CharacterCount }} characters
                                    </span>
                                </div>
                                <div class="mja-content__actions">
                                    <button
                                        type="button"
                                        class="mja-btn-subtle"
                                        (click)="CopyToClipboard()"
                                        [title]="Copied ? 'Copied to clipboard!' : 'Copy notes text'">
                                        <i [class]="Copied ? 'fa-solid fa-check text-success' : 'fa-regular fa-copy'"></i>
                                        <span>{{ Copied ? 'Copied!' : 'Copy' }}</span>
                                    </button>
                                </div>
                            </div>

                            <div
                                class="mja-content__body"
                                [class.is-collapsed]="!IsExpanded && IsLongContent"
                                [class.is-expanded]="IsExpanded">
                                {{ Record.Description }}
                            </div>

                            @if (IsLongContent) {
                                <div class="mja-content__expand-footer">
                                    <button
                                        type="button"
                                        class="mja-btn-expand"
                                        (click)="ToggleExpanded()">
                                        <i [class]="IsExpanded ? 'fa-solid fa-chevron-up' : 'fa-solid fa-chevron-down'"></i>
                                        <span>{{ IsExpanded ? 'Show less' : 'Read full text' }}</span>
                                    </button>
                                </div>
                            }
                        </div>
                    } @else {
                        <div class="mja-content__empty">
                            <div class="mja-content__empty-icon">
                                <i class="fa-regular fa-note-sticky"></i>
                            </div>
                            <div class="mja-content__empty-copy">
                                <h4>No Notes Recorded</h4>
                                <p>There is no full text or notes saved for this activity yet.</p>
                            </div>
                            @if (FormComponent) {
                                <button
                                    type="button"
                                    class="mja-btn-add"
                                    (click)="EnableEdit()">
                                    <i class="fa-solid fa-plus"></i> Add Notes
                                </button>
                            }
                        </div>
                    }
                }
            </div>
        </mj-collapsible-panel>
    `,
    styles: [`
        :host {
            display: block;
            width: 100%;
            margin-bottom: var(--mj-space-4, 16px);
        }

        .mja-content {
            padding: 4px 0;
        }

        /* EDIT MODE STYLES */
        .mja-content__edit {
            display: flex;
            flex-direction: column;
            gap: 8px;
        }

        .mja-content__label {
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 12px;
            font-weight: 600;
            color: var(--mj-text-secondary, #475569);
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }

        .mja-content__stats-pill {
            font-size: 11px;
            font-weight: 500;
            text-transform: none;
            color: var(--mj-text-muted, #94a3b8);
        }

        .mja-content__textarea {
            width: 100%;
            min-height: 180px;
            padding: 12px 14px;
            border-radius: var(--mj-radius-md, 8px);
            border: 1px solid var(--mj-border-default, #cbd5e1);
            background: var(--mj-bg-surface, #ffffff);
            color: var(--mj-text-primary, #0f172a);
            font-family: inherit;
            font-size: 14px;
            line-height: 1.6;
            resize: vertical;
            transition: border-color 0.15s ease, box-shadow 0.15s ease;
            box-sizing: border-box;
        }

        .mja-content__textarea:focus {
            outline: none;
            border-color: var(--mj-brand-primary, #0284c7);
            box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15);
        }

        /* READ MODE STYLES */
        .mja-content__reader {
            border: 1px solid var(--mj-border-default, #e2e8f0);
            border-radius: var(--mj-radius-md, 8px);
            background: var(--mj-bg-surface, #ffffff);
            overflow: hidden;
            box-shadow: 0 1px 2px rgba(0, 0, 0, 0.04);
        }

        .mja-content__toolbar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 10px 14px;
            background: var(--mj-bg-surface-subtle, #f8fafc);
            border-bottom: 1px solid var(--mj-border-default, #e2e8f0);
        }

        .mja-content__stats {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .mja-pill {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            font-size: 11px;
            font-weight: 600;
            color: var(--mj-text-secondary, #334155);
            background: #e2e8f0;
            padding: 2px 8px;
            border-radius: 9999px;
        }

        .mja-pill--muted {
            background: transparent;
            color: var(--mj-text-muted, #64748b);
            font-weight: 500;
        }

        .mja-btn-subtle {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 10px;
            font-size: 12px;
            font-weight: 500;
            color: var(--mj-text-secondary, #475569);
            background: transparent;
            border: 1px solid var(--mj-border-default, #cbd5e1);
            border-radius: 6px;
            cursor: pointer;
            transition: all 0.15s ease;
        }

        .mja-btn-subtle:hover {
            background: var(--mj-bg-surface-hover, #f1f5f9);
            color: var(--mj-text-primary, #0f172a);
            border-color: var(--mj-brand-primary, #0284c7);
        }

        .text-success {
            color: #059669 !important;
        }

        .mja-content__body {
            padding: 16px 18px;
            font-size: 14px;
            line-height: 1.65;
            color: var(--mj-text-primary, #1e293b);
            white-space: pre-wrap;
            word-break: break-word;
            font-family: inherit;
        }

        .mja-content__body.is-collapsed {
            max-height: 240px;
            overflow: hidden;
            position: relative;
            mask-image: linear-gradient(to bottom, black 65%, transparent 100%);
            -webkit-mask-image: linear-gradient(to bottom, black 65%, transparent 100%);
        }

        .mja-content__expand-footer {
            display: flex;
            justify-content: center;
            padding: 8px 14px 12px;
            border-top: 1px dashed var(--mj-border-default, #e2e8f0);
            background: var(--mj-bg-surface-subtle, #f8fafc);
        }

        .mja-btn-expand {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            font-size: 12px;
            font-weight: 600;
            color: var(--mj-brand-primary, #0284c7);
            background: transparent;
            border: none;
            cursor: pointer;
            padding: 4px 8px;
            border-radius: 4px;
            transition: background 0.15s ease;
        }

        .mja-btn-expand:hover {
            background: rgba(2, 132, 199, 0.08);
        }

        /* EMPTY STATE STYLES */
        .mja-content__empty {
            display: flex;
            flex-direction: column;
            align-items: center;
            text-align: center;
            padding: 32px 16px;
            border: 1px dashed var(--mj-border-default, #cbd5e1);
            border-radius: var(--mj-radius-md, 8px);
            background: var(--mj-bg-surface-subtle, #f8fafc);
        }

        .mja-content__empty-icon {
            font-size: 28px;
            color: var(--mj-text-muted, #94a3b8);
            margin-bottom: 8px;
        }

        .mja-content__empty-copy h4 {
            margin: 0 0 4px;
            font-size: 14px;
            font-weight: 600;
            color: var(--mj-text-secondary, #334155);
        }

        .mja-content__empty-copy p {
            margin: 0 0 16px;
            font-size: 12px;
            color: var(--mj-text-muted, #64748b);
        }

        .mja-btn-add {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            font-size: 12px;
            font-weight: 600;
            padding: 6px 14px;
            border-radius: 6px;
            color: #ffffff;
            background: var(--mj-brand-primary, #0284c7);
            border: none;
            cursor: pointer;
            transition: opacity 0.15s ease;
        }

        .mja-btn-add:hover {
            opacity: 0.9;
        }
    `]
})
export class ActivityContentPanel extends BaseFormPanel<mjBizAppsCommonActivityEntity> implements OnInit {
    constructor(private cdr?: ChangeDetectorRef) {
        super();
    }

    public IsExpanded = false;
    public Copied = false;

    public ngOnInit(): void {
        // Default to collapsed if long content
        this.IsExpanded = false;
    }

    public get HasContent(): boolean {
        return !!(this.Record?.Description && this.Record.Description.trim().length > 0);
    }

    public get IsLongContent(): boolean {
        const text = this.Record?.Description || '';
        return text.length > 350 || text.split('\n').length > 7;
    }

    public get CharacterCount(): number {
        return this.Record?.Description ? this.Record.Description.length : 0;
    }

    public get WordCount(): number {
        const text = (this.Record?.Description || '').trim();
        if (!text) return 0;
        return text.split(/\s+/).filter(Boolean).length;
    }

    public ToggleExpanded(): void {
        this.IsExpanded = !this.IsExpanded;
        this.cdr?.markForCheck();
    }

    public OnTextChange(val: string): void {
        this.Record.Description = val;
        this.cdr?.markForCheck();
    }

    public async CopyToClipboard(): Promise<void> {
        const text = this.Record?.Description || '';
        if (!text) return;

        try {
            if (navigator?.clipboard) {
                await navigator.clipboard.writeText(text);
            }
            this.Copied = true;
            this.cdr?.markForCheck();
            setTimeout(() => {
                this.Copied = false;
                this.cdr?.markForCheck();
            }, 2000);
        } catch {
            // fallback
        }
    }

    public EnableEdit(): void {
        if (this.FormComponent) {
            this.FormComponent.EditMode = true;
        }
    }
}
