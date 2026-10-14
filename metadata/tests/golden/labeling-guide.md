# Blind labeler decision guide

Written before labeling. Sources: the title text and the Name/Description fields of the 12 job functions and 8 seniority levels. The seniority files have no rank field. The order used here is the order the descriptions imply: Individual Contributor < Team Lead < Manager < Director < Vice President < Senior Vice President < C-Level, with Board Member as a separate governance level.

## Function boundaries
- **Executive** vs a line function: owners, founders, co-owners, CEOs and owner/operators go to Executive. For a combined title like "Cheesemaker & Co-owner", ownership wins, and the craft function is the alternative.
- **Operations** is the home for physical production and core delivery, because the taxonomy has no Production or Manufacturing function. That covers cheesemaking, affinage, creamery and herd work, store operations, procurement and buying (supply chain), and production quality programs.
- **Sales** vs **Operations** at retail: front-line cheesemongers sell to customers, so they go to Sales, with Operations as the alternative. Store Manager runs the store, so it goes to Operations, with Sales as the alternative.
- **Sales** vs **Customer Success**: Account Manager goes to Sales, with Customer Success as the alternative.
- **Product** vs **Operations**: "Product Manager" goes to Product. A generic "Program Director" goes to Operations, with Product as the alternative. A retail or restaurant "Cheese Program" is merchandising and buying, so it goes to Operations.
- **Marketing**: brand roles.
- **Human Resources**: people, talent and recruiting roles ("Head of People").
- **Legal** vs **Operations** for food quality and safety: an internal QA director runs a production quality program, so that goes to Operations, with Legal as the alternative. A food safety *consultant* is a compliance or regulatory advisor, so that goes to Legal, with Operations as the alternative.
- **Engineering** QA means software or hardware QA. Food QA is not Engineering.
- **Education & Training**: lecturer, instructor, curriculum and training titles go to Education & Training, with Human Resources as the alternative.
- **Procurement**: Operations (supply chain), with Finance as the alternative.

## Seniority boundaries
- **Individual Contributor**: practitioners, specialists, reps, buyers, consultants, apprentices, juniors, "II" grades, lecturers and instructors. "Senior" or "Sr." on its own stays IC.
- **Team Lead**: "Lead" titles and "Head <craft practitioner>" (Head Cheesemaker, Head Cheesemonger). These lead a craft team, with Manager as the alternative.
- **Manager**: any "Manager"/"Mgr" who runs a team or unit (Store, Creamery, Herd, Operations). "Sr. Mgr" stays Manager, with Director as the alternative. Product Manager and Associate Brand Manager are IC by practice, with Manager as the alternative.
- **Director**: "Director"/"Dir." and "Head of <function>" (Head of People), with Vice President as the alternative.
- **Vice President**: "VP" titles.
- **C-Level**: "Chief ..." officers, CEO (including interim), and owners, founders and co-owners (they are the top executive of their business).
- **Board Member**: Board Chair and board or advisory titles.
- **Principal** is ambiguous: an owner or partner of a small firm, a school principal, or a senior consultant. I label it Executive/Director, with C-Level as the alternative.

## Abbreviations, languages, trade titles, multi-role titles
- Expand the common abbreviations: Mgr = Manager, Sr. = Senior, Dir. = Director, VP = Vice President, Ops = Operations.
- Non-English titles: translate first. "Jefe de Producción" means Production Manager, so it goes to Operations/Manager.
- Cheese trade titles: a cheesemonger is a retail cheese seller, an affineur ripens cheese, and a cheesemaker produces it. Novelty C-titles ("Chief Cheese Officer") are C-Level, and the function is Executive, with Marketing as the alternative.
- Multi-role titles take the highest seniority. Ownership makes the function Executive, and the other role becomes function_alt.
- Mark ambiguous=1 only when a second label is genuinely defensible on either dimension.

## Addendum (sample 2, 12 titles)
- **"Assistant"/"Asst."** prefix and "Asst. to the X": Individual Contributor. The function follows the parent role. "Asst. to the Regional Manager" names no function, so it goes to Operations, with Sales as the alternative.
- **Generic "Lead" titles** (Production Lead, Counter Lead): Team Lead. A cheese "counter" is the retail selling floor, so Counter Lead goes to Sales, with Operations as the alternative, consistent with how I labelled cheesemongers.
- **"Quality Manager"** and its French form **"Responsable Qualité"**: Operations/Manager, with Legal as the alternative, consistent with Dir. Quality Assurance. "Responsable" can also mean the department head, so Director is the seniority alternative.
- **"Fromager"** (French, cheese specialist): the retail cheese expert, so it gets the cheesemonger label, Sales/IC. Because in France the word also covers makers and affineurs, the alternative is Operations.
- **"Principal" + function noun** (Principal Engineer): a senior Individual Contributor in that function. This differs from a bare "Principal", which is a firm principal.
- **"GM"** (General Manager): Executive, because the Executive description includes general management. It is labelled Director, consistent with Principal, with C-Level as the alternative, since a GM is often the top operator of a small business. Operations is the function alternative.
- **Volunteer Coordinator**: Human Resources (people and recruiting of volunteers)/IC, with Operations as the alternative. "Coordinator" is an IC title.

## Labeler selection (label-quality rig)
- Labelers B and C are chosen by the rig, not by this guide's author: for each vendor (B = OpenAI, C = Google), the Active LLM with the highest PowerRank that the vendor itself serves, so the two new labelers are two different model families (GPT and Gemini). A PowerRank tie goes to the model with the lower output price (its active cost row for that vendor), then to the model name.
- Labelers B and C run at their provider's default temperature: the rig sends none, because some frontier models (GPT-6 Astra) accept only their default, and MJ has no metadata saying which. The labels are reproducible from the audit file (`job-title-labels-audit.json`), which stores every labeler's answer.
- Labeler C's purpose is a second model family. It is Google Gemini because no Anthropic Claude route worked with this host's credentials. The classifier under test is also a Gemini model, so B (OpenAI) is the labeler from outside the classifier's family. The audit file records each new labeler's vendor and model.
