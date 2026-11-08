import Foundation

struct CategoryClassifier {
    static func classify(_ merchant: String) -> Category {
        let lower = merchant.lowercased()

        // Order matters: more specific / conflict-prone categories come first.
        // Health before Supermarket → prevents "סופר-פארם" matching "סופר".
        // Entertainment before Housing → prevents "yes"/"hot" matching utilities.
        let rules: [(Category, [String])] = [

            // ─── בריאות ───────────────────────────────────────────────────────
            (.health, [
                // פארמים
                "סופר-פארם", "superpharm", "super pharm", "super-pharm",
                "good pharm", "new pharm", "be pharm",
                "בית מרקחת", "pharmacy",
                // קופות חולים
                "כללית", "clalit", "מכבי", "maccabi", "מאוחדת", "לאומית",
                // בתי חולים
                "שיבא", "sheba", "איכילוב", "ichilov",
                "הדסה", "hadassah", "רמב\"ם", "rambam",
                "בילינסון", "מאיר hosp", "סורוקה", "soroka",
                "אסותא", "assuta", "מדיקה", "medika",
                "שניידר", "schneider", "herzliya medical", "הרצליה מדיקל",
                "וולפסון", "קפלן", "ברזילי", "נהריה", "הלל יפה",
                "אסף הרופא", "שערי צדק", "לניאדו", "זיו", "פוריה",
                "יוספטל", "לב השרון", "שלוותה", "גהה", "אברבנאל",
                // שירותי חירום
                "טרם", "terem",
                // כללי
                "רופא", "clinic", "hospital", "medical center",
            ]),

            // ─── סופרמרקט ─────────────────────────────────────────────────────
            (.supermarket, [
                "שופרסל", "shufersal",
                "רמי לוי", "rami levi",
                "יינות ביתן", "יוחננוף", "יוחנן",
                "חצי חינם", "אושר עד",
                "מחסני השוק", "סופר יהודה", "קשת טעמים",
                "tiv taam", "טיב טעם",
                "am:pm", "am pm",
                "מגה", "ויקטורי",
            ]),

            // ─── קפה ──────────────────────────────────────────────────────────
            (.coffee, [
                // רשתות ישראליות
                "ארומה", "aroma",
                "גרג", "greg",
                "קופיקס", "cofix",
                "לנדוור", "landwer",
                "ארקפה", "arcaffe",
                "קקאו", "cacao",
                "ביגה", "biga",
                "בליקר", "bleecker",
                "אילנ'ס",
                "anastasia", "origem", "waycup",
                "cafelix", "nahat coffee", "xoho",
                "mae cafe", "levinsky 41",
                // מילות מפתח כלליות
                "קפה", "cafe", "coffee",
                "starbucks",
                "נספרסו", "nespresso", "espresso",
                "coffee bean",
            ]),

            // ─── מסעדות ───────────────────────────────────────────────────────
            (.restaurants, [
                // המבורגר
                "מקדונלד", "mcdonald",
                "בורגראנץ", "burgeranch",
                "burgus", "bbb burger",
                "בורגר סאלון", "מוזס", "black bar",
                "אגאדיר", "agadir",
                // שרשרות ידועות
                "מקס ברנר", "max brenner",
                "japanika", "ג'פניקה",
                "kfc", "domino", "pizza hut",
                "vapiano", "pasta basta",
                // מסעדות ישראליות
                "טאיזו", "taizu",
                "מחניודה", "machneyuda",
                "הסאלון", "hasalon",
                "papagaio", "פאפאגאיו",
                "tiger lily", "herbert samuel",
                "אל גאוצ'ו", "gaucho",
                "אנגוס", "angus",
                "לחם בשר", "רק בשר", "מיטבר",
                "benedict",
                // אוכל רחוב
                "פלאפל", "falafel",
                "שווארמה", "shawarma",
                "סביח",
                // כללי
                "פיצה", "pizza",
                "סושי", "sushi",
                "חומוס", "hummus",
            ]),

            // ─── דלק ──────────────────────────────────────────────────────────
            (.fuel, [
                "דלק", "delek",
                "סונול", "sonol",
                "פז", "paz",
                "ten ", "ten\t",
                "דור אלון", "dor alon",
                "yellow", "alonit",
                "so good", "pazomat",
                "fuel", "gas station",
            ]),

            // ─── בידור ────────────────────────────────────────────────────────
            // לפני דיור — מונע "yes planet" / "hot cinema" מלהתאים לתשלומים
            (.entertainment, [
                // קולנוע
                "cinema city", "סינמה סיטי",
                "yes planet", "יס פלאנט",
                "rav hen", "רב חן",
                "hot cinema", "הוט סינמה",
                "globus max",
                "סינמה", "cinema",
                // פעילויות
                "bowling",
                "game zone", "ijump", "sky jump",
                "babylon park", "superland", "luna park",
                "magic kass",
                "escape room", "questomania", "escape sign",
                "fun zone", "vr park", "laser tag",
                // סטרימינג ומשחקים
                "netflix", "spotify", "apple", "steam",
                "פלייסטיישן", "playstation",
            ]),

            // ─── דיור וחשבונות ────────────────────────────────────────────────
            (.housing, [
                "שכירות",
                // חשמל
                "חברת חשמל", "חשמל",
                // מים (ספציפי לפני כללי)
                "מי אביבים", "מי גבעתיים", "מי רמת גן",
                "מי הרצליה", "מי ראשון", "מי חולון",
                "מי בת ים", "מי אשדוד", "מי חיפה", "מי באר שבע",
                // מסים
                "ארנונה", "ועד בית",
                // גז
                "גז", "מגז",
                // תקשורת
                "bezeq", "בזק",
                "hot mobile", "hot net", "hot tv",
                "yes tv",
                "cellcom", "סלקום",
                "partner",
                "פלאפון", "pelephone",
                "golan telecom", "we4g",
                "013 netvision", "013 נטוויז'ן",
                "012 smile",
                "ibc unlimited",
                "סטינג", "sting tv",
            ]),

            // ─── חינוך ────────────────────────────────────────────────────────
            (.education, [
                "אוניברסיטה", "מכללה", "university",
                "קורס", "udemy", "coursera",
                "סטימצקי", "steimatzky",
                "צומת ספרים",
                "ספרים",
            ]),

            // ─── קניות ────────────────────────────────────────────────────────
            (.shopping, [
                // ביגוד
                "זארה", "zara",
                "h&m", "castro", "renuar",
                "pull & bear", "pull&bear",
                "bershka", "stradivarius",
                "american eagle",
                "nike", "adidas", "puma",
                "foot locker", "footlocker",
                "golf & co", "golf fashion",
                "naaman",
                // אלקטרוניקה
                "terminalx", "terminal x",
                "ksp", "bug ",
                "מחסני חשמל",
                // בית
                "home center", "הום סנטר",
                "ikea", "ace ",
                "fox home", "zara home",
                // כללי
                "office depot",
                "laline", "the body shop",
                "אמזון", "amazon", "ebay",
                "next", "fox",
            ]),
        ]

        for (category, keywords) in rules {
            if keywords.contains(where: { lower.contains($0.lowercased()) }) {
                return category
            }
        }

        return .other
    }
}
