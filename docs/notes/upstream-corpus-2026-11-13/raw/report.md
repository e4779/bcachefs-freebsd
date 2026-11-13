## FreeBSD Status Report Third Quarter 2026

Here is the third 2026 status report, with 51 entries.

This report is published a bit later than the last few, but we are finally here!
The main reason for the delay is the recent PHP vulnerabilities issue: https://reviews.freebsd.org had to be taken down for a little while, and unfortunately some reports were still being reviewed there.
But the problem is now fixed and we are back on track.
As this happened in October, do not expect to read about it in this status report however.
This will be material for the last 2026 status report: do not miss it!

Have a nice read!

Lorenzo Salvadore, on behalf of Status Team

---

Table of Contents

- FreeBSD Team Reports
  - FreeBSD Core Team
  - FreeBSD Foundation
  - FreeBSD Release Engineering Team
  - Cluster Administration Team
  - Bugmeister Team
- Projects
  - FreeBSD, CRA, EuroBSDCon, and Security Team
  - Cyber Resilience Act (CRA) Readiness Project
  - FreeBSD Software Bill of Materials (SBOM)
  - Capsicumize fts(3)
  - Full CPUID Control for bhyve
  - A bhyve management GUI written in Freepascal/Lazarus
  - Desktop Script for bsdinstall
  - Sylve — A Unified System Management Platform for FreeBSD
  - Vision Accessibility
  - x11appjail: Tool for creating, verifying, installing, and running AppJails
  - Port of rdma-core project to FreeBSD
  - NFS over Remote Direct Memory Access (RDMA)
  - nfsdtop(8) shows who is using the NFS server
  - Enhancing Zoned Storage support
  - LLDB Improvement on FreeBSD
  - Procdesc: debugging API
- Userland
  - Scheduler
  - Syscall filtering for truss(1)
  - sysconf(8) completes the configuration trinity
  - CUSE Improvements
  - ext2fs user space tools
- Kernel
  - Boot Loader Improvements
  - Suspend/Resume Improvements
  - Audio Stack Improvements
  - Adopt -fbounds-safety in the FreeBSD Kernel TCP/IP Stack
  - Netlink Support for Tunnel Interfaces
  - Netlink Payload Decoding Infrastructure for FreeBSD Tracing Tools
  - LinuxKPI 802.11 and Native Wireless Update
  - Series of IPv6 Improvements
  - Series of Routing Stack Improvements
  - BPF/ifnet Contract Hardening: D59140
  - Storage Discovery and Diagnostics Improvements
  - x86 splitlocks detection support
  - Aquantia / Marvell aq(4) Device Driver
- Architectures
  - FreeBSD Driver Development for BananaPi R2 / R64 / R2 Pro
  - ROCm Support on FreeBSD
- Cloud
  - FreeBSD on EC2
- Documentation
  - Documentation Engineering Team
  - The FreeBSD Russian Documentation Project
- Ports
  - FreshPorts: Translations
  - Brave Browser on FreeBSD: Status Report
  - Dockerbox
  - KDE on FreeBSD
  - Improve OpenJDK on FreeBSD
  - FreeBSD HPC Ports Modernization
  - Improve libvirt support for bhyve hypervisor

---

## FreeBSD Team Reports

Entries from the various official and semi-official teams, as found in the Administration Page.

---

### FreeBSD Core Team

The FreeBSD Core Team is the governing body of FreeBSD.

#### Completed items

We completed the following items:

##### Handover from the previous Core Team

The handover from core.13 was completed: mail aliases, the LDAP group, and the Phabricator group now contain only core.14 members.

##### Core liaisons

- FreeBSD Foundation: bapt@ (with most of core@ participating in monthly Foundation meetings)
- secteam: kevans@
- clusteradm: adrian@
- srcmgr: imp@
- portmgr: adamw@, olivier@
- doceng: hrs@
- re: hrs@

##### Public meeting minutes

We reached consensus to publish our public meeting minutes, which were previously only sent to the developers mailing list.

##### FreeBSD Developer AI survey

bapt@ created a survey for FreeBSD developers on the use of AI and LLMs.
He presented the results to core@, and a summary was shared with developers.
140 developers responded.

- Policy: 88% want the Project to adopt a policy, either a formal, written policy (49%) or light guidance and best practices (39%).
  6% said that AI should be explicitly discouraged, and 3% that the existing contribution rules are sufficient.
- AI-assisted code: 35% said it must be disclosed, 25% that it must be reviewed more strictly than human code, 22% that it should be treated like any other contribution, and 16% that it should be rejected outright.
- Safeguards: mandatory human review (78%) and mandatory disclosure (69%) were requested most often, followed by provenance or licensing documentation (47%) and mandatory testing (39%).
- Disclosure: 84% want AI use disclosed, either always (48%) or when its involvement is significant (36%).
  79% want AI-assisted commits marked in the commit log, and 56% prefer a tag that names the tool.
- Concerns: the main concerns about quality are correctness and subtle bugs (39%), licensing and provenance (26%), and maintainability (21%).
  75% are somewhat or very concerned about copyright and licensing.
- Principles: accountability, meaning that a human remains responsible (91%), and transparency (78%) were selected most often, and preserving code quality was the top-ranked goal for a policy.
- Other uses: 65% would allow AI-generated documentation with human review.
  54% would allow AI tools on Project infrastructure, most of them with restrictions, and 29% would not.

The FreeBSD Foundation asked for a core representative on the committee for the upcoming user survey.
jrm@ volunteered.

##### Ports repository freeze and history rewrite

On 2026-07-20, a 150 MB binary file was mistakenly committed to the ports tree.
The commit broke mirroring to GitHub, which rejects files larger than 100 MB, and added a file of questionable licensing to the repository history.
On 2026-07-21, core@ decided to freeze the ports repository to limit the number of commits that would need to be rewritten, and worked out a plan with clusteradm@, portmgr@, and the Git administrators.
kevans@ published a signed statement on 2026-07-22 to explain the freeze and to make clear that the ports tree had not been compromised.
The offending commits were removed by rewriting the history of the main branch, and package builds from the old hashes were stopped.
New server-side hooks now guard against a recurrence.

##### EU Cyber Resilience Act (CRA) statement

The FreeBSD Foundation asked core@ to recognize it as an open source steward.
We settled on a statement of support, which was published on the announce and developers mailing lists.

##### Releases

We reviewed the draft announcement for 14.5-RELEASE and the proposed schedule for 15.2-RELEASE.

##### Developer and contributor conflicts

We dealt with conflicts between developers and external contributors.
Decisions were communicated to the parties involved.

##### Commit bit policy

##### Correspondence

We handled correspondence on a number of topics, including the current and future AI policy work and the impact of increased AI/bot-driven scraping on FreeBSD infrastructure.

#### Work in progress

##### Core secretary role

We are defining the scope of a funded secretary role, which may serve the whole project rather than only core@.
Examples from other non-profits and FreeBSD working groups are being used as a reference.
There is rough consensus to move the role towards a project management assistant.
A proposal was shared with the FreeBSD Foundation and feedback is pending.

##### AI policy

imp@ created an AI working group made up of people with diverse opinions on the topic.
The working group will use the developer survey results as input for a policy on the use of AI/LLMs.
The kickoff meeting of the group will be held on October 7.
Final reports are expected in Q4.

##### Bylaws and core terms

We are continuing the previous Core Team’s work on staggered terms.
We consider ourselves a transitional Core Team and plan to invoke the bylaws' staggering provision, with the change taking effect in 2027.
Before the 2027 election, we will designate which members step down after one year and which serve a full two-year term; the vacated seats will be filled in that election.

##### Regularizing policy

Efforts are underway to modernize and centralize the FreeBSD Project’s policy documentation, which is currently inconsistent, poorly visible, and reliant on unwritten "tribal knowledge."
imp@ is working to consolidate existing guidelines, resolve policy contradictions between project groups, and formally record long-standing traditions.
Additionally, this initiative will identify gaps where new, formal policies are needed to ensure smooth, efficient operations.
We hope to have this wrapped up by the end of Q1 2027.

##### Liaison expectations

We are documenting the responsibilities of each liaison role and will publish the document once it is complete.

##### Workflow organization

We are evaluating tooling to track our tasks, documents, and correspondence.
We began using a CryptPad instance set up by bapt@ and clusteradm@.

##### Policy on reasonable content for Project spaces

We discussed writing down the Project norms for what content is reasonable for Project spaces, such as the wiki and repository metadata.
Over the years, we have developed a tradition of avoiding politics, religion, and other contentious issues unrelated to the Project, and need to write it down and bring it in line with open source norms.

##### portmgr structure

We are discussing the structure of portmgr@ and how to revamp the team.

##### Cluster administration planning

adrian@ and some clusteradm@ members are preparing a budget, prioritizing work, improving documentation and processes, and planning to recruit new team members in 2027.

##### Returning developers

srcmgr@ has a new policy for returning developers, which asks for some recent work or plans before access is restored, and portmgr@ has something similar.
We are discussing whether it makes sense for these policies to be aligned across teams.

##### Privacy requests

core@ received a GDPR erasure request covering mailing list posts from more than twenty years ago.
Removing content from public mailing list archives is not practical, especially for archives the Project does not control.
The Project has a privacy policy, which should be extended to cover mailing lists, Bugzilla, and other services.
We communicated this to the person requesting the removal.

##### Core and FreeBSD Foundation meetings

Monthly meetings are scheduled through December 2026.

##### Bay Area Vendor Summit in November

We are planning a short introduction and update followed by a question and answer session.

---

### FreeBSD Foundation

The FreeBSD Foundation is a 501(c)(3) non-profit dedicated to advancing FreeBSD through both technical and non-technical support.
Funded entirely by donations, the Foundation supports software development, infrastructure, security, and collaboration efforts; organizes events and developer summits; provides educational resources; and represents the FreeBSD Project in legal matters.

#### Advocacy

In the third quarter of 2026, our advocacy efforts focused on expanding our educational video content, engaging with the FreeBSD community, and preparing for the upcoming FreeBSD Vendor Summit.
We also continued highlighting the people, projects, and initiatives that support FreeBSD’s growth and long-term success.
Here are a few of the ways the Foundation advocated for FreeBSD in Q3 2026:

- Represented FreeBSD at EuroBSDCon 2026, with Alice Sowerby, Program Manager at the FreeBSD Foundation, joining Pierre Pronchery and Peter Hansteen to present a full-day tutorial, The Night Before CRAmas — Why EU Regulations Are a Gift to Open Source, covering the EU Cyber Resilience Act (CRA) and its implications for FreeBSD vendors.
- Published the following blogs and videos to help to inform and educate the community:

  - Represent FreeBSD in Your Community
  - FreeBSD Foundation Welcomes New Board Member: Dave Cottlehuber
  - Understanding the Foundation Board’s Role in the FreeBSD Ecosystem
  - BSDCan 2026 Trip Report — ShengYi Hung
  - BSDCan 2026 Travel Report — Patrick McEvoy
  - BSDCan 2026 Travel Report — Novković
  - An Update on the FreeBSD Journal: New Editor, New Format
  - FreeBSD Foundation Intern Jim Huang Chen on Raspberry Pi Support and Open Source
  - FreeBSD Foundation Intern Sourojeet Adhikari on Bringing ROCm to FreeBSD
  - Learning at Scale: FreeBSD Foundation Intern Nimish Jain on Exploring the FreeBSD Codebase
  - Worry-Free Upgrades with FreeBSD
- Published the June/July 2026 and August/September 2026 FreeBSD Foundation Newsletters.
- Released the April/May/June 2026 and July/August/September 2026 issues of the FreeBSD Journal with HTML versions of the articles.

#### Continuous Integration and Workflow Improvement

The Foundation supports a full-time staff member dedicated to improving the Project’s continuous integration system and test infrastructure.

#### Legal/FreeBSD IP

The Foundation owns the FreeBSD trademarks, and it is our responsibility to protect them.
We also provide legal support for the core team to investigate questions that arise.

---

### FreeBSD Release Engineering Team

Contact: FreeBSD Release Engineering Team <re@FreeBSD.org>

The FreeBSD Release Engineering Team is responsible for setting and publishing release schedules for official project releases of FreeBSD, announcing code freezes and maintaining the respective branches, among other things.

The Team managed 14.5-RELEASE, leading to the official RELEASE build and announcement in September.
Planning has started for the upcoming 15.2-RELEASE, which is due to arrive in December.

The Release Engineering Team continued providing weekly development snapshot builds for the __main__, __stable/15__, and __stable/14__ branches.

---

### Cluster Administration Team

FreeBSD Cluster Administration Team members are responsible for managing the machines the Project relies on to synchronize its distributed work and communications.

In this quarter, the team has worked on the following:

- Regular support for FreeBSD.org user accounts.
- Regular disk and parts support (and replacement) for all physical hosts and mirrors.
- Cluster software refresh.
- Coordinate community mirrors.
- Ports repository history rewrite.
- Frequent interventions to thwart denial of service by bots.
- Improvements to cgit on our global mirror network.

#### Cluster refresh

Work continues to refresh the software running on FreeBSD.org cluster machines.
We have started putting production workloads on stable/15.
As part of this work some workloads are being moved around to different machines.
This work is ongoing at the end of the quarter.

