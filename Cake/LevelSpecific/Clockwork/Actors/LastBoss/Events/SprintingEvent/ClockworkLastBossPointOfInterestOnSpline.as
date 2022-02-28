import Peanuts.Spline.SplineComponent;
class AClockworkLastBossPointOfInterestOnSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FocusTargetComp;

	UPROPERTY()
	AHazeSplineActor ConnectedSpline;

	UHazeSplineComponent SplineComp;

	UPROPERTY()
	EHazePlayer PlayerToFollow;

	AHazePlayerCharacter Player;
	float DistanceOffset = 1800.f;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (PlayerToFollow == EHazePlayer::Cody)
			Player = Game::GetCody();
		else
			Player = Game::GetMay();

		SplineComp = UHazeSplineComponent::Get(ConnectedSpline);
	}
	

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Player == nullptr)
			return;

		float PlayerDistOnSpline = SplineComp.GetDistanceAlongSplineAtWorldLocation(Player.GetActorLocation());
		FVector NewPoiLocation = SplineComp.GetLocationAtDistanceAlongSpline(PlayerDistOnSpline + DistanceOffset, ESplineCoordinateSpace::World);
		FocusTargetComp.SetWorldLocation(NewPoiLocation);
		
		FHazePointOfInterest Poi;
		Poi.FocusTarget.Component = FocusTargetComp;
		Poi.Blend.BlendTime = 0.25f;
		
		Player.ApplyClampedPointOfInterest(Poi, this);
	}

	UFUNCTION()
	void SetPointOfInterestOnSplineActive(bool bActive)
	{
		if (bActive)
			SetActorTickEnabled(true);
		else
		{
			SetActorTickEnabled(false);
			Player.ClearPointOfInterestByInstigator(this);
		}
	}
}