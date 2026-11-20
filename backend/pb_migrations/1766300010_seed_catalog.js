/// <reference path="../pb_data/types.d.ts" />

// Structural catalog exported from the app's own lib/data/catalog.dart, so the
// backend and a first-run app cannot disagree. Regenerate with:
//   flutter test test/_export_catalog_seed_test.dart
//   python3 tool/gen_seed.py
//
// Deliberately NOT seeded: notices. The ones the app shipped were dated and had
// passed, so publishing them would state something false to patients. The
// patientId counter starts at 0 and must be set to the clinic's real register
// number before go-live.

migrate(
  (app) => {
    const departments = app.findCollectionByNameOrId("departments");
    if (app.countRecords(departments) === 0) {
      const rows =       [
        {
          "code": "opd",
          "nameNp": "सामान्य OPD",
          "nameEn": "General OPD",
          "descNp": "हरेक दिन क्लिनिक खुल्ने समयभर MBBS मेडिकल अफिसरद्वारा OPD जाँच, परामर्श र प्राथमिक उपचार। अपोइन्टमेन्ट आवश्यक पर्दैन।",
          "descEn": "Daily MBBS medical officer OPD for checks, consultations and primary care throughout clinic hours. No appointment needed.",
          "icon": "stethoscope",
          "sortOrder": 0
        },
        {
          "code": "physician",
          "nameNp": "भित्री रोग",
          "nameEn": "Internal Medicine",
          "descNp": "भित्री रोग विशेषज्ञसहित परामर्श — महिनाको दोस्रो शनिबार; आइत–शुक्र दिउँसो पनि उपलब्ध।",
          "descEn": "Internal medicine consultation with a specialist — 2nd Saturday; also available Sunday–Friday afternoons.",
          "icon": "heartbeat",
          "sortOrder": 1,
          "specialistOrder": 2
        },
        {
          "code": "gyn",
          "nameNp": "स्त्री रोग",
          "nameEn": "Gynecology",
          "descNp": "गर्भवती जाँच, स्त्री रोग परामर्श र परिवार नियोजन — महिनाको दोस्रो शनिबार।",
          "descEn": "Pregnancy checks, gynecology consultations and family planning — 2nd Saturday of the month.",
          "icon": "genderFemale",
          "sortOrder": 2,
          "specialistOrder": 3
        },
        {
          "code": "xray",
          "nameNp": "डिजिटल एक्स-रे",
          "nameEn": "Digital X-Ray",
          "descNp": "डिजिटल एक्स-रे सेवा, दैनिक उपलब्ध।",
          "descEn": "Digital X-ray service, available daily.",
          "icon": "scan",
          "sortOrder": 3
        },
        {
          "code": "dental",
          "nameNp": "दन्त उपचार",
          "nameEn": "Dental Care",
          "descNp": "दाँत जाँच, सफाइ र दन्त उपचार सेवा। बिहान सिधै आउन सकिन्छ।",
          "descEn": "Dental checks, cleaning and treatment. Walk in during morning hours.",
          "icon": "tooth",
          "sortOrder": 4
        },
        {
          "code": "lab",
          "nameNp": "ल्याब",
          "nameEn": "Laboratory",
          "descNp": "रगत, पिसाब तथा अन्य नियमित परीक्षण। रिपोर्ट सोही दिन।",
          "descEn": "Blood, urine and other routine tests. Reports available the same day.",
          "icon": "testTube",
          "sortOrder": 5
        },
        {
          "code": "ent",
          "nameNp": "नाक, कान, घाँटी",
          "nameEn": "ENT",
          "descNp": "नाक, कान र घाँटी सम्बन्धी जाँच तथा उपचार — महिनाको पहिलो शनिबार।",
          "descEn": "Ear, nose and throat care — 1st Saturday of the month.",
          "icon": "ear",
          "sortOrder": 6,
          "specialistOrder": 1
        },
        {
          "code": "psych",
          "nameNp": "मानसिक स्वास्थ्य",
          "nameEn": "Mental Health",
          "descNp": "मनोरोग विशेषज्ञद्वारा मानसिक स्वास्थ्य परामर्श — महिनाको अन्तिम शनिबार।",
          "descEn": "Mental health consultation with a psychiatrist — last Saturday of the month.",
          "icon": "brain",
          "sortOrder": 7,
          "specialistOrder": 5
        },
        {
          "code": "derma",
          "nameNp": "छाला रोग",
          "nameEn": "Dermatology",
          "descNp": "छाला सम्बन्धी समस्या, एलर्जी र उपचार परामर्श — महिनाको पहिलो शनिबार।",
          "descEn": "Skin problems, allergies and treatment consultation — 1st Saturday of the month.",
          "icon": "sparkle",
          "sortOrder": 8,
          "specialistOrder": 0
        },
        {
          "code": "usg",
          "nameNp": "भिडियो एक्स-रे (USG)",
          "nameEn": "Ultrasound (USG)",
          "descNp": "भिडियो एक्स-रे अर्थात् अल्ट्रासाउन्ड तथा एनोमली स्क्यान सेवा — महिनाको दुई पटक।",
          "descEn": "Video X-ray (ultrasound) and anomaly scans — twice every month.",
          "icon": "monitor",
          "sortOrder": 9
        },
        {
          "code": "ecg",
          "nameNp": "ई.सि.जी. (ECG)",
          "nameEn": "ECG",
          "descNp": "मुटुको विद्युतीय गतिविधि जाँच सेवा।",
          "descEn": "Heart electrical activity test.",
          "icon": "waveform",
          "sortOrder": 10
        },
        {
          "code": "echo",
          "nameNp": "इकोकार्डियोग्राफी",
          "nameEn": "Echocardiography",
          "descNp": "इकोकार्डियोग्राफी सेवा — मुटु विशेषज्ञसहित महिनाको अन्तिम शनिबार।",
          "descEn": "Echocardiography with a cardiologist — last Saturday of the month.",
          "icon": "heartbeat",
          "sortOrder": 11,
          "specialistOrder": 6
        },
        {
          "code": "family",
          "nameNp": "परिवार नियोजन",
          "nameEn": "Family Planning",
          "descNp": "परिवार नियोजन साधन तथा परामर्श सेवा।",
          "descEn": "Family planning methods and counselling.",
          "icon": "usersThree",
          "sortOrder": 12
        },
        {
          "code": "physio",
          "nameNp": "फिजियोथेरापी",
          "nameEn": "Physiotherapy",
          "descNp": "दुखाइ र चोटपटकका लागि फिजियोथेरापी सेवा। साँझ सिधै आउन सकिन्छ।",
          "descEn": "Physiotherapy for pain and injuries. Walk in during evening hours.",
          "icon": "personSimpleWalk",
          "sortOrder": 13
        },
        {
          "code": "ortho",
          "nameNp": "हाडजोर्नी",
          "nameEn": "Orthopedics",
          "descNp": "हाड, जोर्नी र नसा सम्बन्धी जाँच तथा उपचार — महिनाको तेस्रो शनिबार।",
          "descEn": "Bone, joint and nerve care — 3rd Saturday of the month.",
          "icon": "bone",
          "sortOrder": 14,
          "specialistOrder": 4
        },
        {
          "code": "emergency",
          "nameNp": "आपत्कालीन सेवा",
          "nameEn": "Emergency Care",
          "descNp": "क्लिनिक खुल्ने समयभर आपत्कालीन उपचार। आपत्कालमा सिधै फोन गर्नुहोस्: ०१०-५६१६०६",
          "descEn": "Emergency care during clinic hours. For urgent help, call 010-561606.",
          "icon": "siren",
          "sortOrder": 15
        },
        {
          "code": "pharmacy",
          "nameNp": "फार्मेसी",
          "nameEn": "Pharmacy",
          "descNp": "OPD नजिकै पूर्ण रूपमा उपलब्ध नैतिक फार्मेसी।",
          "descEn": "A fully stocked, ethical pharmacy right beside the OPD floor.",
          "icon": "pill",
          "sortOrder": 16
        },
        {
          "code": "daycare",
          "nameNp": "आईसीयू तथा डे केयर",
          "nameEn": "ICU & Day Care",
          "descNp": "आधुनिक उपकरण र तालिमप्राप्त नर्सिङ टिमसहितको निगरानी तथा डे केयर सेवा।",
          "descEn": "Monitored care and day care with modern equipment and trained nursing staff.",
          "icon": "bed",
          "sortOrder": 17
        }
      ];
      rows.forEach((row) => {
        app.save(new Record(departments, row));
      });
    }
    const doctors = app.findCollectionByNameOrId("doctors");
    if (app.countRecords(doctors) === 0) {
      const rows =       [
        {
          "code": "ashish",
          "nameNp": "डा. आशिष श्रेष्ठ",
          "nameEn": "Dr. Ashish Shrestha",
          "specialtyNp": "सामान्य चिकित्सक",
          "specialtyEn": "General Physician",
          "qualification": "MBBS",
          "departmentCode": "opd",
          "fee": 500,
          "startTime": null,
          "endTime": null,
          "weekdays": [
            1,
            2,
            3,
            4,
            5,
            6,
            7
          ],
          "shifts": [
            "morning",
            "afternoon",
            "evening"
          ],
          "saturdayGroup": null,
          "visiting": false,
          "avatar": "assets/avatars/ashish.png",
          "bioNp": "सामान्य स्वास्थ्य समस्या, ज्वरो, संक्रमण तथा दीर्घ रोगको प्राथमिक उपचारमा अनुभवी।",
          "bioEn": "Experienced in primary care for common illnesses, fever, infections and chronic conditions.",
          "availabilityNp": "दैनिक · क्लिनिक खुल्ने समयभर",
          "availabilityEn": "Daily · All clinic hours"
        },
        {
          "code": "navin",
          "nameNp": "डा. नविन अधिकारी",
          "nameEn": "Dr. Navin Adhikari",
          "specialtyNp": "भित्री रोग विशेषज्ञ",
          "specialtyEn": "Internal Medicine Specialist",
          "qualification": "MD (Internal Medicine)",
          "departmentCode": "physician",
          "fee": 800,
          "startTime": "12:00",
          "endTime": "16:00",
          "weekdays": [
            1,
            2,
            3,
            4,
            5,
            7
          ],
          "shifts": [
            "afternoon"
          ],
          "saturdayGroup": "second",
          "visiting": false,
          "avatar": "assets/avatars/navin.png",
          "bioNp": "भित्री रोग, दीर्घ रोग व्यवस्थापन तथा स्वास्थ्य परामर्शमा विशेषज्ञता।",
          "bioEn": "Specialises in internal medicine, chronic disease management and health counselling.",
          "availabilityNp": "२औँ शनिबार · दिउँसो १२–४",
          "availabilityEn": "2nd Saturday · 12–4 PM"
        },
        {
          "code": "sunita",
          "nameNp": "डा. सुनिता तामाङ",
          "nameEn": "Dr. Sunita Tamang",
          "specialtyNp": "स्त्री रोग विशेषज्ञ",
          "specialtyEn": "Gynecologist",
          "qualification": "MS (Obs/Gyn)",
          "departmentCode": "gyn",
          "fee": 800,
          "startTime": "10:00",
          "endTime": "14:00",
          "weekdays": [
            6
          ],
          "shifts": [
            "morning",
            "afternoon"
          ],
          "saturdayGroup": "second",
          "visiting": false,
          "avatar": "assets/avatars/sunita.png",
          "bioNp": "गर्भवती जाँच, स्त्री रोग परामर्श तथा परिवार नियोजन सेवामा अनुभवी।",
          "bioEn": "Experienced in antenatal care, gynecology consultations and family planning.",
          "availabilityNp": "२औँ शनिबार · बिहान १०–२",
          "availabilityEn": "2nd Saturday · 10 AM – 2 PM"
        },
        {
          "code": "rajan",
          "nameNp": "डा. राजन कार्की",
          "nameEn": "Dr. Rajan Karki",
          "specialtyNp": "हाडजोर्नी तथा नसा रोग विशेषज्ञ",
          "specialtyEn": "Orthopedic Specialist",
          "qualification": "MS (Ortho)",
          "departmentCode": "ortho",
          "fee": 800,
          "startTime": "12:00",
          "endTime": "16:00",
          "weekdays": [
            6
          ],
          "shifts": [
            "afternoon"
          ],
          "saturdayGroup": "third",
          "visiting": false,
          "avatar": "assets/avatars/rajan.png",
          "bioNp": "हाड, जोर्नी, नसा र चोटपटक सम्बन्धी उपचारमा विशेषज्ञ।",
          "bioEn": "Specialist in bone, joint, nerve and injury care.",
          "availabilityNp": "३औँ शनिबार · दिउँसो १२–४",
          "availabilityEn": "3rd Saturday · 12–4 PM"
        },
        {
          "code": "pratibha",
          "nameNp": "डा. प्रतिभा जोशी",
          "nameEn": "Dr. Pratibha Joshi",
          "specialtyNp": "छाला रोग विशेषज्ञ",
          "specialtyEn": "Dermatologist",
          "qualification": "MD (Dermatology)",
          "departmentCode": "derma",
          "fee": 700,
          "startTime": "10:00",
          "endTime": "13:00",
          "weekdays": [
            6
          ],
          "shifts": [
            "morning"
          ],
          "saturdayGroup": "first",
          "visiting": false,
          "avatar": "assets/avatars/pratibha.png",
          "bioNp": "छाला संक्रमण, एलर्जी तथा सौन्दर्य सम्बन्धी उपचारमा विशेषज्ञ।",
          "bioEn": "Specialist in skin infections, allergies and cosmetic dermatology.",
          "availabilityNp": "१औँ शनिबार · बिहान १०–१",
          "availabilityEn": "1st Saturday · 10 AM – 1 PM"
        },
        {
          "code": "bikas",
          "nameNp": "डा. विकास पौडेल",
          "nameEn": "Dr. Bikas Poudel",
          "specialtyNp": "नाक, कान, घाँटी विशेषज्ञ",
          "specialtyEn": "ENT Specialist",
          "qualification": "MS (ENT)",
          "departmentCode": "ent",
          "fee": 700,
          "startTime": "10:00",
          "endTime": "13:00",
          "weekdays": [
            6
          ],
          "shifts": [
            "morning"
          ],
          "saturdayGroup": "first",
          "visiting": false,
          "avatar": "assets/avatars/bikas.png",
          "bioNp": "कान, नाक र घाँटी सम्बन्धी जाँच तथा शल्य उपचारमा अनुभवी।",
          "bioEn": "Experienced in ear, nose and throat evaluation and surgical care.",
          "availabilityNp": "१औँ शनिबार · बिहान १०–१",
          "availabilityEn": "1st Saturday · 10 AM – 1 PM"
        },
        {
          "code": "manish",
          "nameNp": "डा. मनीष गुरुङ",
          "nameEn": "Dr. Manish Gurung",
          "specialtyNp": "दन्त चिकित्सक",
          "specialtyEn": "Dentist",
          "qualification": "BDS",
          "departmentCode": "dental",
          "fee": 500,
          "startTime": "08:00",
          "endTime": "12:00",
          "weekdays": [
            1,
            2,
            3,
            4,
            5,
            6,
            7
          ],
          "shifts": [
            "morning"
          ],
          "saturdayGroup": null,
          "visiting": false,
          "avatar": "assets/avatars/manish.png",
          "bioNp": "दाँत सफाइ, दाँत दुख्ने समस्या तथा सामान्य दन्त उपचारमा अनुभवी।",
          "bioEn": "Experienced in dental cleaning, toothache and routine dental treatment.",
          "availabilityNp": "दैनिक · बिहान ८–१२",
          "availabilityEn": "Daily · 8 AM – 12 PM"
        },
        {
          "code": "suman",
          "nameNp": "डा. सुमन प्रसाद अधिकारी",
          "nameEn": "Dr. Suman Prasad Adhikari",
          "specialtyNp": "मनोरोग विशेषज्ञ",
          "specialtyEn": "Psychiatrist",
          "qualification": "MD (Psychiatry)",
          "departmentCode": "psych",
          "fee": 1000,
          "startTime": "14:00",
          "endTime": "17:00",
          "weekdays": [
            6
          ],
          "shifts": [
            "afternoon"
          ],
          "saturdayGroup": "last",
          "visiting": true,
          "avatar": "assets/avatars/suman.png",
          "bioNp": "काठमाडौँबाट भ्रमणमा आउने मनोरोग विशेषज्ञ; मानसिक तनाव, चिन्ता र निद्रा समस्यामा परामर्श।",
          "bioEn": "Visiting psychiatrist from Kathmandu; consultations for stress, anxiety and sleep problems.",
          "availabilityNp": "अन्तिम शनिबार · दिउँसो २–५",
          "availabilityEn": "Last Saturday · 2–5 PM"
        },
        {
          "code": "sujan",
          "nameNp": "डा. सुजन शाक्य",
          "nameEn": "Dr. Sujan Shakya",
          "specialtyNp": "मुटु रोग विशेषज्ञ",
          "specialtyEn": "Cardiologist",
          "qualification": "MD (Cardiology)",
          "departmentCode": "echo",
          "fee": 1000,
          "startTime": "13:00",
          "endTime": "17:00",
          "weekdays": [
            6
          ],
          "shifts": [
            "afternoon"
          ],
          "saturdayGroup": "last",
          "visiting": true,
          "avatar": "assets/avatars/sujan.png",
          "bioNp": "सहिद गंगालाल मुटु अस्पतालबाट भ्रमणमा आउने वरिष्ठ मुटु रोग विशेषज्ञ; इकोकार्डियोग्राफी सेवा।",
          "bioEn": "Senior visiting cardiologist from Shahid Gangalal Heart Centre; echocardiography service.",
          "availabilityNp": "अन्तिम शनिबार · दिउँसो १–५",
          "availabilityEn": "Last Saturday · 1–5 PM"
        },
        {
          "code": "sarita",
          "nameNp": "सरिता कार्की",
          "nameEn": "Sarita Karki",
          "specialtyNp": "फिजियोथेरापिस्ट",
          "specialtyEn": "Physiotherapist",
          "qualification": "BPT",
          "departmentCode": "physio",
          "fee": 500,
          "startTime": "16:00",
          "endTime": "19:00",
          "weekdays": [
            1,
            2,
            3,
            4,
            5,
            6,
            7
          ],
          "shifts": [
            "afternoon",
            "evening"
          ],
          "saturdayGroup": null,
          "visiting": false,
          "avatar": "assets/avatars/sarita.png",
          "bioNp": "दुखाइ व्यवस्थापन, जोर्नी चलायमान तथा पुनर्स्थापना सेवामा अनुभवी।",
          "bioEn": "Experienced in pain management, joint mobility and rehabilitation.",
          "availabilityNp": "दैनिक · दिउँसो ४–७",
          "availabilityEn": "Daily · 4–7 PM"
        }
      ];
      rows.forEach((row) => {
        app.save(new Record(doctors, row));
      });
    }

    const config = app.findCollectionByNameOrId("clinic_config");
    if (app.countRecords(config) === 0) {
      app.save(new Record(config, { singleton: "clinic", ...{
      "nameNp": "बट्टार सञ्जीवनी पॉलीक्लिनिक",
      "nameEn": "Battar Sanjibani Polyclinic",
      "shortNameNp": "बट्टार सञ्जीवनी",
      "shortNameEn": "Battar Sanjibani",
      "addressNp": "विदुर-२, बट्टार, संगमचोक, नुवाकोट",
      "addressEn": "Bidur 2, Battar, Sangamchowk, Nuwakot",
      "phonePrimary": "010561606",
      "phoneMobile": "9841595025",
      "whatsapp": "9779704513324",
      "email": "info@sanjiwani.com.np",
      "website": "www.sanjiwani.com.np",
      "facebookUrl": "https://www.facebook.com/sanjiwanipolyclinic",
      "mapsUrl": "https://www.google.com/maps/search/?api=1&query=Battar+Sanjibani+Polyclinic+Sangamchowk+Bidur+Nuwakot",
      "openHour": 7,
      "closeHour": 20,
      "specialistCutoffHour": 17
} }));
    }

    const counters = app.findCollectionByNameOrId("counters");
    if (app.countRecords(counters) === 0) {
      app.save(new Record(counters, { key: "patientId", value: 0 }));
    }
  },
  (app) => {
    for (const name of ["counters", "clinic_config", "doctors", "departments"]) {
      const collection = app.findCollectionByNameOrId(name);
      for (const record of app.findRecordsByFilter(collection, "", "", 0, 0)) {
        app.delete(record);
      }
    }
  },
);