The clusteradm team refreshes the production package builders (circa 35 physical machines) on a roughly six- to eight-week cadence.
These machines run FreeBSD current snapshots.

Other machines are upgraded on an as-needed basis, keeping up with security fixes depending on how exposed they are.

At the time of this writing there are 143 physical machines in the cluster.
We have 45 machines on current, 33 on stable/15 and 59 on stable/14.

Most of the remaining stable/13 installations will be upgraded to stable/15 or decommissioned.

```
 12.x: Regular   0, Jails   7
 13.x: Regular   6, Jails  28
 14.x: Regular  59, Jails 223
 15.x: Regular  33, Jails  60
>16.x: Regular  45, Jails   6
Total: Regular 143, Jails 324
Total installations: 467
Running -RELEASE|{-p*}: 0
Total geographic sites: 14
```

#### FreeBSD official mirrors

Current locations are Australia, Brazil, Japan (two full mirror sites), Malaysia, South Africa, Sweden, Taiwan and United States of America — California, Chicago, New Jersey, and Washington.

Our mirror site in Taiwan is experiencing an extended outage.
A new mirror site in Taiwan is being deployed at the beginning of 2026Q4.

One of our mirror sites in Japan will get a complete hardware refresh in 2026Q4.

The hardware and network connection have been generously provided by:

- Cloud and SDN Laboratory at BroadBand Tower, Inc
- Department of Computer Science, National Yang Ming Chiao Tung University
- Internet Association of Australia
- Internet Systems Consortium
- INX-ZA
- KDDI Web Communications Inc
- Malaysian Research & Education Network
- MetaPeer
- New York Internet
- NIC.br
- Sonic
- Teleservice Skåne AB
- Your.Org

New official mirrors are always welcome.
We have noted the benefits of hosting single mirrors at Internet Exchange Points globally, as evidenced by our existing mirrors in Australia, Brazil, and South Africa.
If you are affiliated with or know of any organizations willing to sponsor a single mirror server, please contact us.
We are particularly interested in locations in Europe.

#### Ports repository history rewrite

In July a committer inadvertently pushed a large binary file to the ports repository, necessitating a freeze and subsequent rewrite of the history.
The clusteradm team rewrote the history of the ports tree and ensured that the new history was visible on all our internal and external mirrors in the shortest possible time.
Improvements were made to our Git infrastructure and automation to prevent this happening again.

#### Large language model scraping

The FreeBSD Project’s infrastructure continues to be under constant attack from scrapers collecting training data for large language models ("AI").
The companies training these models have largely moved scraping operations from their own — easy to identify — infrastructure to botnets ("residential proxies"), making them difficult to block at the network edges without significant collateral damage.
The Cluster Administration Team spent a considerable amount of time again this quarter mitigating these distributed denial of service attacks.

#### Improvements to cgit on our global mirror network

https://cgit.FreeBSD.org is a particularly popular target for trainers of probabilistic malware.
We experience a constant torrent of scrapers running on infected computers and appliances all around the world.
To spread the load of these attacks, the clusteradm team increased the number of cgit nodes on our mirrors.
This quarter we deployed additional https://cgit.FreeBSD.org mirrors in California and in Paris.

---

### Bugmeister Team

Comments welcome.
The list is not complete.

Item #1 is the big priority, the Web Crawlers problem.

tl:dr; we know about it; we have spent a great deal of time analyzing it; since we know its cause, the symptoms are not particularly interesting; and this has been raised and acknowledged as a serious issue to/by core@.
There is not much more that Bugmeisters themselves can do here.

Item #2 is generating a policy about LLM-derived contributions.

This depends on portmgr feedback which Mark Linimon requested quite some time ago.

Item #3 is owned by Mark Linimon.

The overview is that the _contents_ of patches in the Bugzilla database is in much better shape than it was two years ago, and Mark continues to try to triage them weekly; but also that Mark keeps getting dragged away from working on this by other issues.

Item #4 is conference calls.

We still have not set up weekly conference calls or some other method of coordination.
Without that, these issues tend to just remain stuck.
We could definitely use help here.

#### Statistics

In this quarter we slightly increased the Problem Report count.
The throughput, however, is much higher, especially for ports.
This may be due to the auto-notifier customizations we previously implemented.

For the src tree, in the last 90 days we have received 329 new
Problem Reports and closed 269.
For ports, the count was 2208 and 2138 respectively.

We do not currently maintain statistics about how many of these actually generate commits, although we do believe the number to be non-trivial.

Mark Linimon has taken on the long-term project of making sure that the submitted patches all apply.
However, he does not claim to be a QA person and to be able to evaluate their aptness by himself.
He is out of his depth here.

The general takeaway is that, with user education, we are getting better-quality Problem Reports this year.
In particular, the ones with patches are being tested for applicability within a week or two of their arrival, and corrected if needed.

We have created many new Bugzilla accounts by user request.
The number of new-account requests has increased this quarter.
In Q3 2026 we added 164, which is not quite 2 per day.

## Projects

Projects that span multiple categories, from the kernel and userspace to the Ports Collection or external projects.

---

### FreeBSD, CRA, EuroBSDCon, and Security Team

This is my second quarter in the FreeBSD Foundation as part of Alpha-Omega’s Security Engineers In Residence (SEIRs) initiative.
Thanks to the input received from the Security Team, I have integrated a staging instance of Forgejo with a self-hosted LLM, demonstrating the potential of new capabilities for the Security Team, without breaching any confidentiality requirements.
This system is capable of dealing with incoming security vulnerability reports, by:

- Drafting an initial response for the submitter
- Issuing an immediate, automated analysis of the issue submitted
- Preparing a template for an eventual Security Advisory (SA) or Errata Notice (EN)
- Checking the SA or EN drafts for conformity
- Automatically signing the final SA, EN, and corresponding assets
- Uploading the outcome where appropriate

This is implemented like a typical, modern CI/CD system with Forgejo’s runner tool as a GitHub-compatible workflow.
The aim is to leverage LLM capabilities for our processes, in accordance with the current workflow, without compromising on confidentiality nor on the necessity for quality review by us mortal members of the security team.

Significant polishing is still required, but the corresponding instance in production should be useful even without the LLM part.
The automation of the more repetitive tasks of the workflow is expected to help us deal with the steady amount of incoming reports, and to extend capabilities from our individual minds into the team as a whole.

In parallel, I have not spared my efforts towards compliance with the European Cyber Resilience Act (CRA) for the FreeBSD Project.
After importing pkgconf in FreeBSD’s base system during the last quarter, I went through a number of iterations for the framework generating Software Bill of Material (SBOM) artefacts during the build.
Prepared together with Tuukka Pasanen, the framework is available for review in D56474 and I now believe it to be a serious candidate for integration.
I would like to thank everyone who has been providing feedback already!
This has helped tremendously to find a balance that feels more right than at any time earlier — at least to me.
A separate request for review for the meta-data is now available as well, D60352, which currently generates a total of 218 artefacts for an amd64 build.
The balance consists of about one artefact per base package generated, as well as one artefact per library actually used during the build.
This way, the complete chain of dependencies can be tracked, while keeping the granularity close to individual third-party projects or internal components.

I would also like to extend my thanks to Alice Sowerby and to Peter Hansteen for an awesome workshop about CRA compliance during EuroBSDCon 2026 in Brussels, this past September 2026.
If you have missed it, you may be in luck, as we are gearing up to deliver it again at a future event.
Do not hesitate to reach out to us if you are interested, together with your rough location and flexibility for travel, so we can have a more accurate impression of the times and places we should aim for.

Sponsor: Alpha-Omega, The FreeBSD Foundation

---

### Cyber Resilience Act (CRA) Readiness Project

The Foundation is running a project through 2026 to actively prepare the FreeBSD Foundation, Project, and community for the EU Cyber Resilience Act.
There are six main areas of focus: Security and Vulnerability Handling, SBOM Toolchain, Public Documentation, Community Legislative Engagement, Public Project Repository, and Communications.

Over Q3, the project has continued to move from planning into implementation, with particular focus on readiness for the CRA’s vulnerability and incident reporting requirements that came into force for manufacturers on September 11, 2026.

The Foundation has created a cyber security policy and CRA reporting protocol to support the Foundation in meeting its obligations as an open source software steward.
Both have been developed with input from the FreeBSD Core and Security Teams and document how the Foundation will work with the Project and respond if CRA reporting obligations are triggered for the Foundation as a steward.
Note that the European Commission has clarified that reporting obligations for stewards begin on December 11, 2027.
These documents will remain internal resources for the time being.

Technical work on the Software Bill of Materials (SBOM) toolchain has continued through development, testing, and review.
The proposed approach for generating SBOMs for the FreeBSD base system is being refined in response to feedback and still requires further review and supporting changes before integration.
Work is also progressing across the wider SBOM ecosystem, both through the Foundation and in the community, including planned support for ports, SPDX-compatible license information, and CycloneDX and SPDX SBOM support in pkgconf.

The Foundation has continued to engage with the FreeBSD and wider open source communities, especially the Eclipse Foundation’s Open Regulatory Compliance (ORC) working group.
At EuroBSDCon 2026, we collaborated with Peter Hansteen to run a day-long CRA and SBOM tutorial.
We also presented an update on this project at the FreeBSD Developer Summit.

Project updates and meeting notes continue to be published through the public project repository.
As we move into Q4, the focus will be on progressing the SBOM implementation and upstream work, improving the discoverability of our public CRA guidance, and working with the FreeBSD Project to identify key manufacturer needs that relate to their CRA obligation to adopt a secure software lifecycle by December 11, 2027.

---

### FreeBSD Software Bill of Materials (SBOM)

The FreeBSD Software Bill of Materials (SBOM) effort has been continued during Q3 2026.
At last, getting SBOM into FreeBSD source is manifesting itself and hopefully will be finalized in Q4.
Thanks to Pierre Pronchery, there is a Phabricator review ongoing: D60352 for FreeBSD source.
Also, ports have one for reviewing: D60441 made by Mathieu Arnold.

As an option for SBOM output, there are currently available SPDX 2.2 and Lite 3.0.1.
CycloneDX SBOM tool is in work in progress and still needs some love to be as qualified as the output for SPDX.
In the future, all SBOM outputs will be under one tool, which will be named `sbomtool`, and as both solutions rely on pkgconf, they will have CycloneDX when it lands in FreeBSD source.

There are several updates from `BSD-2-Clause` to `BSD-Source-beginning-file` in review:

- sys/arm/arm/busdma_machdep.c: Correct SPDX-License-Identifier
- sys/powerpc/powerpc/busdma_machdep.c: Correct SPDX-License-Identifier
- sys/powerpc/powerpc/busdma_bounce.c: Correct SPDX-License-Identifier
- sys/x86/x86/busdma_machdep.c: Correct SPDX-License-Identifier
- sys/x86/x86/busdma_bounce.c: Correct SPDX-License-Identifier
- sys/kern/subr_busdma_bounce.c: Correct SPDX-License-Identifier

Additionally, many third-party repositories have received SPDX License Identifiers, such as libxo (thanks to Juniper for that), and others.
Some projects do not want headers, and some are still in active development.

If you want to help with this effort:

- Review Phabricator changes.
  SPDX License Identifier corrections are at a very low level to review.
- When pkgconf CycloneDX is available, help review and test it.

Sponsor: FreeBSD Foundation

---

### Capsicumize fts(3)

The fts(3) directory traversal library, used by find(1), rm(1), ls(1), chflags(1) and other utilities, historically relied on path-based syscalls that fail in capsicum(4) capability mode.

This quarter fts gained a new `fts_openat()` entry point that accepts a pre-opened directory descriptor, a per-entry `fts_dirfd` field, and a conversion of its internals to fd-relative operations, with ABI compatibility preserved through ELF symbol versioning.
A traversal can now run entirely inside a Capsicum sandbox.

As a first consumer, chflags was capsicumized to perform its work through `chflagsat()` on descriptors opened before entering capability mode, confining it to the hierarchies named on its command line.

This work was completed as a Google Summer of Code 2026 project.

Sponsor: Google Summer of Code 2026

---

### Full CPUID Control for bhyve

#### Project Overview

Ongoing work on this project aims to integrate the existing proof-of-concept work into FreeBSD, and to add the following usability features:

- a user-friendly configuration method to override individual bits, parts or even whole CPUID functions as needed, while keeping the rest of the host CPUID information or a pre-defined CPUID configuration
- a user-friendly configuration method for the hypervisor signature reported by bhyve
- a set of predefined CPUID configurations based on common x86 architecture levels, perhaps also including a set of CPUID data for a few real CPU models, and a user-friendly configuration method to choose one for a VM

#### Changes during the last quarter

##### Changes to the bhyve configuration syntax

There was a last minute change to the configuration syntax.
Instead of using two different options `cpuid.enable` and `cpuid.disable` to enable or disable features by name, there is now a single `cpuid.features` option.
This option accepts feature name, either prefixed with `-` to disable them, or prefixed with `+` or no prefix to enable a feature.

##### Pre-defined CPU Models

In addition to the abstract x86 architecture models, a number of CPU models have been implemented as pre-defined configuration file snippets.
This currently ends with the Icelake generation for Intel and the Bulldozer generation for AMD.

