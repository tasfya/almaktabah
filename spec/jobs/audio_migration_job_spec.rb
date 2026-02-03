require 'rails_helper'

RSpec.describe AudioMigrationJob, type: :job do
  let(:audio_file) { fixture_file_upload(Rails.root.join('spec', 'files', 'audio.mp3'), 'audio/mpeg') }

  describe '#perform' do
    context 'with Fatwa' do
      let(:scholar) { create(:scholar, full_name: 'الشيخ محمد') }
      let(:fatwa) { create(:fatwa, title: 'حكم الصيام', category: 'صيام', scholar: scholar) }

      before do
        fatwa.optimized_audio.attach(audio_file)
      end

      it 'migrates optimized_audio to final_audio' do
        expect {
          described_class.perform_now('Fatwa', fatwa.id)
        }.to change { fatwa.reload.final_audio.attached? }.from(false).to(true)
      end

      it 'logs success message' do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info).with(/Successfully migrated Fatwa##{fatwa.id}/)
        described_class.perform_now('Fatwa', fatwa.id)
      end

      context 'when final_audio already exists' do
        before do
          fatwa.final_audio.attach(audio_file)
        end

        it 'skips migration' do
          expect(Rails.logger).to receive(:info).with(/already has final_audio/)
          described_class.perform_now('Fatwa', fatwa.id)
        end

        it 'does not call migrate_to_final_audio' do
          expect_any_instance_of(Fatwa).not_to receive(:migrate_to_final_audio)
          described_class.perform_now('Fatwa', fatwa.id)
        end
      end

      context 'when optimized_audio is not attached' do
        before do
          fatwa.optimized_audio.purge
        end

        it 'skips migration' do
          expect(Rails.logger).to receive(:info).with(/has no optimized_audio/)
          described_class.perform_now('Fatwa', fatwa.id)
        end
      end

      context 'when record does not exist' do
        it 'logs warning and returns' do
          expect(Rails.logger).to receive(:warn).with(/not found/)
          described_class.perform_now('Fatwa', 999999)
        end
      end
    end

    context 'with Lesson' do
      let(:scholar) { create(:scholar, full_name: 'الشيخ محمد') }
      let(:series) { create(:series, title: 'سلسلة الفقه', scholar: scholar) }
      let(:lesson) { create(:lesson, title: 'الدرس الأول', series: series, position: 1) }

      before do
        lesson.optimized_audio.attach(audio_file)
      end

      it 'migrates optimized_audio to final_audio' do
        expect {
          described_class.perform_now('Lesson', lesson.id)
        }.to change { lesson.reload.final_audio.attached? }.from(false).to(true)
      end

      it 'logs success message' do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info).with(/Successfully migrated Lesson##{lesson.id}/)
        described_class.perform_now('Lesson', lesson.id)
      end

      context 'when position is nil' do
        before do
          lesson.update_column(:position, nil)
        end

        it 'raises an error' do
          expect {
            described_class.new.perform('Lesson', lesson.id)
          }.to raise_error(/Migration failed/)
        end
      end
    end

    context 'with Lecture' do
      let(:scholar) { create(:scholar, full_name: 'الشيخ محمد') }
      let(:lecture) { create(:lecture, title: 'محاضرة في الفقه', kind: :sermon, scholar: scholar) }

      before do
        lecture.optimized_audio.attach(audio_file)
      end

      it 'migrates optimized_audio to final_audio' do
        expect {
          described_class.perform_now('Lecture', lecture.id)
        }.to change { lecture.reload.final_audio.attached? }.from(false).to(true)
      end

      it 'logs success message' do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info).with(/Successfully migrated Lecture##{lecture.id}/)
        described_class.perform_now('Lecture', lecture.id)
      end
    end

    context 'when migration fails' do
      let(:fatwa) { create(:fatwa) }

      before do
        fatwa.optimized_audio.attach(audio_file)
        allow_any_instance_of(Fatwa).to receive(:migrate_to_final_audio).and_return(false)
      end

      it 'raises an error' do
        expect {
          described_class.new.perform('Fatwa', fatwa.id)
        }.to raise_error(/Migration failed/)
      end

      it 'logs error message' do
        expect(Rails.logger).to receive(:error).with(/Failed to migrate/)
        begin
          described_class.new.perform('Fatwa', fatwa.id)
        rescue
          # Expected to raise
        end
      end
    end
  end
end
