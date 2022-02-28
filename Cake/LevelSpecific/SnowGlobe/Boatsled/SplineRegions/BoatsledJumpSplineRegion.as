import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledState;
import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledJumpCameraSettings;
import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;

class UBoatsledJumpSplineRegionComponent : UHazeSplineRegionComponent
{
	UPROPERTY(Meta = (MakeEditWidget))
	FVector BoatsledLandingLocation;

	UPROPERTY(Meta = (MakeEditWidget))
	FVector BoatsledJumpHeight;


	UPROPERTY(Category = "Camera")
	FBoatsledJumpCameraSettings JumpCameraSettings;


	UPROPERTY(Category = "Next State")
	EBoatsledState BoatsledStateAfterLanding;

	UPROPERTY(Category = "Next State")
	AActor LandingBoatsledTrack;

	UPROPERTY(Category = "Next State")
	float TrackRadius = 500.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(LandingBoatsledTrack == nullptr)
			Warning(Name + " (BoatsledJumpSplineRegion): LandingBoatsledTrack actor reference is null!");
	}

	UFUNCTION(BlueprintOverride)
	void OnRegionEntered(AHazeActor EnteringActor)
	{
		if(!EnteringActor.IsA(ABoatsled::StaticClass()))
			return;

		if(!EnteringActor.HasControl())
			return;

		ABoatsled Boatsled = Cast<ABoatsled>(EnteringActor);
		Boatsled.BoatsledEventHandler.OnBoatsledPreJumpRubberBand.Broadcast(SplineRegion.EndPointDistance);
	}

	UFUNCTION(BlueprintOverride)
	void OnRegionExit(AHazeActor ExitingActor, ERegionExitReason ExitReason)
	{
		if(ExitReason != ERegionExitReason::PassedEnd)
			return;

		if(!ExitingActor.IsA(ABoatsled::StaticClass()))
			return;

		ABoatsled Boatsled = Cast<ABoatsled>(ExitingActor);
		UBoatsledComponent PlayerBoatsledComponent = UBoatsledComponent::Get(Boatsled.CurrentBoatsledder);
		if(PlayerBoatsledComponent.IsJumping())
			return;

		// Jumps are handled locally for replication prediction purposes
		Boatsled.BoatsledEventHandler.OnBoatsledStartingJump.Broadcast(MakeJumpParams(Boatsled.ActorLocation));

		// Set track radius to be used after landing
		PlayerBoatsledComponent.TrackRadius = TrackRadius;
	}

	UFUNCTION(BlueprintOverride)
	FLinearColor GetTypeColor() const
	{
		return FLinearColor::Green;
	}

	FBoatsledJumpParams MakeJumpParams(FVector BoatsledLocation)
	{
		FBoatsledJumpParams JumpParams;
		JumpParams.LandingLocation = WorldTransform.TransformPosition(BoatsledLandingLocation);
		JumpParams.JumpHeight = FMath::Abs(WorldTransform.TransformPosition(BoatsledJumpHeight).Z - BoatsledLocation.Z);
		JumpParams.JumpCameraSettings = JumpCameraSettings;
		JumpParams.NextBoatsledState = BoatsledStateAfterLanding;

		// Not so nice but practical; whale's spline actor owns three spline components
		FName SplineName = BoatsledStateAfterLanding == EBoatsledState::WhaleSledding ? n"HazeGuideSpline" : NAME_None;
		JumpParams.TrackSplineComponent = UHazeSplineComponent::Get(LandingBoatsledTrack, SplineName);

		return JumpParams;
	}
}