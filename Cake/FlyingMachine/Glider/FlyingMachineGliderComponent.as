import Peanuts.Spline.SplineComponent;
import Cake.FlyingMachine.FlyingMachineSettings;

event void FOnGliderImpact(FHitResult Hit, float Force);
event void FOnGliderFatalImpact();
event void FOnGliderWindBlowing(FVector Direction, float Force);

class UFlyingMachineGliderComponent : UActorComponent
{
	const FFlyingMachineGliderSettings Settings;

	UFlyingMachineGliderUserComponent RightUser;
	UFlyingMachineGliderUserComponent LeftUser;
	TArray<UHazeSplineComponent> FollowSplines;
	TArray<FHitResult> Hits;

	FRotator Rotation;

	// Speed transitions (controlled by BP)
	float SpeedAnimStart = 0.f;
	float SpeedAnimEnd = 0.f;
	float SpeedAnimDuration = 0.f;
	float SpeedAnimTimer = 0.f;
	bool bShouldAnimSpeed = false;

	UPROPERTY()
	float Speed = Settings.Speed;

	// Events
	UPROPERTY()
	FOnGliderImpact OnImpact;

	UPROPERTY()
	FOnGliderFatalImpact OnFatalImpact;

	UPROPERTY()
	FOnGliderWindBlowing OnWindBlow;

	bool HasBothUsers()
	{
		return RightUser != nullptr && LeftUser != nullptr;
	}

	void TransitionToSpeed(float NewSpeed, float Duration)
	{
		if (Duration <= 0.f)
		{
			// Instant transition
			SpeedAnimStart = SpeedAnimEnd = SpeedAnimDuration = SpeedAnimTimer = 0.f;
			bShouldAnimSpeed = false;
			Speed = NewSpeed;
			return;
		}

		SpeedAnimStart = Speed;
		SpeedAnimEnd = NewSpeed;
		SpeedAnimDuration = Duration;
		SpeedAnimTimer = 0.f;
		bShouldAnimSpeed = true;
	}
}

class UFlyingMachineGliderUserComponent : UActorComponent
{
	UFlyingMachineGliderComponent Glider;
	UHazeSplineComponent Spline;
	float Position;
}