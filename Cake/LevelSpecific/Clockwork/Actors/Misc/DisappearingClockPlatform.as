import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

event void FOnHitTimePlatform();
event void FOnLeftTimePlatform();

UCLASS(Abstract)
class ADisappearingClockPlatform : AHazeActor
{

    UPROPERTY()
    FOnHitTimePlatform OnPressurePlateActivated;
    UPROPERTY()
    FOnLeftTimePlatform OnPressurePlateDeactivated;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
	{
		FOnHitTimePlatform OnPlatformHit;
		// OnPlatformHit.BindUFunction(this, n"PlatformHit");
		// BindOnDownImpacted(this, OnPlatformHit);

		FOnLeftTimePlatform OnPlatformNoLongerHit;
		// OnPlatformNoLongerHit.BindUFunction(this, n"PlatformNoLongerHit");
		// BindOnDownImpactEnded(this, OnPlatformNoLongerHit);
	}

	UFUNCTION()
	void PlatformHit()
	{

	}

	UFUNCTION()
	void PlatformNoLongerHit()
	{

	}

}