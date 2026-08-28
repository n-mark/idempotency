{{- define "arch.namespace" -}}
{{- default .Values.global.namespace .Release.Namespace -}}
{{- end -}}

{{- define "arch.host" -}}
{{- .Values.global.host -}}
{{- end -}}

{{- define "arch.image" -}}
{{- $image := index .Values.image .serviceName -}}
{{- printf "%s:%s" $image.repository $image.tag -}}
{{- end -}}