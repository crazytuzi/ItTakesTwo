import Peanuts.Triggers.PlayerTrigger;
import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledTags;
import Peanuts.Spline.SplineActor;
import Cake.LevelSpecific.SnowGlobe.Boatsled.Capabilities.BoatsledChimneyFallThroughCapability;

class ABoatsledChimneyCrashTrigger : APlayerTrigger
{
	UPROPERTY()
	ASplineActor ChimneyFallTrajectorySpline;

	UPROPERTY()
	AActor SplineTrackAfterChimneyFallthrough;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ensure(ChimneyFallTrajectorySpline != nullptr, "BoatsledChimneyCrashTrigger: reference to the trajectory spline is null!");
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnteredChimneyCrashTrigger");
		Super::BeginPlay();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerEnteredChimneyCrashTrigger(AHazePlayerCharacter PlayerCharacter)
	{
		if(!PlayerCharacter.HasControl())
			return;

		if(ChimneyFallTrajectorySpline == nullptr)
			return;

		UBoatsledComponent BoatsledComponent = UBoatsledComponent::Get(PlayerCharacter);
		if(BoatsledComponent == nullptr)
			return;

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"BoatsledComponent", BoatsledComponent);
		BoatsledComponent.Boatsled.CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"OnPlayerEnteredChimneyCrashTrigger_Crumb"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerEnteredChimneyCrashTrigger_Crumb(const FHazeDelegateCrumbData& CrumbData)
	{
		UBoatsledComponent BoatsledComponent = Cast<UBoatsledComponent>(CrumbData.GetObject(n"BoatsledComponent"));
		BoatsledComponent.BoatsledEventHandler.OnBoatsledFallingThroughChimney.Broadcast(ChimneyFallTrajectorySpline.Spline, UHazeSplineComponent::Get(SplineTrackAfterChimneyFallthrough));
	}
}