import Foundation

struct Country: Identifiable {
    let id: String
    let isoCode: String
    let name: String
    let displayName: String
}

// Obtener la lista de países con DisplayName en es_ES
let esLocale = Locale(identifier: "es_ES")
let countryCodes = Locale.isoRegionCodes
let countries = countryCodes.compactMap {
    let name = Locale.current.localizedString(forRegionCode: $0) ?? ""
    let displayName = esLocale.localizedString(forRegionCode: $0) ?? ""
    return Country(id: $0, isoCode: $0, name: name, displayName: displayName)
}

print("Total countries: \(countries.count)")

class DoubleMetaphone {
    var position = 0
    var primaryPhone = ""
    var secondaryPhone = ""
    var next: (String?, String?, Int) = (nil, nil, 1)

    func checkWordStart() {
        if self.word.getLetters(0, 2) == SILENT_STARTERS.first(where: { self.word.getLetters(0, $0.count) == $0 }) {
            position += 1
        }
        if self.word.getLetters(0) == "X" {
            self.primaryPhone = "S"
            self.secondaryPhone = "S"
            position += 1
        }
    }

    func processInitialVowels() {
        self.next = (nil, nil, 1)
        if position == self.word.startIndex {
            self.next = ("A", 1)
        }
    }



}




class Word {
    let input: String
    let start: String.Index
    var end: String.Index {
        return input.endIndex
    }
    
    init(input: String) {
        self.input = input
        self.start = input.startIndex
    }
    
    func getLetters(range: Range<String.Index>) -> String {
        return String(input[range])
    }
}

    let VOWELS = Set(["A", "E", "I", "O", "U", "Y"])
    let SILENT_STARTERS = ["GN", "KN", "PN", "WR", "PS"]

class DoubleMetaphone {
    var position: String.Index
    var primaryPhone: String
    var secondaryPhone: String
    var next: (String?, String?, Int)
    var word: Word
    


    init() {
        position = String.Index()
        primaryPhone = ""
        secondaryPhone = ""
        next = (nil, nil, 1)
        word = Word(input: "")
    }
    
    func checkWordStart() {
        if word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "GN"
            || word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "KN"
            || word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "PN"
            || word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "WR"
            || word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "PS" {
            position = word.input.index(position, offsetBy: 1)
        }
        
        if word.getLetters(range: position ..< word.input.index(position, offsetBy: 1)) == "X" {
            primaryPhone = "S"
            secondaryPhone = "S"
            position = word.input.index(position, offsetBy: 1)
        }
    }

    func processInitialVowels() {
        next = (nil, nil, 1)
        if position == word.start {
            next = ("A", nil, 1)
        }
    }

    // Add the remaining methods for processing each letter here...

    func parse(input: String) -> (String, String) {
        word = Word(input: input)
        position = word.start
        checkWordStart()
        
        while position < word.end {
            let character = String(word.input[position])
            if "AEIOUY".contains(character) {
                processInitialVowels()
            } else if character == " " {
                position = word.input.index(position, offsetBy: 1)
                continue
            } else if character == "B" {
                processB()
            } else if character == "C" {
                processC()
            } else if character == "D" {
                processD()
            } else if character == "F" {
                processF()
            } else if character == "G" {
                processG()
            } else if character == "H" {
                processH()
            } else if character == "J" {
                processJ()
            } else if character == "K" {
                processK()
            } else if character == "L" {
                processL()
            } else if character == "M" {
                processM()
            } else if character == "N" {
                processN()
            } else if character == "P" {
                processP()
            } else if character == "Q" {
                processQ()
            } else if character == "R" {
                processR()
            } else if character == "S" {
                processS()
            } else if character == "T" {
                processT()
            } else if character == "V" {
                processV()
            } else if character == "W" {
                processW()
            } else if character == "X" {
                processX()
            } else if character == "Z" {
                processZ()
            }
            
            if next.0 != nil, let primary = next.0 {
                primaryPhone += primary
                secondaryPhone += next.1 ?? primary
            }
            
            position = word.input.index(position, offsetBy: next.2)
        }

        if primaryPhone == secondaryPhone {
            secondaryPhone = ""
        }
        return (primaryPhone, secondaryPhone)
    }

