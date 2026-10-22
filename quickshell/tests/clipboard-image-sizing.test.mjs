import assert from "node:assert/strict";
import test from "node:test";
import { loadScript } from "./qml-script.mjs";

const sizing = loadScript(new URL("../Services/ClipboardImageSizing.js", import.meta.url));

for (const [name, dimensions, width, height, dpr, expectedWidth] of [
    ["fractional window scale", "1321x852", 480.3157, 308, 1.5, 717],
    ["wide screenshot fits by width", "1383x213", 480, 308, 1.5, 720],
    ["portrait fits by height", "1000x4000", 480, 308, 1.5, 116],
    ["small image is not enlarged", "100x80", 480, 308, 2, 100],
    ["integer window scale", "3840x2160", 480, 308, 2, 960]
]) {
    test(name, () => {
        const size = sizing.sourceSize(`[[ image 1M png ${dimensions} ]]`, width, height, dpr);
        assert.equal(size.width, expectedWidth);
        assert.equal(size.height, -1);
    });
}

test("unknown dimensions use a bounded decode box", () => {
    for (const preview of [undefined, "", "image", "[[ image png 0x0 ]]"]) {
        const size = sizing.sourceSize(preview, 480, 308, 1.5);
        assert.equal(size.width, 720);
        assert.equal(size.height, 462);
    }
});
