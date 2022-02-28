import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;

class ASwimmingVortex : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent VortexRoot;

	UPROPERTY(DefaultComponent, Attach = VortexRoot)
	UCapsuleComponent CapsuleComp;
	default CapsuleComp.CapsuleRadius = 400.f;
	default CapsuleComp.CapsuleHalfHeight = 3000.f;

	FSwimmingVortexData VortexData;

	// Distance from the top/bottom of capsule
	UPROPERTY(meta=(ClampMin="25.0", UIMin="25.0"))
	const float VerticalHardLimitMargin = 50.f;
	
#if EDITOR
    default bRunConstructionScriptOnDrag = true;
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
//		CapsuleComp.SetRelativeLocation(FVector(CapsuleComp.RelativeLocation.X, CapsuleComp.RelativeLocation.Y, CapsuleComp.CapsuleHalfHeight - CapsuleComp.CapsuleRadius));
	}

	UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        USnowGlobeSwimmingComponent SwimComp = USnowGlobeSwimmingComponent::Get(OtherActor);
	
		if (SwimComp == nullptr)
			return;

		VortexData.VortexTransform = CapsuleComp.WorldTransform;
		VortexData.CapsuleRadius = CapsuleComp.CapsuleRadius;
		VortexData.CapsuleHalfHeight = CapsuleComp.CapsuleHalfHeight;
		VortexData.HardLimitMargin = VerticalHardLimitMargin;

		SwimComp.bVortexActive = true;
		SwimComp.ActiveVortexData = VortexData;
		SwimComp.EnteredSwimmingVolume();
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
        USnowGlobeSwimmingComponent SwimComp = USnowGlobeSwimmingComponent::Get(OtherActor);

		if(SwimComp == nullptr)
			return;

		SwimComp.bVortexActive = false;
		SwimComp.LeftSwimmingVolume();
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
	//	VortexData.VortexTransform = VortexRoot.Transform;
	//	SwimComp.ActiveVortexData = VortexData;
	}
}