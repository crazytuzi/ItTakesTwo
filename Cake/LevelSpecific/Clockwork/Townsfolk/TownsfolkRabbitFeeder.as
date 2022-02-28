import Cake.LevelSpecific.Clockwork.Townsfolk.TownsfolkActor;

event void FRabbitFeederReachedEnd();

class ATownsfolkRabbitFeeder : ATownsfolkActor
{
	UPROPERTY()
	FRabbitFeederReachedEnd OnRabbitFeederReachedEnd;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnReachedEndOfSpline.AddUFunction(this, n"ReachedEndOfSpline");
	}

	UFUNCTION(NotBlueprintCallable)
	void ReachedEndOfSpline(ATownsfolkActor Actor)
	{
		if (SplineFollow.Position.IsForwardOnSpline())
			OnRabbitFeederReachedEnd.Broadcast();
		else
			System::SetTimer(this, n"StartMoving", 3.f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void StartMoving()
	{
		StartMovingOnSpline(StartingSpline, false);
	}
}