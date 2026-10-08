import assert from "node:assert/strict";
import { containsProfanity, mapCommentResponse } from "./jevComment.ts";

const blocked = [
  "co to kurwa jest",
  "k u r w a",
  "k*u*r*w*a",
  "kuuurwa",
  "Chujowa pogoda",
  "Ja pierdolę",
  "spierdalaj",
  "gówno",
  "suka",
  "ty suko",
  "motherfucker",
];

const allowed = [
  "dziękuję za pomoc",
  "thuja uschła przy wejściu",
  "ciotka przyjedzie w sobotę",
  "pedał gazu nie działa",
  "sukienka została w pralni",
  "sukces akcji sprzątania",
  "jesteś miły, dzięki",
  "spotkanie o 18 w sali",
  "kura warta uwagi",
];

for (const sample of blocked) {
  assert.equal(containsProfanity(sample), true, sample);
}
for (const sample of allowed) {
  assert.equal(containsProfanity(sample), false, sample);
}

assert.equal(
  mapCommentResponse({
    answers: {
      is_safe: { type: "noul", noul: 0.91 },
      rejection_reason: { type: "choice", choice: "NONE", confidence: 0.9 },
    },
  }).outcome,
  "ready",
);

assert.deepEqual(
  mapCommentResponse({
    answers: {
      is_safe: { type: "noul", noul: 0.12 },
      rejection_reason: { type: "choice", choice: "PERSONAL_ATTACK", confidence: 0.8 },
    },
  }),
  { is_safe: false, rejection_reason: "PERSONAL_ATTACK", outcome: "blocked" },
);

assert.equal(
  mapCommentResponse({
    answers: {
      is_safe: { type: "noul", noul: 0.12 },
      rejection_reason: { type: "choice", choice: "NONE", confidence: 0.4 },
    },
  }).rejection_reason,
  "PROFANITY",
);

assert.equal(
  mapCommentResponse({
    answers: {
      is_safe: { type: "noul", noul: 0.5 },
      rejection_reason: { type: "choice", choice: "PERSONAL_ATTACK", confidence: 0.8 },
    },
  }).outcome,
  "blocked",
);

assert.equal(
  mapCommentResponse({
    answers: {
      is_safe: { type: "noul", noul: 0.5 },
      rejection_reason: { type: "choice", choice: "NONE", confidence: 0.9 },
    },
  }).outcome,
  "ready",
);

assert.equal(mapCommentResponse({}).outcome, "unavailable");
assert.equal(
  mapCommentResponse({
    answers: {
      is_safe: { type: "noul", noul: 0.5 },
      rejection_reason: { type: "choice", choice: "PERSONAL_ATTACK", confidence: 0.2 },
    },
  }).outcome,
  "ready",
);

console.log("jevComment tests passed");
