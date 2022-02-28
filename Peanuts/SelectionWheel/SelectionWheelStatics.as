// Calculates which section of the wheel is selected based on a coordinate that are relative to the center of the wheel.
// The section indicies are assumed to start from the top, and are aligned clock-wise.
UFUNCTION(Category = "SelectionWheel")
int GetSelectionWheelIndexFromCoordinates(int NumSections, float X, float Y)
{
	return GetSelectionWheelIndexFromAngle(
		NumSections,
		FMath::RadiansToDegrees(-FMath::Atan2(-Y, X))
	);
}

// Calculates which section of the wheel is selected based on an angle.
// The angle is degrees, and is that the 0-angle is straight upwards, and it continues clockwise
// The section indicies are assumed to start from the top, and are aligned clockwise.
UFUNCTION(Category = "SelectionWheel")
int GetSelectionWheelIndexFromAngle(int NumSections, float Angle)
{
	// Selection wheel start at the top, so offset angle.
	// Also flip the angles from counter-clockwise to clockwise.
	float SegmentAngle = 360.f / NumSections;

	float WheelAngle = Angle + SegmentAngle * 0.5f;
	if (WheelAngle < 0.f)
		WheelAngle += 360.f;
	if (WheelAngle >= 360.f)
		WheelAngle -= 360.f;

	return int(WheelAngle / SegmentAngle);
}