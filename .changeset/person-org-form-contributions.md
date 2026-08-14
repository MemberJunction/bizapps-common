---
"@mj-biz-apps/common-ng": patch
---

Stop overriding generated People and Organization forms. Address, contact-method, relationship, and org-hierarchy widgets register as BaseFormPanel contributions. Identity heroes (`contributionKey: 'header'`) replace the Personal Identity / Organization Identity field panels so verticals can last-win the same key (Orders adds stats without forking the form).
