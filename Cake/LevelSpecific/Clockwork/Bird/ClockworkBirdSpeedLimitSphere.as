import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingComponent;
class AClockworkBirdSpeedLimitSphere : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent SpeedLimitSphere;
	default SpeedLimitSphere.SetCollisionProfileName(n"TriggerPlayerOnly");

	// Speed limit on the inside of the sphere
	UPROPERTY()
	float InnerSpeedLimit = 1500.f;

	// Radius of the inside of the sphere with the lowest speed limit
	UPROPERTY()
	float InnerSpeedLimitRadius = 0.f;

	UPROPERTY(Meta = (InlineEditConditionToggle))
	bool bLimitAcceleration = false;

	// Acceleration limit on the inside of the sphere. If set to 0 acceleration is not limited
	UPROPERTY(Meta = (EditCondition = "bLimitAcceleration"))
	float InnerAccelerationLimit = 1000.f;

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		auto FlyingComp = UClockworkBirdFlyingComponent::GetOrCreate(Player);
		FlyingComp.SpeedLimitActors.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		auto FlyingComp = UClockworkBirdFlyingComponent::Get(Player);
		if (FlyingComp != nullptr)
			FlyingComp.SpeedLimitActors.Remove(this);
	}

	float GetSpeedLimitAtPosition(FVector Position, float BaseMaxSpeed)
	{
		float Distance = Position.Distance(ActorLocation);
		if (Distance <= InnerSpeedLimitRadius)
			return InnerSpeedLimit;
		float Percentage =  (Distance - InnerSpeedLimitRadius) / (SpeedLimitSphere.ScaledSphereRadius - InnerSpeedLimitRadius);
		return FMath::Lerp(InnerSpeedLimit, BaseMaxSpeed, Percentage);
	}

	float GetAccelerationLimitAtPosition(FVector Position, float BaseAcceleration)
	{
		if (!bLimitAcceleration)
			return BaseAcceleration;

		float Distance = Position.Distance(ActorLocation);
		if (Distance <= InnerSpeedLimitRadius)
			return InnerAccelerationLimit;
		float Percentage =  (Distance - InnerSpeedLimitRadius) / (SpeedLimitSphere.ScaledSphereRadius - InnerSpeedLimitRadius);
		return FMath::Lerp(InnerAccelerationLimit, BaseAcceleration, Percentage);
	}

};