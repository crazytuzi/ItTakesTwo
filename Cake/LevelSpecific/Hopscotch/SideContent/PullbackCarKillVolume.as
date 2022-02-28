import Cake.LevelSpecific.Hopscotch.SideContent.PullbackCar;
class APullbackCarKillVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent KillCollision;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		KillCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnCollisionOverlap");
	}

	UFUNCTION()
	void OnCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		APullbackCar Car = Cast<APullbackCar>(OtherActor);
		if (Car == nullptr)
			return;

		if (!Car.HasControl())
			return;

		if(Car.CurrentMovementState != EPullBackCarMovementState::Released)
			return;

		auto CrumbComp = UHazeCrumbComponent::Get(Car);
		FHazeDelegateCrumbParams Params;
		Params.AddObject(n"Car", Car);
		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_KillCar"), Params);
		//Car.DestroyCarFromKillCollision();
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_KillCar(const FHazeDelegateCrumbData& CrumbData)
	{
		APullbackCar Car = Cast<APullbackCar>(CrumbData.GetObject(n"Car"));
		if(Car == nullptr)
			return;

		Car.DestroyCarLocally();
	}
}