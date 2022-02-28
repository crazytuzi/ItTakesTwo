import Vino.Movement.Grinding.UserGrindComponent;

event void FHopscotchGrindCheckActorSignature();

class AHopscotchGrindCheckActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxCollision;

	UPROPERTY()
	FHopscotchGrindCheckActorSignature GrindStarted;
	
	UPROPERTY()
	FHopscotchGrindCheckActorSignature GrindEnded;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UUserGrindComponent GrindingCompMay = UUserGrindComponent::Get(Game::GetMay());
		GrindingCompMay.OnGrindSplineAttached.AddUFunction(this, n"OnGrindStarted");
		GrindingCompMay.OnGrindSplineDetached.AddUFunction(this, n"OnGrindEnded");

		UUserGrindComponent GrindingCompCody = UUserGrindComponent::Get(Game::GetCody());
		GrindingCompCody.OnGrindSplineAttached.AddUFunction(this, n"OnGrindStarted");
		GrindingCompCody.OnGrindSplineDetached.AddUFunction(this, n"OnGrindEnded");
	}

	UFUNCTION()
	void OnGrindStarted(AGrindspline GrindSpline, EGrindAttachReason Reason)
	{
		if (BoxCollision.IsOverlappingActor(Game::GetCody()) || BoxCollision.IsOverlappingActor(Game::GetMay()))
		{
			GrindStarted.Broadcast();
		}
	}

	UFUNCTION()
	void OnGrindEnded(AGrindspline GrindSpline, EGrindDetachReason Reason)
	{
		if (BoxCollision.IsOverlappingActor(Game::GetCody()) || BoxCollision.IsOverlappingActor(Game::GetMay()))
		{
			GrindEnded.Broadcast();
		}
	}
}
