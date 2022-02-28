
/**
 * Prototype your math function here. Let a coder know once you're
 * done with it and they'll move it down to .cpp, making it
 * accesible anywhere in angelscript via the Math:: namespace.
 * 
 * comment out the prototyped function once it's been 
 * moved to code. That way one can still see the workings
 * behind the function in angelscript as well. 
 * 
 * The prototyped function will be moved to HazeMathStatic.cpp in c++
 */


// PROTOTYPING AREA

// Constrains Source and Target to Axis and rotates your non-constrained source around the Axis
// Will not reach the target if the axis does not allow it to do so
FVector RotateVectorTowardsAroundAxis(FVector Source, FVector Target, FVector Axis, float AngleDeg)	
{
	FVector AxisNormalized = Axis.GetSafeNormal();
	FVector ConstrainedSource = Source.ConstrainToPlane(AxisNormalized).GetSafeNormal();
	FVector ConstrainedTarget = Target.ConstrainToPlane(AxisNormalized).GetSafeNormal();

	float SourceTargetDot = ConstrainedSource.DotProduct(ConstrainedTarget);
	float AngleDifference = FMath::Acos(SourceTargetDot);

	FVector RotationAxis = ConstrainedSource.CrossProduct(ConstrainedTarget);
	FQuat RotationQuat = FQuat(RotationAxis.GetSafeNormal(), FMath::Min(AngleDifference, AngleDeg * DEG_TO_RAD));
	
	return RotationQuat * Source;
}

// Constrains Source and Target to Axis and rotates your non-constrained source around the Axis
// Will not reach the target if the axis does not allow it to do so
FVector SlerpVectorTowardsAroundAxis(FVector Source, FVector Target, FVector Axis, float Alpha)	
{
	FVector AxisNormalized = Axis.GetSafeNormal();
	FVector ConstrainedSource = Source.ConstrainToPlane(AxisNormalized).GetSafeNormal();
	FVector ConstrainedTarget = Target.ConstrainToPlane(AxisNormalized).GetSafeNormal();

	float SourceTargetDot = ConstrainedSource.DotProduct(ConstrainedTarget);
	float AngleDifference = FMath::Acos(SourceTargetDot);

	FVector RotationAxis = ConstrainedSource.CrossProduct(ConstrainedTarget);
	FQuat RotationQuat = FQuat(RotationAxis.GetSafeNormal(), AngleDifference * Alpha);
	
	return RotationQuat * Source;
}

FLinearColor LerpColor(FLinearColor A, FLinearColor B, float Alpha)
{
	FLinearColor AA = FLinearColor(A.R * A.R, A.G * A.G, A.B * A.B, A.A * A.A);
	FLinearColor BB = FLinearColor(B.R * B.R, B.G * B.G, B.B * B.B, B.A * B.A);
	FLinearColor AB = ((AA) * (1 - Alpha)) + (BB * Alpha);
	
	return FLinearColor(FMath::Sqrt(AB.R), FMath::Sqrt(AB.G), FMath::Sqrt(AB.B), FMath::Sqrt(AB.A));
}

// Spaces the colors equally across the 0-1 alpha, and lerps linearly between two of the nearest colours
FLinearColor LerpColors(TArray<FLinearColor> Colors, float Alpha)
{
	if (Colors.Num() == 0)
		return FLinearColor::Black;

	if (Colors.Num() <= 1)
		return Colors[0];

	if (FMath::IsNearlyZero(Alpha))
		return Colors[0];

	if (Alpha >= (1.f - SMALL_NUMBER))
		return Colors.Last();

	float DecimalIndex = Alpha * (Colors.Num() - 1);
	int StarIndex = FMath::FloorToInt(DecimalIndex);

	FLinearColor A = Colors[StarIndex];
	FLinearColor B = Colors[StarIndex + 1];

	float RealAlpha = DecimalIndex;
	if (StarIndex != 0)
		RealAlpha = DecimalIndex % StarIndex;

	return LerpColor(A, B, RealAlpha);
}

UFUNCTION(BlueprintPure)
float GetDistanceToNearestPlayer(FVector WorldLocation)
{
	float Distance = BIG_NUMBER;
	for (AHazePlayerCharacter Player : Game::Players)
	{
		float DistanceToPlayer = (Player.ActorLocation - WorldLocation).Size();
		if (DistanceToPlayer < Distance)
			Distance = DistanceToPlayer;
	}

	return Distance;
}

