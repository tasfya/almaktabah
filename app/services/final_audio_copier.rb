class FinalAudioCopier
  include ArabicHelper

  FINAL_AUDIO_SERVICE_NAME = :public_media_aws
  MAX_FINAL_AUDIO_KEY_COLLISION_RETRIES = 5

  def initialize(record, force: false)
    @record = record
    @force = force
  end

  def call
    return false unless copy_allowed?

    purge_final_audio if force? && final_audio.attached?

    source_blob = optimized_audio.blob
    target_key = final_audio_target_key(source_blob)
    key = ensure_final_audio_key_unique(target_key)
    content_type = final_audio_content_type(source_blob)

    source_blob.open do |file|
      file.rewind
      new_blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: final_audio_filename(source_blob, target_key),
        content_type: content_type,
        key: key,
        service_name: final_audio_service_name
      )

      final_audio.attach(new_blob)
    end

    true
  end

  private

  attr_reader :record, :force

  def force?
    force
  end

  def copy_allowed?
    return false unless optimized_audio_attached?
    return false unless record.respond_to?(:final_audio)
    return false if final_audio.attached? && !force?

    true
  end

  def optimized_audio_attached?
    record.respond_to?(:optimized_audio) && record.optimized_audio.attached?
  end

  def optimized_audio
    record.optimized_audio
  end

  def final_audio
    record.final_audio
  end

  def purge_final_audio
    final_audio.purge_later
  end

  def final_audio_service_name
    FINAL_AUDIO_SERVICE_NAME
  end

  def final_audio_content_type(source_blob)
    source_blob.content_type.presence || "audio/mpeg"
  end

  def final_audio_target_key(source_blob)
    key = if record.respond_to?(:generate_optimize_audio_bucket_key)
      record.generate_optimize_audio_bucket_key
    end

    latinize_audio_key(key.presence || source_blob.key)
  end

  def final_audio_filename(source_blob, target_key)
    filename = latinize_audio_segment(File.basename(normalize_utf8(target_key)))
    filename.presence || latinize_audio_segment(source_blob.filename.to_s)
  end

  def ensure_final_audio_key_unique(source_key)
    source_key = normalize_utf8(source_key)
    return source_key unless ActiveStorage::Blob.where(key: source_key).exists?

    ext = File.extname(source_key)
    base = File.basename(source_key, ext)
    dir = File.dirname(source_key)
    1.upto(MAX_FINAL_AUDIO_KEY_COLLISION_RETRIES) do |counter|
      filename = "#{base}-#{counter}#{ext}"
      key = dir == "." ? filename : "#{dir}/#{filename}"
      return key unless ActiveStorage::Blob.where(key: key).exists?
    end

    raise "Unable to allocate unique final audio key for #{record.class.name}##{record.id}"
  end

  def normalize_utf8(value)
    value.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
  end

  def latinize_audio_key(value)
    normalized = normalize_utf8(value)
    normalized.split("/").map { |segment| latinize_audio_segment(segment) }.join("/")
  end

  def latinize_audio_segment(value)
    return "" if value.blank?

    normalized = normalize_utf8(value)
    ext = File.extname(normalized)
    base = ext.empty? ? normalized : File.basename(normalized, ext)
    latin_base = transliterate_arabic(base).parameterize
    latin_base = "file" if latin_base.blank?
    ext.present? ? "#{latin_base}#{ext}" : latin_base
  end
end