Many more cpuid configuration options have been introduced to ease writing of CPU model configurations, such as `cpuid.brand` for the CPU Brand String or `cpuid.vendor` to override the vendor identification.

##### CPUID Constraints checks

The constraints checks have been extended to allow defining bitmasks for values that can only be numerically lowered.

A new configuration option `cpuid.check` has been introduced to override the default action regarding the constraints checks.
It takes the values `fail` (the default), `warn`, `none`, and `fix`.

##### Cache Configuration

Default cache configurations have been added to the x86 architecture models and all pre-defined CPU models.

##### Hypervisor Identification

A new `cpuid.hypervisor` option allows easy overriding of the hypervisor identification in CPUID function 0x40000000.
The real hypervisor identification and feature flags can still be queried by guests from CPUID function 0x40000100.

#### Plans for the next quarter

- Add more modern pre-defined CPU models
- Update manpages bhyve(8), bhyve_config(5), and bhyvectl(8).
- Get the whole wad reviewed and committed into FreeBSD.

---

### A bhyve management GUI written in Freepascal/Lazarus

Bhyvemgr is a bhyve management GUI written in Freepascal/Lazarus on FreeBSD.
It needs a bunch of tools, mostly installed on base system, and some installed from ports/packages.
The main goal is to be a desktop application with focus on desktop users to easily and quickly setup and run virtual machines on FreeBSD hosts.

Starting with version v2.0.0, bhyvemgr was migrated to client/server architecture.
As a result, a server component was developed.
This new component is called bhyvemgrd.

Bhvemgrd supports two ways to run privileged tasks: mac_do/mdo (FreeBSD >= 140000) and mac_do/setcred/exec_paths (only for FreeBSD >= 1501501).
The process itself run under an unprivileged bhyvemgrd user.

During last two quarters, there were many bugfixes and improvements to Bhyvemgr.

These are some highlights that were added:

- Add new operating system options
- Add support to use VNC unix sock (vnc.sock) when FreeBSD >= 1500509
- Add support for storage snapshot (only if zfs is enable)
- Improve TPM support
- Move to client/server architecture (unixsocket, json, etc).
  The bhyvemgr keeps like a client and a new bhyvemgrd app is used like a server.
- Remove privileged functions/procedures.
  Now they are part of bhyvemgrd.
- Remove sudo/doas support.
  It is not necessary anymore because privileged tasks will trigger from bhyvemgrd service.
- Remove FreeBSD 13.x support
- Replace remote-viewer support (virt-viewer) with vncviewer (tigervnc-viewer).
  The vncviewer needs less dependencies and it can be ligther than virt option.
- Other fixes, improvements and changes

Bhyvemgr and Bhyvemgrd supports aarch64 from 15.x to 16-CURRENT and amd64 from FreeBSD 14.x to 16-CURRENT.
Bhyvemgr can be compiled or installed from sysutils/bhyvemgr with gtk2, qt5, or qt6 interface support.
Bhyvemgrd can be compiled or installed from sysutils/bhyvemgrd.

People interested in helping or supporting the projects are welcome.

Current bhyvemgr version: 2.1.0
Current bhyvemgrd version: 1.2.0

---

### Desktop Script for bsdinstall

The goal of this project is to provide a simple feature in bsdinstall(8), the FreeBSD system installer, to install and configure a graphical environment.
The installer should ask users whether they want to install a desktop environment and, if so, automatically install and configure everything needed with minimal or no user intervention.
After reboot, users should be presented with a graphical login screen.

In the first 2026 status report, a possible solution was described: a shell script of approximately 400 lines of code to install and automatically configure the components required for a graphical desktop environment, including GPU drivers, Xorg, KDE Plasma, and SDDM.
After a call for testing, which received a significant amount of feedback from users, review D56167 was submitted to add the new desktop script to bsdinstall.

After the review was submitted, several discussions took place about the proposed implementation.
As a result of the review, it was requested to split the script into smaller components and move part of its functionality into separate ports.
The review, D56167, is now obsolete.
Several possible approaches were then analyzed and tested.

The chosen solution is to create new ports with flavors.

The base port provides the tools to build menus and/or return to the script a list of packages to install.
The menu utilities are implemented as shell scripts because the design of a Lua API for the text user interfaces is still in progress.

Each flavor provides a pkg-post-install-lua(5) script to configure the package installed on the new system.
pkg-post-install-lua was chosen instead of the pkg-post-install(5) shell script because it will make it easier to reuse the code if it becomes necessary to use pkg-trigger(5) in the future.

The following four new ports with flavors, with a total of 26 packages, have been created and submitted to Bugzilla:

- x11/bsdinstall-desktop PR298402

  - Base port utilities: bsdinstall-desktop-checks, bsdinstall-desktop-users with menu support.
  - Flavor: -audio.
- graphics/bsdinstall-gpu PR298413

  - Base port utility: bsdinstall-gpu with menu support.
  - Flavors: -amd, -drm, -intel, -nv304, -nv340, -nv390, -nv470, -nv580, -nv595, -nv610, -nvaddons, -nvoptimus, -radeon, -scfb, -vbox, -vesa, -vmware.
- x11/bsdinstall-de PR298442

  - Base port utility: bsdinstall-de.
  - Flavors: -kde, -wireplumber.
- x11/bsdinstall-dm PR298455

  - Base port utility: bsdinstall-dm with menu support.
  - Flavors: -ly, -sddm.

A new draft of the desktop script has also been completed in the project repository.
It is significantly different from the original script and is now approximately 100 lines of code.
A new review to add the desktop script to bsdinstall will be submitted after the new ports have been added to the Ports Collection.

This is still an experimental feature.
In the future, depending on user interest and feedback, the desktop script can be further improved to support additional desktop environments and graphical tools.

Sponsor: The FreeBSD Foundation

---

### Sylve — A Unified System Management Platform for FreeBSD

Sylve is a modern, unified system management platform for FreeBSD.
It provides an integrated web interface for managing virtual machines (via Bhyve), Jails, the networking around them, and ZFS storage.

The backend is implemented in Go, while the frontend is built with Svelte.
The project emphasizes a minimal system footprint.
By default, it does not require any packages outside of the base system.

Optional runtime dependencies, required only when their respective features are used, include:

- devel/libvirt for virtualization
- devel/qemu for disk image management
- Samba 4.x (for example net/samba424) for SMB file sharing
- sysutils/swtpm for TPM emulation support
- dns/dnsmasq for DHCP and DNS services

The port pulls in these dependencies for convenience to the user, but by itself, Sylve needs no dependencies to run.

#### Q3 Progress Highlights

We published two tagged releases this quarter: v0.3.0 on August 24, which shipped the networking, migration, replication, and backup work reported last quarter, and v0.3.1 on September 7, the latter improving cluster recovery, backups, migration, and guest storage management.

##### Data Center / Cluster

- Migration between cluster nodes now transfers the bulk of the ZFS data while the workload is still online, followed by a final incremental transfer and a guarded cutover.
- Backups now commit related datasets and VM disks as coordinated generations, with stronger restore and recovery workflows.

##### Storage

- Deeper ZFS and ARC telemetry and scheduled S.M.A.R.T. tests were added.
- VM storage workflows were redesigned in v0.3.1, with explicit semantics for ejecting and deleting attachments.

##### Operations

- A protected local CLI and interactive console were added for common VM, Jail, networking, and lifecycle operations.
- Certificate and Dynamic DNS management are built in, including free Sylve.app hostnames with managed TLS, plus Cloudflare and Namecheap support.

##### General

- The user documentation received a major overhaul, with task-oriented guides for all major features.
- Sylve now requires libvirt 12.5.0 or newer for VM management; FreeBSD 15.0 or newer remains required.

##### Roadmap Update

The FreeBSD Foundation has expanded its support for Sylve with a new grant for parts of the next phase of the platform.

The next quarter(s) will bring:

- Native OCI container management through Podman.
- An App Gallery with templates for deploying applications in Jails and containers.
- NFS sharing and automatic ZFS dataset tuning.
- A mobile app for managing clusters, operating-system updates from the interface, and ZFS scrub schedules.
- End-to-end testing and clearer migration documentation.
- A simplified interface for beginners.

Sponsors: The FreeBSD Foundation, Alchemilla Ventures (Development), IPTechnics LLC (Infrastructure & Testing)

---

### Vision Accessibility

Vision Accessibility is a project focused on improving visual accessibility in FreeBSD by documenting, developing, and integrating assistive technologies for blind and visually impaired users.

#### High-contrast Theme

During this quarter, work focused mainly on Milestone 2: creating new accessible themes for TUI utilities in the FreeBSD base system, with the ability to select one during the OS installation.

The next version of bsddialog was developed as part of this work, with a focus on improving its theming support.
The theming code was reorganized and improved, and the bsddialog_theme.h API was extended to allow applications to select and customize themes more easily and automatically.

In particular, the library initialization process now uses __bsddialog_get_auto_theme()__, which automatically detects the theme to use.
If available, the theme can be selected through a centralized system-wide or user-specific configuration file.
This allows utilities in the FreeBSD base system, such as tzsetup(8) and bsdinstall(8), as well as ports such as ports-mgmt/portconfig, to use the same theme configuration without requiring individual changes to each application.

Several accessibility-oriented themes were also improved or added:

- Improved the built-in black-and-white theme.
  It was originally designed for terminals without color support, but it is also useful for presenting information without relying on colors alone.
- Added a theme without red, using black, blue, cyan, white, and yellow.
- Added a theme without yellow and blue, using black, green, red, and white.
- Added a new high-contrast theme, using black, magenta, white, and yellow.

The new functionality has been documented in the manual pages, with new examples, and in the bsddialog CHANGELOG.

The design and implementation phases have been completed, and testing is now starting.
The new functionality is currently available only in the main branch of the bsddialog repository.

The next steps are to complete testing, release version 1.2, update the devel/bsddialog port, and import the new version into FreeBSD BASE.

#### Braille display devices

During this quarter, a HumanWare BrailleNote Apex was acquired for use in the upcoming milestones.
A suitable charger was received and the device was successfully tested.
The Braille display and keyboard are working, as is the built-in speech synthesizer.

Although the Braille subsystem is planned for a future milestone, initial experimentation has already started because designing and integrating such a subsystem is a complex task.
These first tests are intended to provide practical information for its future design and implementation.

The BrailleNote Apex is not simply a Braille display, but a Braille notetaker running Windows Embedded CE 6.0.
It provides a one-dimensional user interface through KeySoft, with applications such as a word processor, email, web browsing, and other functionality.
The Apex was also connected to an external monitor through VGA, which made it easier to explore and better understand its functionality.

Using the Apex requires familiarity with Braille, both for writing through the Braille keyboard and for reading through the Braille display.
For this reason, LearnBraille was also developed and used.
It is a simple Lua script that uses devel/liblouis to provide a quiz for practicing Braille characters.

The Apex was connected to FreeBSD through USB and used in its "Screen Reader Terminal" mode, which allows the device to operate as a Braille display connected to another computer.
The device is recognized by uipaq(4), and communication is provided through the man:ucom interface[4].
This is consistent with the device’s architecture, as the Apex runs Windows Embedded CE 6.0.

Initial communication tests were successful in both directions.
Data was sent from FreeBSD to the Braille display, including a simple "Hello World, FreeBSD!" message rendered on the Braille cells.
Characters typed on the Braille keyboard were also received by FreeBSD.
In this direction, each Braille character is represented by one byte, with its bits corresponding to the Braille dots.

Further tests, documentation, and information about the progress and results of this work will be provided in future reports.

Sponsor: The FreeBSD Foundation

---

### x11appjail: Tool for creating, verifying, installing, and running AppJails

__x11appjail__ is a specialized tool for creating, verifying, installing, and running AppJails.
An AppJail is a CLI, TUI or X11 application that runs inside a FreeBSD jail but is perceived by the end user as identical (or at least very similar) to an application running directly on the host system.

This tool makes extensive use of appjail(1) as its engine; however, unlike the latter, the primary user in __x11appjail__ is neither root nor a privileged user, but rather an unprivileged user.
The fundamental goal of this project is to grant the user limited access to the jail, restricted solely to the execution of a CLI, TUI or X11 application.

This project began months ago as a prototype to establish a workflow leveraging appjail-x11(1); however, starting with version 1.0.0, it was rewritten from scratch into a unified tool that integrates all its projects, such as sysutils/appjail, sysutils/unixexec, archivers/appscript, and sysutils/jtransfer, among others.
Even better, it allows for the execution of not only X11 applications but also CLI and TUI programs.

The most relevant project for x11appjail(1) is not only appjail(1), but also appscript(1).
My goal with appscript(1) is to create an ultra-lightweight alternative to AppImage for FreeBSD that does not depend on FUSE, thus eliminating the need to configure `vfs.usermount=1`.
appscript(1) allows you to create an elf(5) executable that contains everything necessary to run a self-contained executable.

- Executables created by appscript(1) extract the payload cooperatively: the leader process extracts the payload once using an exclusive lock, while other processes (if any) wait using a shared lock.
  Unlike previous versions, where the payload was extracted to a random directory upon every execution, this significantly improves performance by extracting the payload only once; furthermore, the resulting directory is removed by the last remaining process once no running processes remain.
