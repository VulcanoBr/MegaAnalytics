require "digest"
require "roo"

module MegaSena
  # Importa a planilha oficial de resultados da Mega-Sena (Caixa) de forma incremental.
  #
  # Regras:
  # - nunca atualiza silenciosamente um concurso histórico: divergência rejeita o arquivo inteiro;
  # - concursos idênticos aos já gravados são ignorados;
  # - somente concursos novos e válidos são inseridos, dentro de uma transação;
  # - cada execução gera um ImportBatch (auditoria) com o relatório do HistoricalValidator.
  class XlsxImporter
    MAX_FILE_SIZE = 20.megabytes
    MAX_DETAILS = 200

    # Rejeição controlada do arquivo (não é um erro de programação)
    class Rejected < StandardError
      attr_reader :details

      def initialize(message, details = [])
        super(message)
        @details = details
      end
    end

    # Nomes de cabeçalho aceitos (já normalizados: minúsculo, sem acento, sem espaços duplicados).
    # Ajuste aqui caso a Caixa altere os títulos da planilha.
    COLUMN_ALIASES = {
      contest_number: [ "concurso" ],
      draw_date: [ "data do sorteio", "data sorteio" ],
      number_1: [ "bola1", "bola 1" ],
      number_2: [ "bola2", "bola 2" ],
      number_3: [ "bola3", "bola 3" ],
      number_4: [ "bola4", "bola 4" ],
      number_5: [ "bola5", "bola 5" ],
      number_6: [ "bola6", "bola 6" ],
      winners_sena: [ "ganhadores 6 acertos" ],
      city_uf: [ "cidade / uf", "cidade/uf" ],
      prize_sena: [ "rateio 6 acertos", "valor rateio 6 acertos" ],
      winners_quina: [ "ganhadores 5 acertos" ],
      prize_quina: [ "rateio 5 acertos", "valor rateio 5 acertos" ],
      winners_quadra: [ "ganhadores 4 acertos" ],
      prize_quadra: [ "rateio 4 acertos", "valor rateio 4 acertos" ],
      accumulated_sena: [ "acumulado 6 acertos" ],
      total_revenue: [ "arrecadacao total" ],
      estimated_prize: [ "estimativa prêmio", "estimativa premio" ],
      special_draw_accumulated: [ "acumulado sorteio especial mega da virada", "acumulado sorteio especial" ],
      observation: [ "observacao" ]
    }.freeze

    REQUIRED_COLUMNS = (%i[contest_number draw_date] + Draw::NUMBER_COLUMNS).freeze
    INTEGER_COLUMNS = ([ :contest_number ] + Draw::NUMBER_COLUMNS + Draw::COUNT_COLUMNS).freeze
    DECIMAL_COLUMNS = Draw::MONEY_COLUMNS
    TEXT_COLUMNS = %i[city_uf observation].freeze

    def self.call(file_path:, file_name:)
      new(file_path: file_path, file_name: file_name).call
    end

    def initialize(file_path:, file_name:)
      @file_path = file_path.to_s
      @file_name = file_name.to_s
      @batch = nil
    end

    def call
      @batch = ImportBatch.create!(file_name: @file_name, status: :processing, started_at: Time.current)

      check_file!
      @batch.update!(file_sha256: sha256)
      reject_already_imported!

      rows = parse_rows
      @batch.update!(total_rows: rows.size)
      validate_rows!(rows)

      existing = Draw.all.index_by(&:contest_number)
      new_rows, skipped, divergences = classify(rows, existing)
      raise Rejected.new("Divergência em #{divergences.size} concurso(s) já importado(s). Nada foi gravado.", divergences) if divergences.any?

      check_sequence!(existing.keys + new_rows.map { |r| r[:attrs][:contest_number] })

      persist!(new_rows, skipped)
      run_historical_validation
      @batch
    rescue Rejected => e
      fail_batch!(e.message, e.details)
    rescue StandardError => e
      raise unless @batch&.persisted?

      fail_batch!("Erro inesperado: #{e.class}: #{e.message}", [])
    end

    private

    # --- arquivo -----------------------------------------------------------

    def check_file!
      raise Rejected, "Arquivo não encontrado." unless File.file?(@file_path)
      raise Rejected, "Formato inválido: envie um arquivo .xlsx." unless File.extname(@file_name).casecmp?(".xlsx")
      raise Rejected, "Arquivo vazio." if File.size(@file_path).zero?
      raise Rejected, "Arquivo maior que #{MAX_FILE_SIZE / 1.megabyte} MB." if File.size(@file_path) > MAX_FILE_SIZE
    end

    def sha256
      @sha256 ||= Digest::SHA256.file(@file_path).hexdigest
    end

    def reject_already_imported!
      previous = ImportBatch.succeeded.where(file_sha256: sha256).where.not(id: @batch.id).order(:created_at).last
      return unless previous

      raise Rejected, "Este arquivo já foi importado com sucesso (importação ##{previous.id})."
    end

    # --- leitura -----------------------------------------------------------

    def parse_rows
      sheet = Roo::Excelx.new(@file_path, extension: :xlsx).sheet(0)
      first = sheet.first_row
      raise Rejected, "A planilha não contém dados." if first.nil? || sheet.last_row.to_i <= first

      header = sheet.row(first).map { |cell| normalize(cell) }
      columns = COLUMN_ALIASES.transform_values do |aliases|
        header.index { |name| aliases.map { |a| normalize(a) }.include?(name) }
      end

      missing = REQUIRED_COLUMNS.select { |key| columns[key].nil? }
      raise Rejected, "Colunas obrigatórias ausentes: #{missing.join(', ')}." if missing.any?

      ((first + 1)..sheet.last_row).filter_map do |line|
        raw = sheet.row(line)
        next if raw.compact.all? { |cell| blank_cell?(cell) }

        build_row(line, raw, columns)
      end
    end

    def build_row(line, raw, columns)
      attrs = {}
      errors = []

      columns.each do |key, index|
        next if index.nil?

        begin
          attrs[key] = cast(key, raw[index])
        rescue ArgumentError, TypeError, Date::Error
          errors << "valor inválido na coluna #{key}: #{raw[index].inspect}"
        end
      end

      { line: line, attrs: attrs, errors: errors }
    end

    def cast(key, value)
      return nil if blank_cell?(value)

      if key == :draw_date then parse_date(value)
      elsif INTEGER_COLUMNS.include?(key) then parse_integer(value)
      elsif DECIMAL_COLUMNS.include?(key) then parse_decimal(value)
      elsif TEXT_COLUMNS.include?(key) then value.to_s.strip
      else value
      end
    end

    def parse_date(value)
      case value
      when DateTime, Time then value.to_date
      when Date then value
      else Date.strptime(value.to_s.strip, "%d/%m/%Y")
      end
    end

    def parse_integer(value)
      return value if value.is_a?(Integer)
      return value.to_i if value.is_a?(Numeric) && value == value.to_i

      Integer(value.to_s.strip.delete("."), 10)
    end

    def parse_decimal(value)
      return BigDecimal(value.to_s).round(2) if value.is_a?(Numeric)

      cleaned = value.to_s.gsub(/R\$|\s/, "").delete(".").tr(",", ".")
      BigDecimal(cleaned).round(2)
    end

    def blank_cell?(value)
      value.nil? || (value.is_a?(String) && value.strip.empty?)
    end

    def normalize(value)
      value.to_s.unicode_normalize(:nfd).gsub(/\p{Mn}/, "").downcase.gsub(/\s+/, " ").strip
    end

    # --- validação ---------------------------------------------------------

    def validate_rows!(rows)
      problems = []
      seen = Hash.new(0)

      rows.each do |row|
        attrs = row[:attrs]
        messages = row[:errors].dup
        contest = attrs[:contest_number]
        seen[contest] += 1 if contest

        messages << "concurso ausente ou inválido" unless contest&.positive?
        messages << "data do sorteio ausente" if attrs[:draw_date].nil?

        numbers = Draw::NUMBER_COLUMNS.map { |c| attrs[c] }
        if numbers.any?(&:nil?)
          messages << "as seis dezenas são obrigatórias"
        else
          messages << "dezena fora do intervalo 01–60" unless numbers.all? { |n| n.between?(1, 60) }
          messages << "dezenas repetidas no mesmo concurso" if numbers.uniq.size != 6
        end

        negatives = (Draw::MONEY_COLUMNS + Draw::COUNT_COLUMNS).select { |c| attrs[c] && attrs[c].negative? }
        messages << "valores negativos: #{negatives.join(', ')}" if negatives.any?

        problems << { line: row[:line], contest_number: contest, message: messages.join("; ") } if messages.any?
      end

      seen.select { |_, count| count > 1 }.each_key do |contest|
        problems << { line: nil, contest_number: contest, message: "concurso duplicado na planilha" }
      end

      return if problems.empty?

      raise Rejected.new("Planilha com #{problems.size} problema(s) de validação. Nada foi gravado.", problems)
    end

    def classify(rows, existing)
      new_rows = []
      skipped = 0
      divergences = []

      rows.each do |row|
        current = existing[row[:attrs][:contest_number]]

        if current.nil?
          new_rows << row
          next
        end

        diff = differences(current, row[:attrs])
        if diff.empty?
          skipped += 1
        else
          divergences << { line: row[:line], contest_number: current.contest_number, fields: diff }
        end
      end

      [ new_rows, skipped, divergences ]
    end

    def differences(draw, attrs)
      attrs.each_with_object({}) do |(key, incoming), diff|
        current = draw.public_send(key)
        next if current == incoming

        diff[key] = { existing: current&.to_s, incoming: incoming&.to_s }
      end
    end

    def check_sequence!(contest_numbers)
      numbers = contest_numbers.uniq.sort
      return if numbers.empty?

      gaps = (numbers.first..numbers.last).to_a - numbers
      return if gaps.empty?

      details = gaps.first(MAX_DETAILS).map { |n| { contest_number: n, message: "concurso ausente na sequência" } }
      raise Rejected.new("Lacunas na sequência de concursos (#{gaps.size}). Nada foi gravado.", details)
    end

    # --- gravação ----------------------------------------------------------

    def persist!(new_rows, skipped)
      Draw.transaction do
        new_rows.each do |row|
          Draw.create!(
            row[:attrs].merge(
              import_batch: @batch,
              source_metadata: { "source_file" => @file_name, "source_line" => row[:line] }
            )
          )
        end

        @batch.update!(
          status: :succeeded,
          inserted_rows: new_rows.size,
          skipped_rows: skipped,
          updated_rows: 0,
          error_rows: 0,
          finished_at: Time.current
        )
      end
    end

    def run_historical_validation
      @batch.update!(validation_report: HistoricalValidator.new.call)
    end

    def fail_batch!(message, details)
      @batch.update!(
        status: :failed,
        error_rows: details.size,
        error_details: [ { "message" => message } ] + details.first(MAX_DETAILS).map { |d| d.deep_stringify_keys },
        finished_at: Time.current
      )
      @batch
    end
  end
end
