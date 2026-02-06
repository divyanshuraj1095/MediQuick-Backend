const Medicine = require("../models/Medicines");

function calculateScore(medicine, searchedName, closest) {

    let score = 0;

    // Exact Name Match
    if (medicine.name.toLowerCase().includes(searchedName.toLowerCase())) {
        score += 100;
    }

    // Salt Match
    if (closest && medicine.saltComposition === closest.saltComposition) {
        score += 70;
    }

    // Same Pharmacy
    if (closest && medicine.pharmacy?.toString() === closest.pharmacy?.toString()) {
        score += 40;
    }

    // Stock Bonus
    if (medicine.stock > 50) score += 20;
    else if (medicine.stock > 20) score += 10;

    // OTC safer
    if (medicine.drugSchedule === "OTC") score += 10;

    return score;
}

exports.searchPrescriptionMedicines = async (medicineNames) => {

    const results = [];

    for (let medName of medicineNames) {

        let allCandidates = [];

        // STEP 1 — Exact Match
        let exact = await Medicine.find({
            name: { $regex: medName, $options: "i" },
            stock: { $gt: 0 },
            isAvailable: true
        }).populate("pharmacy");

        if (exact.length > 0) {
            exact.forEach(m => {
                m._score = calculateScore(m, medName);
                allCandidates.push(m);
            });
        }

        // STEP 2 — Find Closest Medicine
        let closest = await Medicine.findOne({
            name: { $regex: medName, $options: "i" }
        });

        if (closest) {

            // Salt Alternatives
            if (closest.saltComposition) {
                let saltAlt = await Medicine.find({
                    saltComposition: closest.saltComposition,
                    stock: { $gt: 0 },
                    isAvailable: true
                }).populate("pharmacy");

                saltAlt.forEach(m => {
                    m._score = calculateScore(m, medName, closest);
                    allCandidates.push(m);
                });
            }

            // Manual Alternatives
            if (closest.alternatives?.length > 0) {
                let manualAlt = await Medicine.find({
                    _id: { $in: closest.alternatives },
                    stock: { $gt: 0 },
                    isAvailable: true
                }).populate("pharmacy");

                manualAlt.forEach(m => {
                    m._score = calculateScore(m, medName, closest);
                    allCandidates.push(m);
                });
            }
        }

        // STEP 3 — Fuzzy Search
        let fuzzy = await Medicine.find({
            $text: { $search: medName },
            stock: { $gt: 0 },
            isAvailable: true
        }).limit(5).populate("pharmacy");

        fuzzy.forEach(m => {
            m._score = calculateScore(m, medName, closest);
            allCandidates.push(m);
        });

        // Remove Duplicates
        let unique = Object.values(
            allCandidates.reduce((acc, curr) => {
                acc[curr._id] = curr;
                return acc;
            }, {})
        );

        // Sort By Score
        unique.sort((a, b) => b._score - a._score);

        results.push({
            searchedMedicine: medName,
            totalFound: unique.length,
            medicines: unique.slice(0, 5)
        });
    }

    return results;
};
