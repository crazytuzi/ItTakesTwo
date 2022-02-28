import Vino.Movement.Components.MovementComponent;

class UWaspMovementComponent : UHazeMovementComponent
{
	// Whenever we're following a spline, we apply this offset in world space to spline location
	UPROPERTY()
	FVector SplineWorldOffset = FVector::ZeroVector;

	// Whenever we're following a spline, we apply this offset in spline transform local space to spline location
	UPROPERTY()
	FVector SplineLocalOffset = FVector::ZeroVector;

	UHazeAkComponent AudioComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		AudioComp = UHazeAkComponent::Get(Owner);
		AudioComp.SetRTPCValue("Rtpc_Characters_Enemies_Wasps_VelocityDelta", 0.f, 200);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		//Super::Tick(DeltaTime); // No super currently so can't do this :P
		if ((PreviousVelocity - Velocity).SizeSquared() > 10.f*10.f)
			AudioComp.SetRTPCValue("Rtpc_Characters_Enemies_Wasps_VelocityDelta", Velocity.Size(), 200);
	}
}