- appscript-verify(1) is a new command installed by archivers/appscript to verify executables signed with signify(1); it is particularly relevant to x11appjail(1)'s `veriexec` (see below).
- x11appjail(1)'s `veriexec` is an internal tool used by x11appjail(1) to run an AppJail in portable mode only if it is signed with a trusted key.
  This tool is unrelated to NetBSD’s `veriexec`.
- Both tools support the classic, battle-tested SHA-256 algorithm and the faster yet secure BLAKE3 algorithm.
  When sysutils/b3sum is available (the default if x11appjail(1) was installed from ports), BLAKE3 is the default choice, unless SHA-256 is explicitly specified in rc.conf(5).

  The checksum algorithm is fundamental to both x11appjail(1) and appscript(1).
  In the case of x11appjail(1), the algorithm is used in internal operations such as `veriexec`, whereas appscript(1) uses it to verify executables.
  BLAKE3 has been selected as the default option because it offers greater speed without compromising security.
- Attributes have been implemented in x11appjail(1) as a means for both the user and the system operator to manipulate the behavior of an AppJail.
  For example, a system operator can create the system attribute __users__.uid.__perms__, the content of which might be "__enable_3d__ __sound__ __usb__ __webcam__".
  An unprivileged user can create the user attributes appname:profile.__allow__.__enable_3d__ and appname:profile.__allow__.__sound__.
  Subsequently, when executing an AppJail, devices become visible or remain hidden depending on whether the user holds the corresponding permission and has authorized those permissions for the jail being created.
  In this case, the hardware acceleration and sound devices will become visible, provided the AppJail has incorporated the necessary logic to make them visible.

Another notable change worth mentioning for x11appjail(1) are the examples added in `${EXAMPLESDIR}/Apps`: `badwolf`, `chromium`, `evince`, `feh`, `firefox`, `htop`, `linux-brave`, `mpv`, `nanonote`, `telegram-desktop` and `thunderbird`.
Beyond the applications themselves, the key factor is the deployment method.
`htop` is an example of a CLI application, `linux-brave` is a Linux application, and the others are X11 applications.
Web browsers, Mpv, and Thunderbird are the most interesting examples, as they demonstrate how an AppJail can use VirtualGL to properly enable hardware acceleration within a FreeBSD jail, something that would not normally be possible given that Xephyr is the backend used by appjail-x11(1).
Best of all, from the end-user’s perspective, all of this is transparent.

---

### Port of rdma-core project to FreeBSD

The Remote Direct Memory Access (RDMA) infrastructure provides high-performance interconnect between computing and storage nodes.
It can operate over different physical networks, for instance Ethernet and Infiniband.

The implementation of the RDMA stack consists of several components.
There is the core kernel infrastructure, and drivers for Host Channel Adapters (HCAs), providing access to the kernel verbs.
Userspace applications never interact with the kernel devices directly, the core libibverbs library and vendor-specific userspace drivers provide unified and device-specific verbs.

Since RDMA intent of providing low-latency low-overhead operations, performant HCAs offload a lot of operations from CPU.
Also, typical in-line operations like send and receive can be initiated and completed in userspace, where kernel only assists in the connection establishment and teardown.
Due to this, the userspace RDMA software stack is crucial for its operations.

FreeBSD base system includes port of the so called OFED kernel core component, kernel drivers, as well as userspace core (libibverbs) and userspace drivers, for instance libmlx5 for managing Nvidia Connect-X4 and later HCAs.
Over time, the kernel parts get some significant updates from the infiniband code in the Linux kernel, which become the home for updated OFED.
Userspace part of OFED was converted into the rdma-core userspace project, that only supports Linux (and glibc).
Since userspace drivers in rdma-core provide essential functionality, and since FreeBSD userspace RDMA components are quite outdated, the situation overall needs a resolution.

We attempted to update the in-tree userspace components by importing the series of rdma-core commits with dependencies, but it quickly proved to be not feasible.
Instead we started looking at what it would take to make rdma-core compile and run on FreeBSD.

First, there were a number of missing glibc-specific APIs that were used in rdma-core, for instance, strdupa() and friends, main:tdestroy(3), some pthread functions.
These were easy to handle in the base system, and addition of them benefited the whole FreeBSD porting story.

Next, and more serious, the unportable features of glibc were used everywhere in the sources, and trying to cover them all would cause huge porting patch, which is problematic to push upstream, even for cooperating upstream.
Instead, the idea of using an approach similar to LinuxKPI for kernel code, was formed and developed, called LinuxAPI.
Unlike LinuxKPI, which handles architectural mismatches between Linux kernel and FreeBSD kernel, in addition to the different C interfaces, LinuxAPI needs to smooth out the differences around extensions to the same core functionality defined by POSIX.
It is mostly about bits that are not defined by POSIX but needed for RDMA to function, like networking interface enumeration, or discovery of the rdma-capable devices and their capabilities etc.

It seems that people consider the LinuxAPI useful outside the rdma-core porting efforts already, there is a project github.com/freebsd/linuxapi which takes the developed set of headers and extends it further.
We are currently working on providing the permissive license to make the library useful without additional strings attached.

Our initial goal, also limited by the available hardware, is to have rdma-core work with the ConnectX-4 cards.
Of course we welcome all vendors interested in RDMA on FreeBSD to improve the port to properly support their cards.

The result of the porting is available as the repository.
Also we try to upstream the changes so that FreeBSD would become the second natively supported platform for rdma-core.
The Pull Request to the github project is submitted.
There is currently a blocking discussion about the way to organize CI for FreeBSD platform.
Gleb Popov created the net/rdma-core port from the forked sources, which is already in the ports tree.

The kernel changes to get the port working were surprisingly small and contained.
They mostly consisted of bug fixes for the code paths not previously exercised by userspace since there were no userspace.
Most interesting part was perhaps the difference in ioctl(2) behavior between Linux and FreeBSD, where Linux can both return an error and copyout the data structure.
The issue was already observed in the LinuxKPI, and the porting work provided the generic solution there.

Sponsor: Nvidia networking

---

### NFS over Remote Direct Memory Access (RDMA)

Currently FreeBSD’s NFS is supported over TCP (and UDP for NFSv3).
This project adds support for NFS over RDMA, as described by RFC-8166 and RFC-8267.
This should allow RDMA aware NICs to offload most of the network transport and improve performance over fast LAN fabrics.

Thanks to Vinicius, a lot of progress has been made.
He has the NFS server side working, and quite well from what I know.

The client side is now testing quite well against Vinicius’s server and both client and server are now ready for third party testing.
To test, a client and server with Mellanox ConnectX4→6 NICs running a kernel built from recent FreeBSD main sources is needed.

See nfs-over-rdma-setup.txt for information on setting up a testing environment.

A stable/15 kernel should be sufficient for the loadable modules in a few weeks.
The client code should also be committed to FreeBSD’s main in a few weeks, with an MFC to stable/15 be the end of 2026.
The server code was created via generative AI and the FreeBSD project is working on a policy for handling generative AI submissions.
In the meantime, the server code will be available as an "unofficial port" that builds a kernel loadable module.

Third party testing would be appreciated.

Thanks go to Vinicius for the NFS server work and to the FreeBSD Netperf cluster folk, without which I would have never gotten this code tested.

Sponsor for the NFS server code: Verastus HPC

---

### nfsdtop(8) shows who is using the NFS server

nfsstat(1) reports the server as a whole.
nfsdtop(8) reports the user, the group, or the client behind the reads and writes.
It is a top-like display, taken with dtrace(1) from the nfsd(8) paths `nfsrvd_read`, `nfsvno_read`, `nfsrvd_write`, and `nfsvno_write`.

The default view is per user.
`-g` coalesces by group, and `-c` by IPv4 client.
Each interval prints a total, then the rows that did the I/O, sorted by combined read and write volume.
The default interval is two seconds.
The columns are humanized bandwidth unless `-b` asks for the bytes moved in that interval.
WRITE(IN) is data the clients sent.
READ(OUT) is data the server sent.

```
nfsdtop
nfsdtop -c
nfsdtop -g -G wheel
```

A UID, GID, or client address on those paths belongs to the client, not to the server.
nfsdtop(8) does not ask getent(1) to name them while it samples.
Names come from map files in the current directory: .nfsd.passwd, .nfsd.group, and .nfsd.hosts.
A filter (`-U`, `-G`, or `-C`) is resolved once, from those maps and then with getent(1) or host(1), and the result is compiled into the dtrace(1) predicate.

`-j` emits one JSON object for the view total and one per key, each interval, with the byte counts and the rates.
`-J` samples the client, group, and user views together:

Only root, or a user who can run dtrace(1), can run it.
The client view and `-C` are IPv4 only.
`-R`, or a non-empty `NFSDTOP_REDACT`, replaces names that are not well-known system accounts with random strings of the same length.

The introduction is in HEAD as of 60c7313074b9 (D59438), and nfsdtop(8) makes its first release in FreeBSD 16.0.

Thanks to Alexander Ziaee and Benedict Reuschling for the man page, to Adrian Chadd for review, and to Rick Macklem for a look at the NFS side.

Run it on a server that is already busy.
If the row you need is not a user, a group, or a client, please write.

---

### Enhancing Zoned Storage support

#### Project Overview

Work on this project intends to enhance Zoned Storage support in FreeBSD, by adding the following new features:

- New gzoned(8) GEOM driver for emulating zoned devices.
- Zoned Namespaces (ZNS) support for zoned NVMe drives.
- Improved Zoned Storage handling for gconcat(8), glabel(8), and gpart(8).

The work was carried out as part of Google Summer of Code 2026.

#### Importance to FreeBSD

The new gzoned(8) driver emulates Zoned Storage on top of regular, non-zoned drives, allowing for development, testing, and integration of Zoned Storage without zoned hardware.

ZNS support enables using Zoned Storage on NVMe SSDs.

Zone-aware GEOM classes let host-managed drives be used with the usual storage tools.

#### Status

ZNS support was added to the nda(4) driver, while nvd(4) support is not planned due to its barebones nature.

Host-managed devices can now be concatenated through gconcat(8), while glabel(8) will cleanly refuse them for automatic labeling due to its metadata requirement.
gpart(8) can now create GPT partition schemes on host-managed drives by not writing the backup GPT table.

#### Plans for next quarter

- Polish up gconcat(8), glabel(8), and ZNS support, as they can now rely on gzoned(8) from main.
- Merge the complete work into main.

---

### LLDB Improvement on FreeBSD

I was off for university from May to August and I am back to working on this now.
Since I could not accomplish this task for LLVM 23, the target release for completion has changed to LLVM 24.

armv7 and powerpc64be are support candidates now.
Once LLDB refactoring is done, I will implement support for those architectures.

Unlike KGDB that uses custom frame sniffer for trapframe unwinding, LLDB uses DWARF CFI instead.
DWARF CFI works on KGDB as well; when a frame is not recognized by KGDB’s frame sniffer, it will fall back to CFI.
Thus, no change on the KGDB side is needed.

Sponsor: The FreeBSD Foundation

---

### Procdesc: debugging API

The process descriptors API enhancements project continued, with the goal to allow complete process control using descriptors, in particular, debugging.
I wanted to make it possible to stop reference pids as the process identifiers.
The milestone for it should be a demonstration of enabling the capsicum mode for some non-trivial debugger, I selected truss(1) because it does not need neither filesystem nor network namespace accesses after attached to the target.

The semi-obvious solution there is to introduce pdptrace(2), which is equivalent to ptrace(2) but takes the process descriptor as the process designator.
We need to be able to obtain the notifications of the process debugging events, which are provided by waitpid[2] syscall family for pid-based controls.
And, we need a way to obtain the process descriptor for a new child forked from the debuggee, to continue tracing of all descendants.

Previously, the pdopenpid(2) system call was added, which allows to get a handle on an arbitrary process.
Existing operations on the process descriptors are somewhat limited: handle owner can wait for the exit notification using kqueue(2), and with some luck retrieve the process exit status.

The last point requires some elaboration.
Since the pdwait(2) call was added recently, there were some amount of hacks in the kernel to allow waitpid(2) calls on pid’s of processes created with pdfork(2).
As result, the waitpid(2) caller might have reaped the process before owner of the process descriptor could call pdwait(2).
Similarly, if there is more than one process descriptor opened on the same process, only the first pdwait(2) caller could retrieve the exit status with pdwait(2), making other descriptors useless.

The listed set of problems also made it very hard to correctly use the proposed pdptrace(2).
The process being debugged could steal events from process descriptors and vice versa.
Simply disallowing wait(2) on processes with the opened descriptors is not an option for two reasons:
* backward compatibility, waitpid(2) was already allowed and existing binaries relied on it
* if the debuggee used fork(2) to create a child, it expects to get the exit notification (e.g. SIGCHLD) and exit status from wait(2)

The solution was manyfold.
First, we have to postpone reaping if there are either opened process descriptors, or if the process was created with fork(2), we should not reap until wait(2) is called on pid by the parent.
Second, the exit status needs to be preserved in the process descriptors private data even after reaping, to allow pdwait(2) on any of the descriptors.
This was implemented by providing a bitmap of the 'zombie refs' on the kernel struct proc.
Each zombie reference prevents reaping, and cleared by corresponding call to waitpid(2) or pdwait(2).
Only when all registered references are cleared, zombie can be reaped.
If the process is created with pdfork(2) or opened with pdopenpid[2], it gets the procdesc zombie reference.
If the process was created with fork(2), it gets the 'parent' zombie reference.
By default, pdfork[2] also sets the parent reference to allow the waitpid(2), for compatibility.
The new pdfork(2) flag PD_NOWAITPID prevents that.

