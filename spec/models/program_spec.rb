require "rails_helper"

RSpec.describe Program, type: :model do
  subject(:program) { build(:program) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_numericality_of(:pass_mark).only_integer.is_in(0..100) }

  it "is unpublished by default with a pass mark of 60" do
    expect(Program.new).to have_attributes(published: false, pass_mark: 60)
  end

  it "assigns only the global default domain automatically" do
    default = create(:domain, is_default: true)
    create(:domain)
    expect(create(:program).domains).to eq([ default ])
  end

  it "does not cascade a domain assignment to its lessons" do
    site = create(:domain)
    item = create(:program_item, :lesson)
    item.program.assign_to(site)
    expect(item.lesson.reload.domains).not_to include(site)
  end

  it "lists the distinct scholars of its lesson items" do
    program = create(:program)
    first = create(:series)
    second = create(:series)
    create(:program_item, :lesson, program: program, lesson: create(:lesson, series: first))
    create(:program_item, :lesson, program: program, lesson: create(:lesson, series: first))
    create(:program_item, :lesson, program: program, lesson: create(:lesson, series: second))
    create(:program_item, :book, program: program)

    expect(program.scholars).to contain_exactly(first.scholar, second.scholar)
  end

  it "orders its items by position" do
    program = create(:program)
    later = create(:program_item, program: program, position: 2)
    earlier = create(:program_item, program: program, position: 1)
    expect(program.program_items).to eq([ earlier, later ])
  end
end
