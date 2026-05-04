Product Requirements Document (PRD): Wit's End

1. Product Overview

Name: Wit's End (Brand concept: "Making studying suck less.")
Platform: Mobile (Android/Flutter)
Core Philosophy: Minimum friction, maximum output, zero boredom. Wit's End delivers high-yield, hyper-focused study modules designed to prepare students for AP-level exams. Instead of dry textbooks or sterile quiz apps, the entire experience is driven by highly opinionated, unorthodox "Personas" that give the app a distinct, entertaining edge.

2. Technology Stack & Architecture

Frontend: Flutter (Mobile UI), Riverpod (State Management), GoRouter (Navigation).

Backend & Identity: Supabase (Postgres Database, Auth, Storage for CDN/assets).

Monetization Engine: RevenueCat (Subscription management linked to Store Consoles).

3. Core Features (P0 - Launch Requirements)

A. The Launch Library (Target Subjects)

The V1 database will launch with five highly-curated subjects. Every subject must pass the "Wit's End Quality Audit" before deployment and will be structured around high-yield tactical info and common pitfalls.

Human Geography: * Tactical Info: Focus heavily on demographic transition models, maps, and cultural landscapes (Requires Map Image support).

The Gotcha: Confusing Environmental Determinism with Possibilism, or misapplying Von Thünen’s model to modern globalized agriculture.

Psychology: * Tactical Info: Rapid-fire recall of foundational theories, terminology, key figures, and the physical structures of the brain.

The Gotcha: Mixing up Classical vs. Operant conditioning, or confusing the specific functions of neurotransmitters (e.g., Dopamine vs. Serotonin).

World History (Modern): * Tactical Info: Broad global timelines, cause-and-effect relationships, and major trade networks.

The Gotcha: Memorizing exact dates instead of chronological trends, or failing to recognize cross-regional similarities (e.g., comparing Japanese and European feudalism).

US Government & Politics: * Tactical Info: Foundational documents (Federalist Papers), landmark SCOTUS cases, and systemic checks and balances.

The Gotcha: Misidentifying which Constitutional clause applies to a specific landmark case (e.g., Commerce Clause vs. Equal Protection Clause).

Environmental Science: * Tactical Info: Biological cycles, major environmental legislation, and core ecological vocabulary.

The Gotcha: Reversing the biological steps in the nitrogen cycle or misunderstanding the exact definition of the "Tragedy of the Commons."

B. The Persona Engine (The Tutors)

The app's UI copy, feedback, and grading prompts are dynamically driven by the user's selected "Tutor." Users can select from the following personas to guide their study sessions:

Ashleigh: Disaffected Gen-Z/Alpha TikTok influencer. Everything you do is either "low-key brilliant" or "absolute cringe."

Gerald: Sarcastic, pragmatic, millennial household Chief of Staff. He just wants you to get this done efficiently so he can go back to his iced coffee.

Marissa: Mean Girls grown up to be PTO President. Passive-aggressive, overly sweet, but deeply judgmental about your wrong answers.

Karen: Entitled, demanding, and always right. She WILL speak to the manager if you don't score a 5 on this exam.

C. V1 Question Archetypes & The Drill Engine

The app will cycle users through specific drill types, heavily flavored by their chosen Persona.

The Archetypes:

Matching (Rapid Recall): Text-based term-to-definition mapping. Built for speed and muscle memory.

Multiple Choice (MCQ): Scenario-driven applications. Supports text-only or "Stimulus" questions (requires fetching Maps, Charts, or Diagrams from Supabase Storage).

Free Response (FRQ): Deep-dive scenario prompts. Displays a prompt + optional image support, followed by a self-grading checklist/rubric for the user to validate their own mastery.

The Engine Logic:

Criticality/Probability Metadata: Every single question in the database must be tagged with a probability/criticality ranking (High, Medium, Low). This powers "Cram Mode," prioritizing the absolute highest-yield concepts for users short on time.

Adaptive Spaced Repetition (The "Retirement" System): The engine dynamically prunes the active deck based on knowledge gaps. Users can configure a "Retirement Threshold" in their settings (e.g., hide after 3 consecutive correct answers) and a cooldown duration (e.g., 24 hours, 72 hours, or Permanent). Mastered questions are automatically filtered out, forcing the user to focus exclusively on what they don't know.

Mashup Mode: A session configuration that allows users to select multiple subjects at once (e.g., Psychology + US Gov). The engine seamlessly intertwines questions from all selected subjects to match the reality of a student cramming for back-to-back exams.

D. Infrastructure & Identity

Auth System: Supabase Auth. Google Sign-In is mandatory for the Android launch. Apple Sign-In mandatory if launching to iOS.

The "Library" View & Favorites: A dynamic dashboard fetching available subjects and user progress from Supabase. Includes a "Star/Favorite" feature allowing users to pin their currently active subjects to the top of the screen to minimize search friction.

Cloud Sync & Preferences: Progress, selected Persona, "Mastery" data/hit-counts, Starred subjects, and Retirement user settings must sync to the Supabase Postgres database so users don't lose their data if they change devices.