Then, wait-like events must work with the process descriptors.
The procdesc kqueue(2) event filter was extended with NOTE_PDSIGCHLD hints to report that pdwait(2) can retrieve tracing or exiting event on the descriptor.

Then, the pdptrace(2) was able to usefully control the target.
A new ptrace call to retrieve the list of the attached processes PT_GET_CHILDREN allowed pdptrace(2) to get hold of forks.

With all the features implemented, it was possible to convert truss(1) to use only process descriptors to control the traced processes.
The existing mode of using pids was preserved, and can be selected with the '-y' option as an emergency switch and to easy comparison and debugging of the new mode.

Sponsor: The FreeBSD Foundation

---

## Userland

Changes affecting the base system and programs in it.

---

### Scheduler

This quarter, a number of fixes and cleanups were merged to ULE and 4BSD:

- Fix priority conflation of differently-niced CPU-bound threads (4BSD).
- Fix priority diminishing too slowly when consuming CPU, because of some obsolete SMP scaling (4BSD).
- Fix selecting lowest priority thread early in some corner cases (ULE).
- Only allocate local runqueues (used for pinning/bound threads) for CPUs that are actually present (4BSD).
- Removal of unused `hlt_cpus_mask` and `sched_do_timer_acccounting()`.
- Removal of unused `kern.sched.4bsd.followon` (4BSD).
- When setting `kern.sched.{4bsd,ule}.slice`, check the value makes sense and make sure to update dependent internal constants such as `hogticks` and `sched_slice_min`.
- Ensure `sched_slice_min` and the quantum computation stay sane for small quantum values (ULE).
- Update some comments.

Work is on-going and nearing completion on cleaning up the machinery allowing multiple scheduler implementations (a.k.a., "instances") to co-exist in the same kernel.
From a single list of function descriptors, it now automatically produces the declaration of functions in the scheduler interface and in scheduler instances, the fields of the scheduler instance descriptor structure and the dispatching functions.
A second round of changes is in preparation, with the aim to potentially remove implementation functions' namespacing (e.g., having `ule` or `4bsd` in their names) in the source code, in effect renaming them back to their old names, which are those of the interface functions, while keeping the namespacing for C symbols which is required for debugging and in general manipulation by various ELF tools.

Work continues in the background on solutions to long-standing shortcomings in the ULE scheduler such as unfairness for non-interactive threads in certain particular circumstances and the very weak effect of nice values.
For more information, please consult the previous report, and the slides of the latest presentation at EuroBSDCon2026’s DevSummit.

Sponsor: The FreeBSD Foundation

---

### Syscall filtering for truss(1)

truss(1) traces the system calls a process makes.
Until this quarter it reported every call, which for anything larger than a toy program buries the calls of interest.

HEAD now accepts `-t` with a comma-separated expression naming the system calls to report.
The option letter is the one System V Release 4 and SunOS `truss` use for this.
A term may be a system call name, an fnmatch(3) glob (`readlink*`), a system call number in the traced process’s ABI, or `@group` for a family of related calls.
A leading `!` excludes what that one term matches and applies to no other term — unlike SVR4 `truss` and Linux `strace`, where `!` is sticky for the rest of the list.
Terms apply in order; the last match wins.
`truss -t` with no expression lists the groups and exits.

Groups are themselves `-t` expressions, so they compose without a second language.
`@desc` is built from `@read` and `@write` rather than repeating their members.
Member lists are patterns (`extattr_*file`_, `sctp`_`*`) rather than frozen name lists, so a later system call that follows the same naming convention joins the right group without a source change here.

Thirteen groups ship to start: `@all`, `@creds`, `@desc`, `@file`, `@ipc`, `@memory`, `@net`, `@none`, `@proc`, `@read`, `@signal`, `@time`, and `@write`.
They are not a clone of Linux `` strace’s `% `` classes: `@read` and `@write` split descriptor data-in from data-out, and `@time` covers clocks, timers, and sleeping rather than clocks alone.

Show only the file and network activity of a command:

```
truss -t @file,@net fetch https://www.freebsd.org/
```

Show everything a command does except its memory management:

```
truss -t '!@memory' make buildworld
```

Show the descriptor activity of a running process apart from the data transfers themselves:

```
truss -t '@desc,!@read,!@write' -p 34
```

```
truss -c -t 'readlink*' /bin/ls
```

A system call excluded by `-t` is not decoded, so the filter also skips the cost of formatting arguments that would never be printed, and it is left out of the `-c` summary.
Without `-t`, behaviour is unchanged.

The work is in HEAD as of af25f2476230, with an MFC planned after two weeks.
Thanks to Robert Clausecker for review, and to Alexander Ziaee for the man page pass.

If a call you care about is in the wrong group, or a group you would use is missing, please write.

---

### sysconf(8) completes the configuration trinity

sysctl(8) speaks to the running kernel.
sysrc(8) speaks to rc.conf(5).
This quarter the set became three, and the new tool is a pleasure to use.
sysconf(8) reads and writes the rest of the base configuration: loader.conf(5), sysctl.conf(5), and the make.conf(5) family (make.conf, src.conf, and src-env.conf).
The syntax is the one your fingers already know.
Given simply a name, reads back the value of the given name.
`name=value` writes, and the reply comes back in the familiar line: `name: old → new`.

The next boot setting fits on one line:

```
sysconf loader zfs_load
sysconf loader zfs_load="YES"
```

```
sysconf sysctl kern.maxfiles=65536
```

```
sysconf loader kernels+=kernel_test
```

```
sysconf make CFLAGS+=-DDEBUG
sysconf src -s WITHOUT_LLDB
```

rc.conf(5) keeps the tool that already does it best.
`sysconf rc sshd_enable=YES` hands every argument after `rc` straight to sysrc(8).
One front door, and the right specialist behind it.

Under the utility is bsdconf(3), the figpar engine brought forward as one reader and one writer, co-authored with Faraz Vahedi.
Each file family is a small descriptor: the keyword, the files, and the quoting rules of the program that will actually read them.
Loader values are written quoted, because that is what the boot loader accepts.
Sysctl values are quoted only when the round trip needs it.
The make family keeps its real operators (`+=`, `?=`, `:=`, `!=`) and the empty `WITH_` / `WITHOUT_` assignment, because for those knobs presence is the setting.
You name the format with the target.
`-f` names the path, so a loader-formatted file staged anywhere is still a loader file, and a `generic` target covers a file that matches no built-in.

Where the boot reads several files, sysconf reads those same files, in that same order.
The loader target starts where the loader starts, at /boot/defaults/loader.conf, and follows `loader_conf_files`, `loader_conf_dirs`, and `local_loader_conf_files`, including a layout that points those lists somewhere else.
The value you read is the value that takes effect.
The value you write is stored where it will still take effect on the next boot.
A removal clears every file that lists the directive, so that an earlier setting does not simply get unmasked.
The same command lists the files and dumps the effective set:

```
sysconf loader -l
sysconf loader -a
```

`-d` reports the descriptions carried in the defaults file.
`-A` widens a dump so directives still at their default are part of the picture.

A write replaces the file whole.
The new text goes to a temporary in the same directory, is fsynced, and is renamed over the original, with mode and ownership preserved.
If the machine stops halfway, the previous file is the one still on disk.
Read-only use, a `-c` check included, runs inside a capsicum(4) sandbox: the files are opened, every other capability is dropped, and only then is a line parsed.

The sysctl target asks the running kernel before it stores anything.
An unknown OID, a read-only OID, a loader-only tunable, or a value outside the type’s range is reported and skipped, and a loader-only tunable is pointed at the loader target, where a boot setting belongs.
Every other assignment in the same command still applies.
On make and src, `WITH_foo=no` is written and you are told at once to use `WITHOUT_foo=1` instead.
That is the advice in share/mk/bsd.mkopt.mk, delivered at the keyboard, and repeated on a later read with the file and line so an old `WITH_*=no` stays in view.

`-j` and `-R` aim the same sentences at a jail or another root.

The introduction is in HEAD as of 3fe5961a0b70 (D58066), and sysconf(8) makes its first release in FreeBSD 16.0.
It has already grown since that commit.
A unique prefix of a target is enough (`lo` is loader, `sy` is sysctl, `sr` is src), and a poudriere target carries the same verbs to poudriere.conf and the make overlays under poudriere.d.

Thanks to Robert Clausecker and Faraz Vahedi for review, and to Alexander Ziaee for the release notes.

Try it on HEAD against a file you usually open by hand.
If a format you live in is missing, please write.
The descriptor layer is how the next one joins, and it would be good to hear which file you want next.

---

### CUSE Improvements

At the end of this quarter, I started working on improving cuse(3).
Apart from minor fixes and refactors, I fixed known hangs in the kernel module during I/O (872c36cb6f2d) and module hot-unload (d38ef1aca969).

You can also follow the development process on the FreeBSD Foundation’s status-updates repository, where I post weekly reports.

Sponsor: The FreeBSD Foundation

---

### ext2fs user space tools

The goal of this project is to implement tools for managing ext2fs filesystems in base FreeBSD.

Sponsor: The FreeBSD Foundation

---

## Kernel

Updates to kernel subsystems/features, driver support, filesystems, and more.

---

### Boot Loader Improvements

Work this quarter expanded the boot loader’s support for compressed images, memory disks, and HTTP network booting, with an eye to both iPXE integration, and loader.efi(8) completeness.
It also introduced a QEMU-based test framework covering many of FreeBSD’s boot combinations.

The loader can now read files compressed with XZ or Zstandard in the same way that it already handled gzip and bzip2 files.
XZ support is enabled by default in the BIOS and EFI loaders, including support for compressed memory-disk images such as FreeBSD installation images.
Zstandard support is available as a build option.

Memory-disk handling was generalized so that the loader can create an `md` device dynamically.
This provides a fallback on systems whose UEFI firmware does not implement the RamDisk protocol, a situation found on some smaller and embedded systems.
The resulting memory disk is exported to the kernel and can contain both the kernel and the root filesystem.
Downloaded memory-disk images now use the correct UEFI memory type, and downloads can be interrupted with Escape.
This replaces the need to use the memdisk_uefi.efi third-party add-in that people needed previously for iPXE integration.
Now loader.efi can also download images via iPXE’s download services, requiring only basic networking DXE modules in the UEFI firmware image.

EFI HTTP support previously depended on the firmware having loaded loader.efi through UEFI HTTP Boot and was restricted to the server selected by the firmware.
The loader now accepts arbitrary `http[N]://host[:port]/path` device specifications.
These can be used as `rootdev`, in loader.conf, or interactively, regardless of how the loader itself was started.
The implementation can either reuse an existing loader network configuration or ask the firmware network stack to perform DHCP.

The DHCP client now requests a FreeBSD vendor option containing the URL of an initial memory-disk image.
With this option, a machine can start loader.efi directly over the network, discover a detached root image through DHCP, retrieve that image over HTTP, and boot from it.
Care was taken to transfer ownership of the network interface between the loader’s native network stack and the UEFI HTTP stack.
This is necessary because each stack needs different access to the firmware’s network protocols.

A new tools/boot/boot-test.sh framework uses QEMU to test booting across aarch64, amd64, armv7, powerpc64, powerpc64le, and riscv64.
It exercises the applicable BIOS, UEFI, OpenFirmware, and PReP environments with CD, MBR, GPT, network, and memory-disk configurations, as well as the Lua, Forth, and simple loaders.
HTTP network-boot and gptboot.efi chain-boot tests were added later in the quarter.
The framework is not yet an installed test because it builds and tests several target architectures from one host.

The chain-boot tests accompanied a fix for systems that use gptboot.efi to select between A/B system partitions.
After being chain-loaded, loader.efi could skip the selected partition and boot the other system partition instead.
The selected partition is now tried first, while the normal search of sibling partitions remains as a fallback.
A separate loader change that interfered with some ZFS chain-boot configurations was reverted.

Other work added a loader.kboot(8) manual page, build knobs for omitting the x86 BIOS and userboot loaders from UEFI-only systems, and defensive checks for firmware that advertises unusable graphics output protocols.

Sponsor: Netflix

---

### Suspend/Resume Improvements

Suspend-to-idle and support for S0ix sleep is in the process of being added to FreeBSD.

This will allow modern Intel and AMD laptops, some of which do not support ACPI S3 sleep, to enter low power states to increase battery life.

amdsmu(4) now proactively diagnoses S0i3 entry after resuming from suspend-to-idle with a new eventhandler.
If S0i3 was not entered, it will print the IP blocks that were blocking entry to dmesg, along with hints on how to resolve them.

The acpi_spmc(4) driver now checks Intel and AMD constraint packages.
Malformed constraints are skipped instead of crashing.

Various improvements were made to the thunderbolt(4) driver: support for writing to router config space, controller resets, and a CRC accounting fix for config write messages.
Thunderbolt controllers can now be resumed (in review), which allows multiple suspend-resume cycles without needing to reload the kernel module.

At this point modern standby works reliably on target laptops and most panics have been ironed out.
The primary issue being worked on is GPE events generated while the machine is suspended — such as plugging or unplugging AC power — causing panics.