UFUNCTION()
AHazePlayerCharacter GetNearestPlayer(FVector WorldLocation, float& Distance)
{
	AHazePlayerCharacter NearestPlayer = nullptr;
	float _Distance = BIG_NUMBER;

	for (AHazePlayerCharacter Player : Game::Players)
	{
		float DistanceToPlayer = (Player.ActorLocation - WorldLocation).Size();
		if (DistanceToPlayer < _Distance)
		{
			_Distance = DistanceToPlayer;
			NearestPlayer = Player;
		}
	}

	Distance = _Distance;
	return NearestPlayer;
}

UFUNCTION()
void GetDistanceToPlayers(float& DistanceToMay, float& DistanceToCody, FVector WorldLocation)
{	
	for (AHazePlayerCharacter Player : Game::Players)
	{
		if (Player.IsMay())
			DistanceToMay = (Player.ActorLocation - WorldLocation).Size();
		else
			DistanceToCody = (Player.ActorLocation - WorldLocation).Size();
	}
}

UFUNCTION(BlueprintPure)
float GetDistanceBetweenPlayers()
{	
	return (Game::May.ActorLocation - Game::Cody.ActorLocation).Size();
}

UFUNCTION(BlueprintPure, Category = "Math")
float GetAngleBetweenVectorsAroundAxis(FVector From, FVector To, FVector Axis)
{
	FVector From_Flat = From.ConstrainToPlane(Axis).GetSafeNormal();
	FVector To_Flat = To.ConstrainToPlane(Axis).GetSafeNormal();
	FVector AxisNormalized = Axis.GetSafeNormal();

	float CrossAngle = From_Flat.CrossProduct(To_Flat).DotProduct(AxisNormalized);
	float DotAngle = From_Flat.DotProduct(To_Flat);

	return FMath::RadiansToDegrees(FMath::Acos(DotAngle) * FMath::Sign(CrossAngle));
}

UFUNCTION()
float GetMappedRangeValueClamped(float InputMin, float InputMax, float OutputMin, float OutputMax, float Value)
{
	FVector2D InputRange = FVector2D(InputMin, InputMax);
	FVector2D OutputRange = FVector2D(OutputMin, OutputMax);

	return FMath::GetMappedRangeValueClamped(InputRange, OutputRange, Value);
}

UFUNCTION()
float GetMappedRangeValueUnclamped(float InputMin, float InputMax, float OutputMin, float OutputMax, float Value)
{
	FVector2D InputRange = FVector2D(InputMin, InputMax);
	FVector2D OutputRange = FVector2D(OutputMin, OutputMax);

	return FMath::GetMappedRangeValueUnclamped(InputRange, OutputRange, Value);
}

// Function taken from Scene Management - was used for setting the minimum drawing size for HISM so why not all props?
UFUNCTION()
float ComputeBoundsDrawDistance(const float ScreenSize, const float SphereRadius, const FMatrix& ProjMatrix)
{
	// Get projection multiple accounting for view scaling.
	const float ScreenMultiple = FMath::Max(0.5f * ProjMatrix.XPlane.X, 0.5f * ProjMatrix.YPlane.Y);

	// ScreenSize is the projected diameter, so halve it
	const float ScreenRadius = FMath::Max(SMALL_NUMBER, ScreenSize * 0.5f);

	// Invert the calcs in ComputeBoundsScreenSize
	return (ScreenMultiple * SphereRadius) / ScreenRadius;
}

// Sets the cull distance on the mesh to a reasonable default value.
UFUNCTION()
void SetSizeBasedCullDistance(UPrimitiveComponent Comp, float CullDistanceMultiplier)
{
	if(Comp == nullptr)
		return;

	Comp.SetCullDistance(Editor::GetDefaultCullingDistance(Comp) * CullDistanceMultiplier);
}

// Moves current value towards target value by a fixed value without overshooting.
float MoveTowards(float Current, float Target, float StepSize)
{
	return Current + FMath::Clamp(Target - Current, -StepSize, StepSize);
}

// Moves current value towards target value by a fixed distance without overshooting.
FVector MoveTowards(FVector Current, FVector Target, float StepSize)
{
	FVector Delta = Target - Current;
	float Distance = Delta.Size();
	float ClampedDistance = FMath::Min(Distance, StepSize);
	FVector Direction = Delta / Distance;
	return Current + Direction * ClampedDistance;
}
