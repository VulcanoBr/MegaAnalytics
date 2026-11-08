module ImportBatchesHelper
  STATUS_CLASSES = {
    "pending" => "bg-gray-100 text-gray-700",
    "processing" => "bg-blue-100 text-blue-700",
    "succeeded" => "bg-emerald-100 text-emerald-700",
    "failed" => "bg-red-100 text-red-700"
  }.freeze

  VALIDATION_CLASSES = {
    "passed" => "bg-emerald-100 text-emerald-700",
    "warning" => "bg-amber-100 text-amber-700",
    "failed" => "bg-red-100 text-red-700"
  }.freeze

  def status_badge(batch)
    badge(t("import_batches.status.#{batch.status}"), STATUS_CLASSES[batch.status])
  end

  def validation_badge(batch)
    return content_tag(:span, "—", class: "text-gray-400") if batch.validation_result.blank?

    badge(t("import_batches.validation.#{batch.validation_result}"), VALIDATION_CLASSES[batch.validation_result])
  end

  private

  def badge(text, classes)
    content_tag(:span, text, class: "inline-block rounded-full px-2.5 py-0.5 text-xs font-medium #{classes}")
  end
end