Sponsor: The FreeBSD Foundation

---

### Audio Stack Improvements

I have been working on the audio stack since 2024Q1.
Below is a list of the previous status reports:

- Ongoing locking refactor in sound(4).
- Initial refactor of sound(4)'s mixer code.
- snd_uaudio(4) bug fixes, and better device support.
- As always, more incremental sound(4), device drivers, and virtual_oss(8) cleanups, fixes and improvements.

You can also follow the development process on the FreeBSD Foundation’s status-updates repository, where I post weekly reports.

Sponsor: The FreeBSD Foundation

---

### Adopt -fbounds-safety in the FreeBSD Kernel TCP/IP Stack

Clang’s -fbounds-safety lets C code state a buffer’s length, as in `__counted_by(len)`.
The compiler then checks accesses through that pointer.
An out-of-bounds access traps instead of corrupting memory.
The TCP/IP stack parses untrusted network input, so it is a good place to start.
This project adds the macros and build support, then converts TCP files one at a time.
Without the flag the annotations expand to nothing.
The tree still builds with the base system compiler and with GCC.

#### This quarter

- External toolchain builds GENERIC on amd64, recipe on the wiki.
- Macros, build knob and soft traps posted, four reviews accepted.
- `tcp_ecn.c` runs checked, kernel boots and passes netinet tests.
- mbuf accessor RFC on arch@ and net@, discussion ongoing.

Sponsor: The FreeBSD Foundation

---

### Netlink Support for Tunnel Interfaces

Following the geneve(4) work, I have been migrating our other tunnel drivers to the new if_clone KPI and adding netlink support for them, both in kernel and in ifconfig(8).
They are now available on CURRENT.

So far, I have added the support for:

- Netlink support for gif(4) with tests.
  (D57666)
- Netlink support for gre(4) with a regression test.
  (D55366)
- IFLAF_GROUP, a FreeBSD-specific netlink attribute to carry the interface groups, since IFLA_GROUP only works with a single numeric group id.
  ifconfig(8) now reads the interface groups from it.
  (D58643)

While here, I fixed the following bugs:

- Races during gre(4) module initialization and destruction of cloned interfaces in jails.
  (D57669)
- Panic in vxlan(4) when unused drvspec values are passed.
  (D58552)
- Wrong interface name translation in Linux netlink dumps under linux(4), and mapping of more interface types to ARPHRD.
  (D59595)

Ongoing work:

- Full support for GRE key.
  (D59849)

---

### Netlink Payload Decoding Infrastructure for FreeBSD Tracing Tools

PF uses Netlink to communicate between userland tools and the kernel, but before this work, truss(1) could not meaningfully decode the payloads of PF Netlink messages and would instead display much of the message as raw data.

This project adds a reusable Netlink payload decoding infrastructure to `libsysdecode` and integrates it with truss(1), allowing structured decoding of Netlink messages rather than exposing only their raw contents.

The core of the infrastructure is a generic attribute decoder based on decoder tables.
The infrastructure supports decoding different attribute types, including integer values, strings, booleans, and nested attributes.
Netlink commands can then provide their own decoder tables describing the attributes they contain, without requiring a separate decoding mechanism for each command.

The infrastructure has been used to add decoding for several PF Netlink commands, including `PFNL_CMD_KILLSTATES`, `PFNL_CMD_GETRULES`, and `PFNL_CMD_GET_LIMIT`.

For example, a PF Netlink message that previously appeared largely as an opaque buffer:

```
recvmsg(3,{0x90d83dda940,12,[{"@\^A\0\0\^P\0\^C\^C\^A\0\0\0\0\0"...,65536}],1,{},0,0},0) = 1060 (0x424)
```

With the new decoding infrastructure, truss(1) can decode the Netlink message and PF payload into meaningful fields, for example:

```
sendto(5,netlink{flags=NLM_F_REQUEST|NLM_F_ACK|NLM_F_ROOT|NLM_F_MATCH,seq=8,pid=0,len=92,type=18,pfctl={cmd=PFNL_CMD_GETSTATES{ifname=,proto=0,af=0,filter_addr=::,filter_mask=::,include_rule=FALSE}}},92,0,NULL,0) = 92 (0x5c)
```

truss(1) was also extended to track the protocol associated with `AF_NETLINK` sockets so that messages can be passed to the appropriate decoder.
Netlink message flags are decoded as combinations of `NLM_F_*` flags, while unknown bits are preserved.

The work in this quarter established the infrastructure needed to continue adding PF Netlink payload decoders without duplicating parsing logic for each command.

Sponsor: Google LLC (GSoC 2026)

---

### LinuxKPI 802.11 and Native Wireless Update

This report focuses on the efforts using permissively licensed Linux wireless drivers, mostly unmodified, on FreeBSD, as well as preparing the native net80211 stack for support of newer standards.

#### Mediatek mt76 support

A call for testing was put out for mt7921 based PCIe chipsets (MT7920E; MT7921E, also known as AMD RZ608; MT7922E ,also known as AMD RZ616).
This is based on ongoing reviews, mostly to replace an old shortcut in LinuxKPI for struct page.
Despite great interest in the driver the previous years we have not had a lot of feedback.

Work to support further mt76 chipsets will continue.

#### Realtek rtw8x support

Thanks to the debugging of users the situation has slightly improved.
It is expected that Linux v7.3 has a lot of bug fixes in the drivers but due to the timeline of Linux and FreeBSD release schedules may only hit main once again.
Further issues have to worked on and fixed still.

#### LinuxKPI USB support

In previous reports we have reported that this was blocked on a compiler option.
During Q3 we found a way which can limit the scope to just LinuxKPI USB drivers.
There is ongoing work to simplify the build framework for this.
While there are rough edges still, especially around teardown and unplug we hope to put out a stack of changes for review or a tree for testing during October.

#### Native net80211 updates (tech debt)

Initial work to remove workarounds from LinuxKPI and fix net80211 are ongoing.

#### Espressif Systems ESP32-E22 support

The current upstream driver from Espressif Systems on Github v0.6 has been ported to FreeBSD.
Initial changes to fix compiler warnings were submitted back as pull requests.
The driver is currently awaiting a vendor import and to be followed by an unifdef within the FreeBSD tree as upstream supports a wide range of Linux versions.
Special thanks go to Espressif Systems for providing me with two E22 sample cards in order to test the port.

Sponsor: The FreeBSD Foundation
Sponsor: Espressif Systems (Hardware)

---

### Series of IPv6 Improvements

Since the last report, I have continued refreshing our IPv6 stack and implementing pending RFCs, and the results are now available on CURRENT.

So far, I have added the support for:

- RFC 8925: IPv6-Only Preferred Option in dhclient(8).
  When the option is received and IPv6 connectivity is available, dhclient stops the DHCPv4 configuration, releases the previous lease and waits for the duration specified by the server before restarting discovery.
  Netlink is used to check for IPv6 connectivity.
  (D56637)
- RFC 6275 (Section 8.3) and RFC 9762 (Section 7.1): The R-bit and P-bit of the Prefix Information option are now exposed to userland for future implementations.
  (D56207)

I also fixed a few bugs in the stack:

- RFC 8981 temporary addresses were regenerated for detached prefixes.
  (D60051)
- The outgoing interface index of pktinfo was checked against the wrong interface in the route cache, per RFC 3542 Section 6.
  (D58544)
- Wrong RA flag inconsistency messages in rtadvd(8).
  (D58672)

Ongoing work:

- RFC 4429: Add support for Optimistic DAD.
  (D55229)

I want to especially thank Marek Zarychta for his tests and reviews.

---

### Series of Routing Stack Improvements

For the past 3 months, I have worked on improving the resilience of our routing stack, and the results are now available on CURRENT.

Previously, the reachability of every nexthop was checked against the interface link status for each packet.
Now, nexthops subscribe to interface link events and only the reachability flag of the final nexthop is checked in the forwarding path.
When a nexthop becomes unreachable, the nexthop groups that contain it are recompiled immediately by replacing the unreachable nexthops with the reachable ones.
Once the link comes back, the nexthops return to their normal slots in the nexthop group.
This means a multipath route keeps forwarding traffic when one of its links goes down, without deleting the route.
I am really proud of this one.

So far, I have added the support for:

- Subscription of nexthops to interface link events.
  (D57375)
- Replacement of unreachable nexthops in nexthop groups.
  (D57389)
- RTA_PREFSRC in netlink and the prefsrc option in route(8), to select the source address of outgoing packets even when it is configured on another interface.
  This is frequently used on unnumbered interfaces and L3 multi-homed hosts.
  (D58294)
- FIB-aware ifa lookups via ifa_ifwithaddr_fib(), and used it in route installation, source address selection and ICMP redirect verification.
  (D58305)
- Nexthop statistics in netstat(1) with the -os flag.
  (D58538)
- A new nhop(9) manual to replace the outdated nexthop information in rtentry(9).
  (D58564)

I also fixed a couple of bugs in fib_algo:

- Nexthop index collision across families, which affected IPv4 routes with IPv6 nexthops.
  (D59552)
- Leak of radix_masks in the radix_lockless algorithm.
  (D59112)

---

### BPF/ifnet Contract Hardening: D59140

#### Description

During Q3 2026, a review of the `bpf_movein()` path in sys/net/bpf.c was conducted following an observed failure when writing to a BPF descriptor on `lo0` (FreeBSD 14.4-RELEASE-p8).

The initial observation was a write(2) returning `EAFNOSUPPORT` when sending a packet through a BPF descriptor bound to `lo0` (DLT_NULL).
The original attribution — missing `sa_len` initialization in `if_output` drivers — was not sustained after independent review by Gleb Smirnoff.

Review established that the reproducer violated the DLT_NULL contract: a write(2) on a BPF descriptor must prepend a 32-bit word in host byte order containing the address family.
The `sa_len` check proposed in the individual drivers (if_disc.c, if_gif.c, if_loop.c, if_me.c, if_tuntap.c) is not required because the existing BPF/ifnet interface contract is already defined at the BPF boundary in `bpf_movein()`.

Following that review, D59140 was updated to add a defensive assertion in `bpf_movein()` per Gleb’s suggestion:

```
MPASS(hlen <= sizeof(sockp->sa_data));
```

This makes the existing BPF/ifnet contract explicit through a defensive assertion at the point where the contract is consumed.
The assertion protects the `sa_data` bounds invariant at the point where the computed header length is consumed.

#### Work Completed

- Identified and reproduced `EAFNOSUPPORT` on `lo0` with BPF write(2) on FreeBSD 14.4-RELEASE-p8.
- Submitted D59140 to Phabricator with initial fix targeting five `if_output` drivers.
- Received review from Gleb Smirnoff identifying the reproducer defect: missing 32-bit DLT_NULL address-family header in the packet.
- Corrected the reproducer and verified locally on FreeBSD 14.5-RELEASE.
- Updated D59140 to replace the driver-level checks with a single `MPASS` assertion in `bpf_movein()` (Diff 186596).
- Updated Summary and Test Plan in D59140 to document the complete investigation history: observed failure → initial attribution → independent falsification → corrected reproducer → local verification → upstream hardening proposal.

#### Work in Progress

- D59140 (Diff 186596) is under upstream review.

#### Open Tasks

- Await upstream review and disposition of Diff 186596.

---

### Storage Discovery and Diagnostics Improvements

Several changes this quarter made storage-device discovery easier to observe and diagnose, particularly during boot.

The CAM DTrace provider gained probes for peripheral I/O errors, error recovery, and peripheral invalidation.
Additional probes report when CAM holds or releases the boot process and when a new bus is registered.
Together these probes cover much more of the path from initial bus discovery through the creation of disk peripherals.
They can also be used with DTrace anonymous tracing to investigate problems that happen before the system reaches multi-user operation.
The new probes are documented in dtrace_cam(4).

CAM now sends a devctl(4) notification when a peripheral is invalidated.
The notification includes the device serial number when available, or its CAM path otherwise, so system-management software can identify the device that disappeared.
The common code used to construct CAM notifications was factored out to support this and future event types.

Two fixes improved the handling of disks that fail during probing.
CAM now stops probing after a peripheral has been invalidated instead of sending more commands to an abandoned device, where they could cause long timeouts and confusing errors.
A related condition for deciding when to invalidate a disk was corrected.
Errors reported for NVMe disks through the CAM `nda` peripheral now identify the command set, making command opcodes easier to interpret.

mpsutil(8) gained a `show discovery` command that prints the controller’s discovery tables.
This exposes the controller’s view of attached SAS devices and expanders and is useful when diagnosing devices that are missing or attached through an unexpected path.

Finally, nvmecontrol(8) received correctness fixes for Autonomous Power State Transition data.
Transition values are now encoded without intermediate integer overflow, and identify data reporting an excessive number of power states is handled with a bounds check rather than an assertion.

Sponsor: Netflix

---

### x86 splitlocks detection support

Most non-x86 platforms are relatively strict with regard to the proper alignment of the data types.
On the other hand, x86 ISA allows any alignment for the operands of integer scalar operations.

Still, there is an AC control bit in the processor flags register which causes alignment exception (fault) on unaligned operations.
Practically the bit is not too useful because most of the compilers generate code that relies on the freedom of the working unaligned access on x86.

