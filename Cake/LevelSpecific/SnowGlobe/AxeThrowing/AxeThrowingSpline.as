import Peanuts.Spline.SplineActor;
import Vino.Movement.Grinding.GrindSpline;

enum EAxeThrowingTargetOrientation
{
	Upright,
	SidewaysRightSide,
	SidewaysLeftSide
}

class AAxeThrowingSpline : AGrindspline
{
	UPROPERTY(Category = "Setup")
	float TargetSpeed = 150.f;

	UPROPERTY(Category = "Setup")
	float DelayDuration = 3.f;

	UPROPERTY(Category = "Setup")
	bool bBackAndForth = false;

	UPROPERTY(Category = "Setup")
	EAxeThrowingTargetOrientation TargetOrientation;

	default StartConnection.bEnabled = false;
	default EndConnection.bEnabled = false;

	// Transient values for game logic
	float SpawnTimer = 0.f;
	int CurrentTargetCount = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bGrindingAllowed = false;
	}
}
