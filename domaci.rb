require "google_drive"
session = GoogleDrive::Session.from_config("config.json")

 def remove_empty(matrix)
    count = 0
    matrix.each do |col|            
        if col.all? { |cell| cell == "" }  # prolazim kroz kolone i ako je celija prazna povecavam count sve dok ne naidjem na prvi ne prazan element
            count += 1
        else
            break
        end
    end
    matrix.shift(count)
 end

class Klasa
    include Enumerable
    attr_reader (:spreadsheet),(:matrix),(:sheet_name),(:worksheet)
    def initialize(session,key,sheet_name)
        @spreadsheet = session.spreadsheet_by_key(key)
        @worksheet = spreadsheet.worksheet_by_title(sheet_name)
    end

    

    def load_matrix(worksheet)
        # spoljasnji map pravi niz za matricu koji sadrzi nizove za svaku kolonu
        #  prolazim kroz svaku kolonu i za nju pravim niz koji sadrzi sve elemente te kolone 
        #  i za svaku kolonu prolazim kroz njene redove i dodajem elemente u niz
        @matrix = (1..worksheet.num_cols).map { |col| (1..worksheet.num_rows).map { |row| worksheet[row, col] } }  #row,col da bih isao nadole, a ne udesno
        remove_empty(matrix)  #brisem prazne kolone
        @matrix = matrix.transpose  #transponujem matricu da bih gledao po redovima a ne po kolonama
        remove_empty(matrix)  #brisem prazne redove
        @matrix.delete_if { |row| row.any? { |cell| cell.to_s.downcase.include?('total') || cell.to_s.downcase.include?('subtotal') } } #ako bilo koji red sadrzi total ili subtotal brisem taj red
        @matrix = matrix.transpose
    end

    def row(row)
        matrix.transpose[row+1]  
    end

    def each
        matrix.each do |row|
            row.each do |element|
                yield element   # kao return samo sto ne prekida petlju nego posalje vrednost i nastavi dalje
            end
        end      
    end


    def [](col)
      # prolazim kroz sve kolone i vracam novu instancu klase2 koja ce imati column kao niz da bih mogao da radim [][]
      matrix.each do |column|     #index je mesto na kom se nalazi kolona u matrici
            return Klasa2.new(column,self,matrix.find_index{column}) if column.include? col
      end
      nil
    end

    def method_missing(columnName, *args)
        raise "more than 0 arguments!!!" unless args.empty?
        coll = matrix.find { |column| column[0].delete(" ") == columnName.to_s } #find vraca prvi element koji zadovoljava uslov ili nil ako ne postoji
        return Klasa2.new(coll,self,matrix.find_index{coll}) #vracam i index kolone da bih mogao da radim PrvaKolona.nesto
    
    end

    def merge_tables(matrica1, matrica2)
        return "Headeri tabela nisu isti" if matrica1.transpose[0] != matrica2.transpose[0]  # ubacujem celu prvu matricu i drugu osim headera
        merged_table = matrica1.transpose
        merged_table += matrica2.transpose[1..-1]
    end

    def minus_tables(matrica1, matrica2)
        return "Headeri tabela nisu isti" if matrica1.transpose[0] != matrica2.transpose[0]  
        minus_matrix = matrica1.transpose.select { |row| !matrica2.transpose[1..-1].include?(row) } #vracam sve redove koji se ne nalaze u drugoj matrici
    end                 #select vraca niz koji zadovoljava uslov (ako matrica2 ne sadrzi red iz matrice1)
end

class Klasa2
    include Enumerable
    attr_accessor (:niz),(:klasa),(:index)

    def initialize(niz,klasa,index)
    @niz = niz
    @klasa = klasa
    @index = index
    end

    def [](col)
        @niz[col]
    end
    
    def []=(col, value)
        @niz[col+1] = value;
    end

    def to_s
        @niz[1..-1].to_s
    end

    def sum
        @niz.sum(&:to_i)
    end    
    
    def avg
        sum / (@niz.size-1).to_f
    end

    def method_missing(columnName,*args)
        raise "ne sme da ima argumente!" unless args.empty?
        klasa.matrix.transpose.find { |red| red[@index] == columnName.to_s }    #radim klasa. da bih pristupio matrici klase, prolazim kroz transponovanu 
    end                                                                         #da bih isao kroz redove i radim red[index] da bih uzeo red gde se nalazi columnName
    
    def each
      niz.each do |element|
        yield element
      end
    end
end

d = Klasa.new(session,"1Ibdrm1pg5_Zcs_wrQZ9ssVrHTshW_wLd6erJgq1ZdtE","Sheet1")
d2 = Klasa.new(session,"1Ibdrm1pg5_Zcs_wrQZ9ssVrHTshW_wLd6erJgq1ZdtE","Sheet2")

d.load_matrix(d.worksheet)
d2.load_matrix(d2.worksheet)
p d.row(1)
puts d["Prva Kolona"] #p ignorise to string
puts d["Prva Kolona"][2]
puts d["Prva Kolona"][1] = "dddd"
puts d["Prva Kolona"]

p d.matrix
#p d.matrix.transpose
puts d.PrvaKolona
p d.PrvaKolona.sum
p d.PrvaKolona.avg

p d.PrvaKolona.dddd
p d.PrvaKolona.map(&:to_i).reduce &:+
p d.PrvaKolona.reduce &:+
p d.PrvaKolona.select {|x| x.to_i.odd?}
p d.merge_tables(d.matrix,d2.matrix)
p d.minus_tables(d.matrix,d2.matrix)