Particularly interesting case of the unaligned access is when the disposition of the operand causes it to span two cache lines (which is impossible for naturally aligned data).
Normal (unlocked) operations cause so called torn reads and writes.
This effect become observable starting with Core2 Intel microarchitecture.

Even more interesting case is provided by the locked operations using the LOCK prefix on read-modify-write instruction with the mis-aligned data.
To satisfy ISA guarantees in this case, the CPU has to either take more than one cache line for exclusive ownership in MESI-like cache coherence protocol, or exercise so called bus lock ensuring global cache ownership.
Either option has very high cost and causes observable detrimental effects on other processes and virtual machines executing on the same physical host.

Since some time Intel provides a control for the lock operations that need to span more than one cache line (split locks).
Turning the control on causes split locks to generate the same #AC exception as done by the AC flag, but only for the split locks, instead of all unaligned accesses.

The feature is controlled by the platform MSR and is per-CPU global, which precludes making the MSR directly available to userspace.
The new sysarch(2) operation I386_SET_SPLITLOCK was developed that enables the control for the calling thread.
The control is part of the machine state maintained on the context switch.

The intent is mainly to assist in catching bugs where improperly alignment locking structures are created, unlike Linux, which uses the feature to artificially penalize such processes by slowing them down.
If the program code modifications are not possible, users and administrators can LD_PRELOAD a trivial shared object that turns the control on.

Sponsor: The FreeBSD Foundation

---

### Aquantia / Marvell aq(4) Device Driver

Aquantia (now Marvell) AQtion devices are multi-gigabit PCIe Ethernet controllers supporting speeds up to 10 Gb/s.
They are found on workstation and desktop motherboards, and add-in NICs.

Aquantia published a FreeBSD driver for its first-generation "Atlantic" controllers, but it was unmaintained for some time.
FreeBSD developers contributed some fixes to the vendor’s repository, but several pull requests were never addressed.
The driver was available in the ports collection as net/aquantia-atlantic-kmod, with some additional patches, but it was not part of the base system and lacked support for newer devices.

Ed Maste imported a snapshot of the vendor driver, applied patches from unmerged pull requests and the port, wrote an aq(4) man page, and connected it to the build.

Since then, Nick Price added support for the second-generation Atlantic 2 (AQC113) controllers, and has made extensive fixes and improvements throughout the driver.
These include enabling jumbo frames, software LRO, and suspend/resume; correcting RSS queue distribution and honouring the kernel RSS policy; expanding and fixing checksum and VLAN offloads and VLAN/multicast filtering, hardening the attach, detach, reset, interrupt and RX/TX paths; handling PHY thermal shutdown; and improving diagnostics and link-state reporting.

The driver is available in -CURRENT snapshot images, and has been MFC’d to stable/15 to be included in FreeBSD 15.2.

Sponsor: The FreeBSD Foundation (Ed’s work)

---

## Architectures

Updating platform-specific features and bringing in support for new hardware platforms.

---

### FreeBSD Driver Development for BananaPi R2 / R64 / R2 Pro

This project adds FreeBSD support for three Banana Pi router boards: the BPI-R2 (MediaTek MT7623, armv7), the BPI-R64 (MediaTek MT7622, arm64) and the BPI-R2 Pro (Rockchip RK3568, arm64).

#### BPI-R2 (MT7623) Introduction

The Banana Pi BPI-R2 is a MediaTek MT7623N-based router board (quad-core ARM Cortex-A7, up to 1.3 GHz) with 2 GB DDR3, 8 GB eMMC, 4x Gigabit LAN and 1x Gigabit WAN driven by the built-in MT7530 switch, two SATA ports, two USB 3.0 ports, a mini PCIe slot, HDMI output, MIPI DSI/CSI connectors and the usual UART, I2C, SPI, PWM and GPIO headers.
Because the MT7623 is an armv7 part, it is the only board of the three that is built from the 32-bit `GENERIC` kernel configuration.

#### Current State of FreeBSD Support BPI-R2

Implemented so far:

- Platform / machdep support — device map, early console, late init and SoC reset, plus the `SOC_MEDIATEK` kernel option and a DTB build for `mt7623n-bananapi-bpi-r2.dts`
- SMP startup for the four Cortex-A7 cores
- UART driver
- Clock management — shared MediaTek clock infrastructure (gates, muxes, fixed factors) used by the topckgen, infracfg, pericfg, hifsys, bdpsys, imgsys, vdecsys and audsys clock controllers
- PLL clocks (apmixedsys)
- System configuration registers (syscfg/syscon)
- Pinctrl
- GPIO

#### Development roadmap BPI-R2

Implement missing drivers:

- Storage controller (eMMC/SD/MMC)
- Ethernet (GMAC) and the MT7530 switch
- USB 3.0 (xHCI) and T-PHY
- SATA / AHCI
- PCIe
- Watchdog
- I2C
- SPI
- PWM

#### BPI-R64 Introduction

The Banana Pi BPI-R64 is a MediaTek MT7622-based development board (dual-core ARM Cortex-A53, ~1.35 GHz) featuring 4x Gigabit LAN, 1x Gigabit WAN, 802.11n 4x4 Wi-Fi, Bluetooth 5.0 and a range of peripheral interfaces (UART, SPI, I2C, GPIO, SATA, mini PCIe, eMMC and others).

#### Current State of FreeBSD Support BPI-R64

Implemented so far:

- UART driver
- Clock management (clocks)
- Pinctrl
- Storage controller (eMMC/SD/MMC)
- Ethernet driver for the MT7622 GMAC
- USB 3.0 (xHCI) driver
- T-PHY (USB and PCIe PHY)
- Watchdog driver
- RTC driver
- Random number generator driver
- PCIe configuration space driver (pciecfg)
- sysirq — the interrupt polarity controller
- PCIe — experimental
- Wi-Fi — experimental

#### Development roadmap BPI-R64

Implement missing drivers:

- SATA / AHCI, including SATA mode for the T-PHY
- GPIO
- I2C
- SPI
- PWM

Work in progress:

- Review and rework of the clock drivers
- MT7531 Ethernet switch

#### BPI-R2 Pro Introduction

The Banana Pi BPI-R2 Pro is the next generation smart router development
board, powered by a Rockchip RK3568 processor.

It carries 2 GB LPDDR4 memory and 16 GB eMMC storage, and offers two USB 3.0 ports, five Gigabit Ethernet ports, an M.2 Key-E and a mini PCIe slot, two MIPI DSI interfaces (one of which can be switched to LVDS in software), one MIPI CSI camera interface and one HDMI output.

#### Current State of FreeBSD Support BPI-R2 Pro

Implemented so far:

- UART driver
- Clock management (clocks)
- Pinctrl
- GPIO
- Storage controller (eMMC/SD/MMC)
- USB 3.0 (xHCI) driver
- Watchdog driver
- PCIe driver

#### Development roadmap BPI-R2 Pro

Implement missing drivers:

- HDMI
- MIPI DSI/CSI

Work in progress:

- AHCI / SATA
- PCIe

---

### ROCm Support on FreeBSD

ROCm is AMD’s compute platform, which is the set of libraries, drivers, and tooling used to program their AI accelerators, and/or GPUs.
On FreeBSD there are only a few ways to run compute workloads (AI/ML, graphics, and so on) on the GPU, and to my knowledge those are Vulkan and OpenGL.
Both are fine for graphics, and sometimes machine learning too, but a lot of workloads are just not well suited to them, and end up being done in ROCm or CUDA instead, since those give the developer a lot more control over how the task is actually executed.

So I have been slowly porting the ROCm toolchain over to FreeBSD, which would let the AI accelerator ecosystem run natively here.

Most of my time recently has been spent getting rocr-runtime working from my rocm-systems fork, whilst upstreaming the changes needed in the FreeBSD kernel.
Once the kernel side is done, I can merge the amdkfd code into drm-kmod (after a lot of cleaning up), and from there it is mostly a matter of time getting the remaining pieces of rocr-runtime running.

#### Work completed

- amdkfd driver

  - The amdkfd driver now compiles, links, and loads.
  - Ported the v11 platform files for certain AMDGPU generations.
  - `/dev/kfd` is now exposed, and interactable.
  - Cleaned up undefined symbols which are not used as of now.
- ROCm systems

  - Fixed initialisation issues.
  - Refactoring all changes before doing a large upstream push of code which can be upstreamed.
