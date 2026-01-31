
const isPrescriptionRequired = (medicine) => {
  if (!medicine) return false;

  if (medicine.prescriptionRequired === true) {
    return true;
  }

  if (medicine.category === "PRESCRIPTION") {
    return true;
  }

  // Drug schedule based check
  const restrictedSchedules = ["H", "H1", "X"];
  if (restrictedSchedules.includes(medicine.drugSchedule)) {
    return true;
  }

  return false;
};

module.exports = {
  isPrescriptionRequired
};
