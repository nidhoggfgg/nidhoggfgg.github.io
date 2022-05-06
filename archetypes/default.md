---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
draft: false
slug: {{ substr (md5 (printf "%s%s" .Date (replace .TranslationBaseName "-" " " | title))) 0 8 }}
---
