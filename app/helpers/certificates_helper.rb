module CertificatesHelper
  # Inside Arabic text the number would otherwise swap its parts around the
  # hyphen or break across lines there.
  def certificate_number_tag(number)
    tag.bdi(number, dir: "ltr", class: "whitespace-nowrap")
  end

  # The verify URL as a link that reads left to right and copies clean: each
  # Arabic path segment is isolated in a <bdi>, so the slashes stay in place
  # without inserting direction marks into the text.
  def certificate_verify_link(certificate)
    url = certificate_url(certificate)
    parts = CGI.unescape(url).split("/", -1).map { |part| part.match?(/\p{Arabic}/) ? tag.bdi(part) : part }
    link_to safe_join(parts, "/"), url, dir: "ltr", class: "link link-hover"
  end

  # The program's title after "has completed the program", without saying
  # "برنامج" twice when the title already starts with it.
  def certificate_program_name(program)
    word = t("programs.certificate.program_word")
    title = tag.strong("«#{program.title}»", class: "font-bold")
    program.title.start_with?(word) ? title : safe_join([ word, title ], " ")
  end

  def certificate_name_classes(name)
    size = name.length > 40 ? "text-xl md:text-3xl print:text-4xl" : "text-2xl md:text-4xl print:text-5xl"
    "#{size} leading-relaxed font-bold font-title border-b-2 border-primary/30 px-6 pb-2"
  end
end
