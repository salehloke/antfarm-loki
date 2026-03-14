/**
 * Tests for the helloWorld function.
 * Verifies function type, return value, and non-throwing behavior.
 */
import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { helloWorld } from "./hello.js";

describe("helloWorld", () => {
  it("is a function", () => {
    assert.equal(typeof helloWorld, "function");
  });

  it("returns void (synchronous)", () => {
    const result = helloWorld();
    assert.equal(result, undefined);
  });

  it("does not throw", () => {
    assert.doesNotThrow(() => {
      helloWorld();
    });
  });
});