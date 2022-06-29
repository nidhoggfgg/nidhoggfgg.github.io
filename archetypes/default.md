---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
draft: true
lastmod: {{ .Date | time.Format "2006-01-02" }}
slug: {{ substr (md5 (printf "%s%s" .Date (replace .TranslationBaseName "-" " " | title))) 0 8 }}
---
