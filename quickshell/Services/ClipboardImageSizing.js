.pragma library

function sourceSize(preview, width, height, pixelRatio) {
    const ratio = pixelRatio > 0 ? pixelRatio : 1;
    const boxWidth = Math.max(1, Math.ceil(width * ratio));
    const boxHeight = Math.max(1, Math.ceil(height * ratio));
    const dimensions = (preview || "").match(/(\d+)x(\d+)\s*\]\]$/);
    if (!dimensions)
        return {width: boxWidth, height: boxHeight};

    const sourceWidth = Number(dimensions[1]);
    const sourceHeight = Number(dimensions[2]);
    if (sourceWidth <= 0 || sourceHeight <= 0)
        return {width: boxWidth, height: boxHeight};

    const scale = Math.min(1, boxWidth / sourceWidth, boxHeight / sourceHeight);
    // A two-axis sourceSize can cover-scale the decoder output; constrain only width.
    return {width: Math.max(1, Math.ceil(sourceWidth * scale)), height: -1};
}
