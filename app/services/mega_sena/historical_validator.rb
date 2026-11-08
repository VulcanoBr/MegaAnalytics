module MegaSena
  # Audita a integridade de todo o histórico armazenado.
  # Retorna um Hash (jsonb-friendly) com result: passed | warning | failed.
  class HistoricalValidator
    MAX_ISSUES = 100

    COLUMNS = (
      %i[contest_number draw_date] + Draw::NUMBER_COLUMNS + Draw::MONEY_COLUMNS + Draw::COUNT_COLUMNS
    ).freeze

    def initialize(scope = Draw.all)
      @scope = scope
    end

    def call
      @errors = []
      @warnings = []

      rows = @scope.order(:contest_number).pluck(*COLUMNS).map { |values| COLUMNS.zip(values).to_h }

      check_rows(rows)
      check_duplicates(rows)
      check_gaps(rows)

      {
        "result" => result,
        "checked_draws" => rows.size,
        "errors_count" => @errors.size,
        "warnings_count" => @warnings.size,
        "errors" => @errors.first(MAX_ISSUES),
        "warnings" => @warnings.first(MAX_ISSUES),
        "checked_at" => Time.current.iso8601
      }
    end

    private

    def result
      return "failed" if @errors.any?
      return "warning" if @warnings.any?

      "passed"
    end

    def check_rows(rows)
      previous_date = nil

      rows.each do |row|
        contest = row[:contest_number]
        numbers = Draw::NUMBER_COLUMNS.map { |c| row[c] }

        if numbers.any?(&:nil?) || numbers.size != 6
          error("missing_numbers", contest, "O concurso não possui as seis dezenas")
        else
          error("number_out_of_range", contest, "Dezena fora do intervalo 01–60") unless numbers.all? { |n| n.between?(1, 60) }
          error("repeated_numbers", contest, "Dezenas repetidas no mesmo concurso") if numbers.uniq.size != 6
        end

        date = row[:draw_date]
        if date.nil?
          error("missing_date", contest, "Data do sorteio ausente")
        else
          error("future_date", contest, "Data do sorteio no futuro (#{date})") if date > Date.current
          if previous_date && date < previous_date
            error("chronology", contest, "Data anterior à do concurso precedente (#{date} < #{previous_date})")
          end
          previous_date = date
        end

        negatives = Draw::MONEY_COLUMNS.select { |c| row[c] && row[c].negative? }
        error("negative_money", contest, "Valores monetários negativos: #{negatives.join(', ')}") if negatives.any?
      end
    end

    def check_duplicates(rows)
      rows.map { |r| r[:contest_number] }.tally.each do |contest, count|
        error("duplicate_contest", contest, "Concurso duplicado (#{count} registros)") if count > 1
      end
    end

    def check_gaps(rows)
      numbers = rows.map { |r| r[:contest_number] }.uniq
      return if numbers.empty?

      warn_issue("history_start", numbers.min, "O histórico não começa no concurso 1") if numbers.min != 1

      gaps = (numbers.min..numbers.max).to_a - numbers
      gaps.each { |n| error("gap", n, "Concurso ausente na sequência") }
    end

    def error(code, contest, message)
      @errors << { "code" => code, "contest_number" => contest, "message" => message }
    end

    def warn_issue(code, contest, message)
      @warnings << { "code" => code, "contest_number" => contest, "message" => message }
    end
  end
end
