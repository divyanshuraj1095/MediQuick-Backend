const https = require("https");

// Call Gemini REST API directly — no SDK version issues
function callGemini(apiKey, prompt) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.4,
        maxOutputTokens: 1024,
      }
    });

    const options = {
      hostname: "generativelanguage.googleapis.com",
      path: `/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`,
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(body),
      },
    };

    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        try {
          const parsed = JSON.parse(data);
          if (parsed.error) {
            reject(new Error(parsed.error.message || "Gemini API error"));
          } else {
            const text = parsed?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
            resolve(text);
          }
        } catch (e) {
          reject(new Error("Failed to parse Gemini response"));
        }
      });
    });

    req.on("error", reject);
    req.write(body);
    req.end();
  });
}

// POST /api/advisor/analyse
exports.analyseSymptoms = async (req, res) => {
  try {
    const { query } = req.body;

    if (!query || query.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: "Please provide a symptom description.",
      });
    }

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      console.error("[Advisor] GEMINI_API_KEY not set in .env");
      return res.status(500).json({
        success: false,
        message: "AI service not configured. GEMINI_API_KEY missing in .env",
      });
    }

    const prompt = `You are a cautious health advisor AI in a pharmacy app.

User's health concern (may be in any language): "${query.trim()}"

Instructions:
- Understand and respond in English regardless of input language
- Suggest 3-5 practical home care tips
- Suggest up to 3 common OTC (over-the-counter) medicines with dosage. Never suggest prescription medicines.
- If symptoms are serious (chest pain, stroke signs, fever >104F/40C, difficulty breathing, severe bleeding): set isSerious=true and suggestDoctor=true
- For mild symptoms: isSerious=false, suggestDoctor=false
- Always include a precaution that the user should consult a doctor if symptoms persist

Return ONLY a raw JSON object, no markdown, no code fences, no extra text:
{"isSerious":false,"suggestDoctor":false,"tips":["tip1","tip2","tip3"],"medicines":[{"name":"Medicine (strength)","dosage":"dosage"}],"precaution":"precaution text. Consult a doctor if symptoms persist or worsen."}`;

    const rawText = await callGemini(apiKey, prompt);

    if (!rawText) {
      throw new Error("Empty response from Gemini");
    }

    // Extract JSON — handle any surrounding text or code fences
    let jsonStr = rawText.trim()
      .replace(/^```json\s*/i, "")
      .replace(/^```\s*/i, "")
      .replace(/```\s*$/i, "")
      .trim();

    // Find JSON object in the text
    const jsonMatch = jsonStr.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      console.error("[Advisor] No JSON found in response:", rawText.substring(0, 200));
      throw new Error("Could not extract JSON from AI response");
    }
    jsonStr = jsonMatch[0];

    const advice = JSON.parse(jsonStr);

    // Normalise all fields
    const safeAdvice = {
      isSerious: advice.isSerious === true,
      suggestDoctor: advice.suggestDoctor === true,
      tips: Array.isArray(advice.tips) ? advice.tips.filter(Boolean) : [],
      medicines: Array.isArray(advice.medicines)
        ? advice.medicines.filter((m) => m && m.name)
        : [],
      precaution:
        typeof advice.precaution === "string" && advice.precaution.length > 0
          ? advice.precaution
          : "This is general advice only. Consult a doctor if symptoms persist or worsen.",
    };

    return res.json({ success: true, query, advice: safeAdvice });

  } catch (error) {
    console.error("[Advisor] Error:", error.message);
    return res.status(500).json({
      success: false,
      message: `Could not analyse symptoms: ${error.message}`,
    });
  }
};