- FreeBSD kernel

  - The linux/util_macros.h` (D57465) has been committed to the kernel.
  - Added `jiffies64_to_msecs` (D58075) has been committed to the kernel.
  - Added `compat_ptr_ioctl` (D58076) has been committed to the kernel.
  - Added `tgid` to `task_struct` under LinuxKPI (D58228) has been committed to the kernel.
  - Various other LinuxKPI-related changes are still under review (D58207, D58222, D58845, D60275).

There have been about two pull requests accepted to rocm-systems, otherwise I am still working on the large one which merges in FreeBSD support.
That code has not been completed yet, so I have not opened it.

#### Work in progress

- Fixing initialisation issues in rocr-runtime, and working through whatever else shows up once it runs further.
- Getting the large rocm-systems pull request finished and opened upstream.
- Fixing issues with Sysfs within amdkfd.
  Still diagnosing issues, and figuring out what exactly the issue is.

#### Help needed

- Support for RDNA 1 and RDNA 2: I had commented/stubbed out all the structs and functions related to RDNA 1 and 2, because I do not have the cards, nor the time right now to test them properly.
  If you have the cards and the time to test them, please reach out and I can tell you exactly how to do it.

This work has been sponsored by The FreeBSD Foundation!
Thank you to the FreeBSD Foundation!!

Sponsor: The FreeBSD Foundation

---

## Cloud

Updating cloud-specific features and bringing in support for new cloud platforms.

---

### FreeBSD on EC2

FreeBSD is available on both amd64 (Intel and AMD) and arm64 (Graviton) EC2 instances.

A fix to ena(4) taskqueue NUMA binding has been applied, resulting in significant improvements in network throughput on c8gn.48xlarge systems starting with 14.5-RELEASE.

EC2 now supports automatically growing filesystems when EBS volumes are expanded; this is enabled by default in 16.0-CURRENT and will be available as a non-default option in 15.2-RELEASE.

The `ebsnvme` tool which ships in EC2 images now supports the "ebsnvme stats" command, compatible with Amazon Linux.

A new "desktop" flavour of AMI is now available for FreeBSD 15, which uses xrdp to expose a KDE environment.

---

## Documentation

Noteworthy changes in the documentation tree, manual pages, or new external books/documents.

---

### Documentation Engineering Team

The Documentation Engineering Team is responsible for defining and following up documentation goals for the committers in the Documentation Project.
The doceng team charter describes the duties and responsibilities of the Documentation Engineering Team in greater detail.

This quarter in the Documentation Project, in addition to routine maintenance, several projects have come to fruition or were underway:

- Dave Cottlehuber <dch@FreeBSD.org> added an OCI container chapter to the Handbook.
- Benedict Reuschling <bcr@FreeBSD.org> and Sergio Carlavilla Delgado <carlavilla@FreeBSD.org> refreshed the ZFS chapter of the Handbook.
- Danilo G. Baio <dbaio@FreeBSD.org> improved handbook examples to have a clickable copy button which omits the shell prompt.
- Danilo G. Baio <dbaio@FreeBSD.org> updated textproc/po4a, the translation toolchain, to version 0.74.
- Älven <alven@FreeBSD.org> updated textproc/groff, the GNU manual page toolchain, to version 1.24.2.
- Fernando Apesteguia <fernape@FreeBSD.org> updated www/gohugo, the website generator, to version 1.76.0.
- Wolfram Schneider <wosch@FreeBSD.org> updated man.FreeBSD.org, the oldest and largest manual pages archive on the internet.
- Alexander Ziaee <ziaee@FreeBSD.org> updated the guidelines for device driver manuals, updating all manuals to this format is underway.
- Alexander Ziaee <ziaee@FreeBSD.org> is improving manual page compatibility for the upcoming textproc/mandoc version 1.15.
- Vladlen Popolitov <vladlen@FreeBSD.org> and Sergio Carlavilla Delgado <carlavilla@FreeBSD.org> have invested considerable work in code-correctness for the Project website.
- Vladlen Popolitov <vladlen@FreeBSD.org> and Andrey Zakhvatov <andy@FreeBSD.org> have been hard at work keeping the Russian translation up to date.

This quarter, Vladlen Popolitov <vladlen@FreeBSD.org> was promoted to a doc commit bit.
No other commit bits have been granted or taken in for safekeeping during this quarter.

---

### The FreeBSD Russian Documentation Project

The FreeBSD Russian Documentation Project’s current goal is to provide up-to-date Russian translations of the most important parts of the FreeBSD documentation (FAQ, Handbook, website content).
It is essential to support Russian-speaking users with high-quality official technical materials and to increase the adoption of the operating system worldwide.
We hope this initiative will gain support within the Russian-speaking FreeBSD community and lead to an increase in translated materials.

During the last quarter:

- The project to translate FreeBSD man pages has moved beyond its initial stages: approximately 300 documents from Section 1 (General Commands) have been published in the russian/freebsd-man port (with man pages for versions 15.0 and above).
  Many thanks to Gleb Popov for preparing and publishing the port.
- For the FreeBSD 14.5 release, the complete set of release documentation (release notes, errata, etc.) has been translated into Russian in a timely manner alongside the English originals.
- 100% of the text in Weblate has been translated and synchronized with the English version (in August).
- The Russian language section of www.FreeBSD.org/ru has been kept fully translated and synchronized with the English version.
- Russian pages on the website and documentation have been validated by the HTML validator vnu, and all errors have been fixed.

Plan for the next quarter:

- Continue the ongoing efforts to translate FreeBSD man pages.

We would appreciate your assistance:

- Install the russian/freebsd-man port and use the Russian-language manual pages.
  It is available on all FreeBSD versions.
- Submit corrections and new translations as pull requests to the translation repository on GitHub.
- See CONTRIBUTING.md for details on how to contribute.

---

## Ports

Changes affecting the Ports Collection, whether sweeping changes that touch most of the tree, or individual ports themselves.

---

### FreshPorts: Translations

FreshPorts, and its sister site, FreshSource, have reported upon FreeBSD commits for over 25 years.
They cover all commits, but their primary focus is ports.

FreshPorts tracks the commits and extracts data from the port Makefiles to create a database of information useful to both port developers and port users.
For example, https://www.freshports.org/security/acme.sh/ shows the history of this port, back to its creation in May 2017.

Until now, the website was available only in English.

#### FreshPorts can now be translated

Nearly all of the website’s own text has been prepared for translation using gettext, including:

- the page header, sidebar, and footer
- the account pages, and the signup and password emails
- the commit, port, and category pages
- search and the port lists
- the watch list pages
- the FAQ and the other information pages

The language is chosen from the browser’s settings, and can be changed with a language picker at the bottom of every page.
Day and month names follow the chosen language too, so "Saturday, 3 Oct 2026" becomes "2026年10月3日星期六" in Chinese.
Port descriptions, commit messages, and ports framework terms such as `BROKEN` and `USES` come from the ports tree and remain in English.
The legal and privacy pages also remain in English, so the English text stays authoritative.

Two translations have already been contributed: Simplified Chinese by ykla, and Turkish by Yusuf Yaman.
Thank you to both.

#### This work is not in production yet

www.freshports.org remains English only for now.
The translations can be previewed on test.freshports.org: choose 简体中文 or Türkçe at the bottom of any page.

#### Help is wanted

There are about 1,180 strings to translate.
Each translation is a single `.po` file, so no knowledge of PHP is needed, and editors such as Poedit make the work straightforward.
To contribute, see the instructions at the link above and send a pull request:

- Translate FreshPorts into a new language.
- Help finish the Simplified Chinese and Turkish translations, which need the newest strings.
- Review existing translations and report mistranslations as GitHub issues.

Thank you to everyone who has helped so far.

---

### Brave Browser on FreeBSD: Status Report

#### Summary

A native FreeBSD port, www/brave, is available in the {repo}[FreeBSD-Ports overlay].
It builds Brave __1.94.120__, based on Chromium __152.0.7977.76__, for amd64 and aarch64.
The build uses only the release tarballs and the ports toolchain (LLVM 22, Rust, Node 24).
It does not use depot_tools, gclient, CIPD or siso, and it does not need the Linuxulator.

#### Status

- Native build on amd64 and aarch64.
- Shields filter lists.
- Port options for Widevine (via www/foreign-cdm), PipeWire, Qt6, CUPS, Kerberos, and ALSA, PulseAudio and sndio.

#### Open issues

- __Services key.__ Without it, component updates return 403, so there is no ad block catalog and no CRLSet.
  The port currently uses the same key that Arch ships.
- Leo, Brave Search and speech-to-text have no keys, so they do not work.
- The updater and remoting are disabled.
  Updates come through pkg.
- The Brave version is tied to the Chromium version in www/chromium.

---

### Dockerbox

Dockerbox is a virtualized Docker daemon.
Although the Docker daemon is not natively available on FreeBSD, Dockerbox runs it inside a Debian Bhyve virtual machine to provide access to it.

#### Status Updates

- Dockerbox now supports 2 kinds of underlaying file sharing for bind mounts: virtio-9p, NFS  
  Both ways share host paths into the dockerbox guest.  
  For paths on host, only paths shared into dockerbox can be bind mounted.
- Dockerbox now supports publishing port to a customized binding host IP  
  Before, only binding to `0.0.0.0` was supported.  
  This is because dockerbox, as a virtual machine guest, does not share host’s IP addresses.  
  Now binding only to selected IP on host is supported, with the help of dockerbox-broker.  
  Example usage: `docker run --label dockerbox.bind=192.168.88.100:8080 -p 8080:80 nginx`
- Dockerbox now supports customizable IP address and gateway
- sysutils/dockerbox-broker is now in the ports tree
- Dockerbox-broker now supports udp port forwarding

Sponsor: The FreeBSD Foundation

---

### KDE on FreeBSD

The KDE on FreeBSD project packages CMake, Qt, and software from the KDE Community, for the FreeBSD ports tree.
The software includes a full desktop environment called KDE Plasma (for both X11 and Wayland) and hundreds of applications that can be used on any FreeBSD machine.
The KDE team is part of desktop@, building the software stack to make FreeBSD beautiful and usable as a daily driver graphical desktop workstation.

#### KDE Stack

KDE Frameworks, Plasma, and Gear release happen very regularly.
KDE team usually lands these updates shortly after their upstream release.

- KDE Frameworks ports were updated to 6.31.0.
- KDE Plasma Desktop was updated to 6.7.5.
- KDE Gear was updated to 26.08.2.

Plasma 6.7 is the last release supporting X11 session.
Future KDE Plasma 6.8 release will be Wayland-exclusive, support for X11 applications will be fully entrusted to Xwayland.
See KDE blog post for details.

The x11/sddm port has got several fixes improving Wayland support.
SDDM can now start its greeter under KWin Wayland (commit)

#### Sunsetting Qt5 ports

Deprecated Qt5 is still used by approximately 340 ports.
During this quarter the www/qt5-webengine port for Qt5WebEngine has been removed, and most of its consumers have been upgraded to use Qt6.
KDE team encourages maintainers to migrate their Qt5 ports to Qt6 and KDE Frameworks 6 and to deprecate abandoned by upstream software.

---

### Improve OpenJDK on FreeBSD

The goal of this project is to improve OpenJDK support for FreeBSD/amd64 and FreeBSD/arm64.

Java is an important runtime environment for many high performance, critical enterprise systems.
Making sure Java based applications run correctly and efficiently on FreeBSD is important to ensure that FreeBSD will continue to be a viable and attractive platform for enterprises, as well as businesses and organizations of all sizes.

This quarter, a few rather big, invasive features have been merged upstream (JEP 401: Value Objects and JEP 539: Strict Field Initialization), meaning that it has been difficult to get reviews and acceptance for our changes in this period.
We have spent the time on fixing issues with the BSD port, as well as keeping it up to date with the upstream changes as they have appeared.

The following fixes/improvements have been done in this quarter:

- Various fixes and enhancements

  - Bug 296945: The `wxneeded` ELF flag is now set on the JDK binaries, allowing java to run on systems with W^X protection enabled.
  - Bug 294358: really build headless without installing Xorg libs
  - Removed `USE_LDCONFIG` from OpenJDK 8 and 11 ports.
    Fixes Bug 297282: java/openjdk25 - libjava.so does not find libjvm.so
  - Only return symbols that match the requested address for dladdr(3) on BSD.
    This also reverts the default visibility of libjvm symbols back to hidden to avoid exposing internal symbols.
    This should also make the library faster to load, and less resource hungry.
  - Fix debugd connect test on FreeBSD.
- Upstream BSD Port:

  - Submitted draft JEP for BSD port upstreaming effort.
- Ports:

  - New port for OpenJDK 27 released.
  - OpenJDK 26: Update to version 26.0.2
  - OpenJDK 25: Update to version 25.0.4
  - OpenJDK 21: Update to version 21.0.12
  - OpenJDK 17: Update to version 17.0.20
  - OpenJDK 11: Update to version 11.0.32

Sponsor: The FreeBSD Foundation

---

### FreeBSD HPC Ports Modernization

This report continues the FreeBSD HPC Ports Modernization initiative, which aims to make FreeBSD a practical and maintainable platform for modern high-performance computing (HPC) software stacks.
Previous quarters focused on bringing the Slurm, PMIx, PRRTE and UCX stack up to date and filling gaps in the surrounding ecosystem.
This quarter’s work centered on three things: keeping the scheduler and communication libraries current (including security fixes), deepening FreeBSD-specific runtime support in UCX and enabling the Open MPI/UCX combination, and taking the first FreeBSD-native Slurm features upstream to SchedMD.

#### Work completed

- Updated sysutils/slurm-wlm three times, from 26.05.1 to 26.05.2 and then to 26.05.4, tracking upstream releases.
  The 26.05.4 update also addresses seven CVEs.
  Thanks to the configure-time HDF5 probe merged upstream last quarter, the obsolete downstream HDF5 patches could be removed and the downstream `patch-configure` was substantially reduced.
  The remaining FreeBSD conmgr patch was rebased and a missing `<signal.h>` include was added so the test suite builds on FreeBSD.
- Enabled `slurmrestd` in sysutils/slurm-wlm.
  It had been disabled because it was believed not to build on FreeBSD, but with current Slurm it builds without any additional portability patches.
  The port now ships `slurmrestd` together with the REST/OpenAPI plugins.
- Updated net/ucx from 1.20.1 to 1.22.0.
  Earlier in the quarter the port gained a guard around the Linux-specific netlink implementation, and `ucx_vfs` support was improved for FreeBSD by replacing `fusermount3` with `mount_fusefs`/`umount`, using FreeBSD-compatible FUSE capability detection and fixing UNIX socket ancillary data handling (`SCM_RIGHTS` and peer credentials).
  A follow-up fix for the VFS inotify watch was contributed by Laurent Chardon.
- Introduced a UCX option in net/openmpi, allowing Open MPI to be built against net/ucx on FreeBSD (work by Laurent Chardon, based on testing and reports from this initiative).
  This also fixed an OMPIO `sharedfp/sm` crash.
- Updated benchmarks/py-reframe-hpc twice, from 4.10.0 to 4.10.2 and then to 4.10.3.
- Updated sysutils/py-clustershell from 1.9.3 to 1.10.1, including fixes for unportable tests.
- Submitted `proctrack/freebsd-reaper` to SchedMD, a new Slurm process-tracking plugin built on FreeBSD’s `procctl()` process-reaper APIs.
  The step daemon acquires reaper status, tracks descendants across process-group changes and nested reapers, and signals the tracked process tree during cleanup.
  On a FreeBSD test node it cleaned up orphaned, SIGTERM-resistant and nested children like `proctrack/pgid`, and additionally handled `setsid`, `setpgid`, double-fork and nested-daemon escapes, which `proctrack/pgid` does not.
  A zombie regression was retested and the node returned to IDLE without timing out or draining.
- Submitted `%o` support for `Include` filenames in Slurm configuration to SchedMD.
  `Include slurm-%o.conf` selects `slurm-FreeBSD.conf` on FreeBSD and `slurm-Linux.conf` on Linux, so a heterogeneous configless cluster can keep one authoritative configuration on `slurmctld`.
  This has been running on a mixed FreeBSD/Fedora cluster using the corresponding port patches.

#### Work in progress

- Addressing review feedback on the open UCX (UCS/SYS portability for non-Linux platforms) and mpifileutils (Linux-only API guards) upstream pull requests, to shrink the local patchsets of the ports further.
- Following up with SchedMD on the `proctrack/freebsd-reaper` and configless `%o` Include submissions.

#### Future plans

- Land the outstanding upstream pull requests and keep identifying FreeBSD portability issues to fix upstream rather than patch locally.
- Carry the Slurm patches accepted by SchedMD into the port and drop the corresponding downstream changes.
- Continue tracking upstream Slurm, UCX, Open MPI, PMIx and PRRTE releases closely.
- Document a reference Slurm + Open MPI + PMIx + PRRTE + UCX deployment on FreeBSD, including a mixed FreeBSD/Linux configless setup, to lower the barrier for new sites.

---

### Improve libvirt support for bhyve hypervisor

#### Completed work

- libvirt/bhyve driver:

  - Added support for VLAN configuration, VLAN filtering, and isolated bridge ports on FreeBSD.
  - Added boot order configuration for disk devices.
  - Implemented several new APIs: domain renaming, lifecycle management, getting guest info using the QEMU Guest Agent, and setting QEMU Guest Agent response timeout.
  - Added serial number configuration for SATA disks and NVMe controllers, as well as EUI-64 configuration for NVMe disks.
  - Fixed several issues related to transient and persistent domain handling, monitor events, startup error reporting, and TAP device cleanup.
- Added `guest-get-fsinfo` support for FreeBSD to the QEMU Guest Agent.
- Extended libvirt-tck coverage for libvirt/bhyve.
- Work in progress on unprivileged `bhyve:///session` support.

#### Plans for the next quarter

- Complete unprivileged `bhyve:///session` support.
- Add support for TPM devices.
- Complete suspend/resume support.
- Continue implementing features based on the QEMU Guest Agent.
- Continue extending CI and cover the new guest-agent-based features with new tests.

Sponsor: The FreeBSD Foundation

---