    func processB() {
    // "-B" is pronounced as "-P" if not at the end of the word
    if position > word.start && word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "MB" {
        next = ("P", "P", 2)
    } else {
        next = ("P", "P", 1)
    }
    
    // "-B" is silent if followed by a "H" and not at the end of the word
    if word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "BH"
        && position != word.input.index(word.end, offsetBy: -2) {
        position = word.input.index(position, offsetBy: 2)
    }
}

func processC() {
    // "-CIA-" is pronounced as "X"
    if word.getLetters(range: position ..< word.input.index(position, offsetBy: 4)) == "CIA" {
        next = ("X", "X", 3)
        position = word.input.index(position, offsetBy: 3)
        return
    }

    // "-CH-" is pronounced as "X" if at the beginning
    if position == word.start && word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "CH" {
        next = ("X", "X", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "-CH-" is pronounced as "X" if preceded by "S"
    if position > word.start
        && word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "CH"
        && word.getLetters(range: word.input.index(position, offsetBy: -1) ..< position) == "S" {
        next = ("X", "X", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "-CH-" is pronounced as "K" otherwise
    if word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "CH" {
        next = ("K", "K", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "-C-" is pronounced as "X" if followed by "-C-", "-S-", or "-Z-"
    if word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "CI"
        && position < word.input.index(word.end, offsetBy: -2)
        && "CSZ".contains(word.getLetter(at: word.input.index(position, offsetBy: 2))) {
        next = ("X", "X", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "-CC-" is pronounced as "X" if preceded by a vowel and followed by a vowel other than "H"
    if position > word.start
        && word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "CC"
        && isVowel(at: word.input.index(position, offsetBy: -1))
        && (position < word.input.index(word.end, offsetBy: -2)
            && isVowel(at: word.input.index(position, offsetBy: 2))
            && word.getLetter(at: word.input.index(position, offsetBy: 2)) != "H") {
        next = ("X", "X", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "-C-" is pronounced as "K" otherwise
    if word.getLetter(at: word.input.index(position, offsetBy: 1)) == "C" {
        next = ("K", "K", 2)
    } else {
        next = ("K", "K", 1)
    }
}

func processD() {
    // "-DG-" is pronounced as "J" if followed by "-E-", "-I-", or "-Y-"
    if position < word.input.index(word.end, offsetBy: -2)
        && word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "DG"
        && "EYI".contains(word.getLetter(at: word.input.index(position, offsetBy: 2))) {
        next = ("J", "J", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "-DT-" is pronounced as "T" if at the end
    if position == word.input.index(word.end, offsetBy: -2) && word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "DT" {
        next = ("T", "T", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "-D-" is pronounced as "T" otherwise
    next = ("T", "T", 1)
}

func processF() {
    // "-FF-" is pronounced as "F"
    if word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "FF" {
        next = ("F", "F", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "-F-" is pronounced as "F" otherwise
    next = ("F", "F", 1)
}

func processG() {
    let nextCharIndex = word.input.index(after: position, default: word.input.endIndex)

    // "-GH-" is pronounced as "F" if it is at the end of the word
    if word.getLetter(at: position) == "G" && (nextCharIndex == word.input.endIndex || word.getLetter(at: nextCharIndex) != "H") {
        next = ("K", "K", 1)
        position = word.input.index(after: position)
        return
    }

    // "-GN-", "-GNED-" is pronounced as "N"
    if word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "GN" {
        if isSuffixAt(position, "ED") || isSuffixAt(position, "E") || isSuffixAt(position, "ELY") {
            next = ("N", "N", 2)
            position = word.input.index(position, offsetBy: 2)
            return
        }
    }

    // Initial "G" is pronounced as "J" if followed by "H" and not at the beginning of the word
    if word.getLetter(at: position) == "G" && nextCharIndex != word.input.endIndex && word.getLetter(at: nextCharIndex) == "H" && position != word.input.startIndex {
        next = ("J", "J", 1)
        position = word.input.index(after: position)
        return
    }

    // "-G-" is pronounced as "K" if followed by "H" and not at the end of the word
    if word.getLetter(at: position) == "G" && nextCharIndex != word.input.endIndex && word.getLetter(at: nextCharIndex) == "H" && nextCharIndex != word.input.endIndex {
        next = ("K", "K", 1)
        position = word.input.index(after: position)
        return
    }

    // "-G-" is pronounced as "F" if followed by "H" and at the end of the word
    if word.getLetter(at: position) == "G" && nextCharIndex == word.input.endIndex && word.getLetter(at: nextCharIndex) == "H" {
        next = ("F", "F", 1)
        position = word.input.index(after: position)
        return
    }

    // "-G-" is pronounced as "K" otherwise
    if word.getLetter(at: position) == "G" {
        next = ("K", "K", 1)
        position = word.input.index(after: position)
        return
    }
}

func processH() {
    let nextCharIndex = word.input.index(after: position, default: word.input.endIndex)

    // "H" is silent if it is at the beginning of the word and is preceded by a vowel
    if position == word.input.startIndex && isVowel(at: nextCharIndex) {
        // Skip the "H" and move to the next character
        position = word.input.index(after: position)
        return
    }

    // "-CH-" is pronounced as "K" if it is at the beginning of the word
    if isAtBeginning(position) && word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "CH" {
        next = ("K", "K", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "-CH-" is pronounced as "K" if it is not at the beginning of the word and is preceded by a vowel
    if !isAtBeginning(position) && word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "CH" && isVowel(at: position) {
        next = ("K", "K", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "HH" is treated as a single sound
    if word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "HH" {
        // Treat "HH" as a single sound and skip the second "H"
        position = word.input.index(position, offsetBy: 1)
        return
    }

    // "-RH-" is pronounced as "R"
    if word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "RH" {
        next = ("R", "R", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "-H-" is pronounced as "H" otherwise
    if word.getLetter(at: position) == "H" {
        next = ("H", "H", 1)
        position = word.input.index(after: position)
        return
    }
}

func processJ() {
    // "-JOSE-" is pronounced as "H" if it is at the beginning of the word
    if isAtBeginning(position) && word.getLetters(range: position ..< word.input.index(position, offsetBy: 4)) == "JOSE" {
        next = ("H", "H", 4)
        position = word.input.index(position, offsetBy: 4)
        return
    }

    // "-J-" is pronounced as "Y" otherwise
    if word.getLetter(at: position) == "J" {
        next = ("Y", "Y", 1)
        position = word.input.index(after: position)
        return
    }
}

func processK() {
    // "-KN-", "-KNB-", "-KNUD-" are pronounced as "N" if they are at the beginning of the word
    if isAtBeginning(position) {
        if word.getLetters(range: position ..< word.input.index(position, offsetBy: 3)) == "KN" ||
           word.getLetters(range: position ..< word.input.index(position, offsetBy: 4)) == "KNB" ||
           word.getLetters(range: position ..< word.input.index(position, offsetBy: 5)) == "KNUD" {
            next = ("N", "N", 1)
            position = word.input.index(position, offsetBy: 2)
            return
        }
    }

    // "-K-" is pronounced as "K" otherwise
    if word.getLetter(at: position) == "K" {
        next = ("K", "K", 1)
        position = word.input.index(after: position)
        return
    }
}

func processL() {
    // "-L-" is pronounced as "L"
    if word.getLetter(at: position) == "L" {
        next = ("L", "L", 1)
        position = word.input.index(after: position)
        return
    }

    // "-LAU-" is pronounced as "L" if followed by a vowel
    if word.getLetters(range: position ..< word.input.index(position, offsetBy: 3)) == "LAU" &&
       isFollowedByVowel(position: word.input.index(position, offsetBy: 3)) {
        next = ("L", "L", 3)
        position = word.input.index(position, offsetBy: 3)
        return
    }

    // "-LEI-" is pronounced as "L" if it is at the beginning of the word
    if isAtBeginning(position) && word.getLetters(range: position ..< word.input.index(position, offsetBy: 3)) == "LEI" {
        next = ("L", "L", 3)
        position = word.input.index(position, offsetBy: 3)
        return
    }

    // "-L-" is pronounced as "L" if followed by a consonant
    if word.getLetter(at: position) == "L" && isFollowedByConsonant(position: position) {
        next = ("L", "L", 1)
        position = word.input.index(after: position)
        return
    }
}

func processM() {
    // "-M-" is pronounced as "M"
    if word.getLetter(at: position) == "M" {
        next = ("M", "M", 1)
        position = word.input.index(after: position)
        return
    }

    // "-MN-" is pronounced as "N" if not at the beginning of the word
    if word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "MN" &&
       !isAtBeginning(position) {
        next = ("M", "N", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "-M-" is pronounced as "M" if followed by a vowel
    if word.getLetter(at: position) == "M" && isFollowedByVowel(position: position) {
        next = ("M", "M", 1)
        position = word.input.index(after: position)
        return
    }
}

func processN() {
    // "-N-" is pronounced as "N"
    if word.getLetter(at: position) == "N" {
        next = ("N", "N", 1)
        position = word.input.index(after: position)
        return
    }

    // "-NH-" is pronounced as "N" if at the end of the word
    if word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "NH" &&
       isAtEnd(position) {
        next = ("N", "N", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "-NG-" is pronounced as "N" if at the end of the word
    if word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "NG" &&
       isAtEnd(position) {
        next = ("N", "N", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "-NN-" is pronounced as "N"
    if word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "NN" {
        next = ("N", "N", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "-KN-" is pronounced as "N" if followed by "A", "O", or "U"
    if word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "KN" &&
       isFollowedByAOU(position: position) {
        next = ("N", "N", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "-N-" is pronounced as "N" if followed by "G" and not at the end of the word
    if word.getLetter(at: position) == "N" &&
       word.getLetter(at: word.input.index(after: position)) == "G" &&
       !isAtEnd(word.input.index(after: position)) {
        next = ("N", "N", 1)
        position = word.input.index(after: position)
        return
    }

    // "-N-" is pronounced as "N" if followed by a vowel
    if word.getLetter(at: position) == "N" && isFollowedByVowel(position: position) {
        next = ("N", "N", 1)
        position = word.input.index(after: position)
        return
    }
}

func processP() {
    // "-PH-" is pronounced as "F"
    if word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "PH" {
        next = ("F", "F", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "-P-" is pronounced as "P"
    if word.getLetter(at: position) == "P" {
        next = ("P", "P", 1)
        position = word.input.index(after: position)

        // If followed by "H" and at the end of the word, pronounce as "F"
        if word.getLetter(at: position) == "H" && isAtEnd(position) {
            next = ("F", "F", 1)
            position = word.input.index(after: position)
        }

        return
    }

    // "-PP-" is pronounced as "P"
    if word.getLetters(range: position ..< word.input.index(position, offsetBy: 2)) == "PP" {
        next = ("P", "P", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }
}

func processQ() {
    // "-Q-" is pronounced as "K"
    if word.getLetter(at: position) == "Q" {
        next = ("K", "K", 1)
        position = word.input.index(after: position)

        // If followed by "U", move to the next letter
        if isFollowedByU() {
            position = word.input.index(after: position)
        }

        return
    }
}

func processR() {
    // "-R-" is pronounced as "R" if not at the end of the word
    if word.getLetter(at: position) == "R" && !isEndOfWord() {
        next = ("R", "R", 1)
        position = word.input.index(after: position)

        // Handle "-RR-" pronounced as a single "R"
        if word.getLetter(at: position) == "R" {
            position = word.input.index(after: position)
        }

        return
    }

    // "-R-" at the end of the word is silent
    if word.getLetter(at: position) == "R" && isEndOfWord() {
        // Handle special case "-ER"
        if isFollowedByE() {
            next = ("R", "", 2)
        } else {
            next = ("", "", 1)
        }

        position = word.input.index(after: position)
        return
    }
}

func processS() {
    // "-S-" pronounced as "S" if followed by "H" or "IO" or "IA"
    if word.isFollowedBy("S", followedBy: ["H", "IO", "IA"]) {
        next = ("S", "", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "-S-" pronounced as "X" if followed by "I" or "E" or "Y"
    if word.isFollowedBy("S", followedBy: ["I", "E", "Y"]) {
        next = ("X", "", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "-S-" pronounced as "S"
    if word.getLetter(at: position + 1, default: "") == "S" {
        position = word.input.index(position, offsetBy: 2)
    } else {
        position = word.input.index(position, offsetBy: 1)
    }

    next = ("S", "", 1)
}

func processT() {
    // "-TION-" pronounced as "X"
    if word.isFollowedBy("T", followedBy: ["IO", "IA"]) {
        next = ("X", "", 3)
        position = word.input.index(position, offsetBy: 3)
        return
    }

    // "-TIA-" or "-TCH-" pronounced as "X"
    if word.isFollowedBy("T", followedBy: ["IA"]) || word.isFollowedBy("T", followedBy: ["CH"]) {
        next = ("X", "", 3)
        position = word.input.index(position, offsetBy: 3)
        return
    }

    // "-TH-" pronounced as "0" (zero)
    if word.isFollowedBy("T", followedBy: ["H"]) {
        next = ("0", "", 2)
        position = word.input.index(position, offsetBy: 2)
        return
    }

    // "-T-" pronounced as "T"
    if word.isFollowedBy("T") {
        position = word.input.index(position, offsetBy: 1)
    } else {
        position = word.input.index(position, offsetBy: 1)
        next = ("T", "", 1)
    }
}

func processV() {
    // "-V-" pronounced as "F" if followed by a vowel, "V" otherwise
    if word.isFollowedBy("V") {
        let nextChar = word.characterAt(position, offsetBy: 1)
        if nextChar == "OW" || nextChar == "IA" {
            next = ("F", "F", 1)
        } else {
            next = ("V", "F", 1)
        }
    } else {
        position = word.input.index(position, offsetBy: 1)
        next = ("F", "F", 1)
    }
}

func processW() {
    // "-W-" pronounced as "F" if followed by a vowel, "W" otherwise
    if word.isFollowedBy("W") {
        let nextChar = word.characterAt(position, offsetBy: 1)
        if nextChar == "A" || nextChar == "E" || nextChar == "I" || nextChar == "O" || nextChar == "U" {
            next = ("F", "F", 1)
        } else {
            next = ("W", "W", 1)
        }
        position = word.input.index(position, offsetBy: 1)
    } else if position == 0 && word.isAt(position, "WH") {
        // "-WH-" at the beginning is pronounced as "W" if followed by a vowel
        let nextChar = word.characterAt(position, offsetBy: 2)
        if nextChar == "A" || nextChar == "E" || nextChar == "I" || nextChar == "O" || nextChar == "U" {
            next = ("W", "W", 2)
        }
    } else if word.isAt(position, "WR") {
        // "-WR-" is pronounced as "R"
        next = ("R", "R", 2)
        position = word.input.index(position, offsetBy: 2)
    }
}

func processX() {
    if position == 0 {
        // "-X-" is pronounced as "S"
        next = ("S", "S", 1)
    }

    position += 1
}

func processZ() {
    next = ("S", (charAt(position + 1) == "Z" ? "S" : "X"), (charAt(position + 1) == "Z" ? 2 : 1))
    position += 1
}


}

// Backwards compatibility for the pre-OO implementation
func doubleMetaphone(input: String) -> (String, String) {
    return DoubleMetaphone().parse(input: input)
}

// Backwards compatibility for the old name of the function
let dm = doubleMetaphone




extension String {
    func removingAccents() -> String {
        return folding(options: .diacriticInsensitive, locale: .current)
    }
}

func searchCountries(searchTerm: String, in countries: [Country]) -> [Country] {
    let searchTermWithoutAccents = searchTerm.removingAccents()

    if searchTermWithoutAccents.count == 2 {
        // Buscar por isoCode
        let filteredByIsoCode = countries.filter { $0.isoCode.removingAccents().lowercased() == searchTermWithoutAccents.lowercased() }
        return filteredByIsoCode
    } else {
        // Buscar coincidencia en name y displayName
        let filteredByNameOrDisplayName = countries.filter {
            $0.name.removingAccents().lowercased().contains(searchTermWithoutAccents.lowercased()) ||
            $0.displayName.removingAccents().lowercased().contains(searchTermWithoutAccents.lowercased())
        }
        return filteredByNameOrDisplayName
    }
}

// Ejemplo de uso
let searchTerm = "Birmania"
let searchResults = searchCountries(searchTerm: searchTerm, in: countries)

print("Search Results by term: \(searchTerm)")
for result in searchResults {
    print("\(result.isoCode), \(result.name), displayName: \(result.displayName)")
}