E. Monetization & Store Compliance

Billing Engine: RevenueCat SDK to handle Monthly and Annual "Pro" subscription tiers.

Paywall UX: A high-conversion upgrade screen utilizing clear copy and native store checkout.

Compliance Protocol & Legal (Mostest.io Policy Updates): * Mandatory "Delete Account" button directly accessible in the app's user profile settings.

The existing mostest.io Privacy Policy and ToS must be updated to explicitly cover:

Strict Data Collection: Explicitly detailing the exact data we store to minimize liability. This is strictly limited to:

Auth Data: Email address and Google/Apple ID tokens.

User Profile: A user-chosen Alias/Display Name (real full names are not required or explicitly requested).

App State: Mastery progress, active Persona, Starred subjects, and custom settings (like the Retirement Threshold).

Third-Party Processors & Billing: Disclosure of Supabase (database/hosting) and RevenueCat (subscription state). Explicitly noting that actual payment/billing info (credit cards, addresses) is vaulted entirely by Google/Apple and never touches our servers.

COPPA Compliance: Explicitly stating the app is for users 13 and older (AP high school students).

Data Deletion Rights: Clear instructions within the policy on how users can execute complete data deletion.

4. Strategic Risk Mitigation (Legal & IP)

Trademarks: The letters "AP" or "Advanced Placement" will NOT be used in the main app title. Descriptive branding (e.g., "Wit's End: Making studying suck less.") will be used, alongside mandatory trademark disclaimers (e.g., "AP is a registered trademark of the College Board, which was not involved in the production of, and does not endorse, this product.").

Copyright: Zero usage of official past-exam questions or DBQs. All questions, stimuli, and rubrics must be 100% original variations.

Audio & Right of Publicity: Zero usage of direct audio rips from movies, viral memes, or video games. Furthermore, absolutely no generative AI "soundalikes" of real celebrities or voice actors (to avoid Right of Publicity/Lanham Act lawsuits). All persona audio snippets must use generic, unrecognizable generative AI voices or cleared royalty-free stock audio.

5. The "Not Yet" Bin (Out of Scope for V1)

To enforce scope and ensure a fast launch, the following features are strictly banned from V1 development:

Teacher/School Systems: No LMS integrations, rostering, or teacher dashboards.

User-Generated Content: No public marketplace or ability for students to write their own questions.

Advanced STEM: No complex LaTeX rendering or chemical formula support.

Social/Gamification: No leaderboards, friend lists, or competitive multiplayer modes.

6. Execution Milestones (0 to Launch)

Milestone 1: Foundation & Auth (The Shell)

Initialize Flutter project, Riverpod, and GoRouter.

Provision Supabase project and connect the Flutter client.

Implement Google Sign-In and the base User Profile model (incorporating the Alias/Display Name).

Definition of Done: A user can download the dev build, log in with Google, set an Alias, and see a blank placeholder dashboard.

Milestone 2: The Core Engine (Data & UI)

Define Supabase SQL schema for Subjects, Modules, Questions, User Settings (Retirement configuration, Starred Subjects), and User Progress (including tags for Criticality rankings and Mastery hit-counts).

Build the UI components for the 3 Archetypes (Matching, MCQ, FRQ) and the Persona Selection screen.

Wire the UI to a dummy JSON payload to test logic and state management.

Definition of Done: All three question types function perfectly with mock data, accurately updating local Riverpod state upon completion, and the UI dynamically updates its text based on the active Persona.

Milestone 3: Content Integration & Cloud Sync

Upload the 5 target subjects to the Supabase database.

Upload all necessary images (Maps/Charts) to Supabase Storage.

Wire the frontend "Library View" to fetch live data from Supabase, ensuring "Starred" subjects pin to the top.

Build the logic for "Cram Mode" (filtering by Criticality), "Mashup Mode" (querying multiple subjects), and the "Retirement System" (filtering out mastered questions based on User Settings).

Implement logic to push "Mastery" hit-counts, settings, Starred subjects, and active Persona back to Postgres after a session.

Definition of Done: A user can log in, pick "Karen" as their tutor, star two subjects, initiate a "Mashup Mode" session combining AP Psychology and Gov, correctly answer a question enough times to trigger their custom retirement threshold, and verify that the question does not reappear in the next session.

Milestone 4: Monetization & Compliance

Configure RevenueCat, Google Play Console, and set up the Pro tiers.

Build and integrate the Paywall UI.

Lock specific modules or subjects behind the active subscription check.

Implement the "Delete Account" function and link the Privacy Policy.

Definition of Done: A user hits a locked module, views the paywall, successfully completes a sandbox test purchase, and unlocks the content.

Milestone 5: Quality Audit & Launch

Conduct the "Wit's End Quality Audit" across all 5 subjects to fix typos and ensure accuracy.

Generate app store assets (Screenshots, Icon, Description with Legal Disclaimers).

Submit to Google Play Console for review.

Definition of Done: App is live on the store and ready to accept real user payments.