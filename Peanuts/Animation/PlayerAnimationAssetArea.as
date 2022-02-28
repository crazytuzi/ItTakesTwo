

class APlayerAnimationAssetArea : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default SetActorTickEnabled(false);

	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent Root;
	default Root.BoxExtent = FVector(100.f);
	default Root.CollisionProfileName = n"Trigger";

	UPROPERTY(EditInstanceOnly, Category = "Activation")
	TArray<AVolume> AdditionalShapes;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionStateMachineAsset CodyAnimationAsset;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionStateMachineAsset MayAnimationAsset;

	TPerPlayer<int> OverlappingShapeCount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"OnTriggerBeginOverlap");
		OnActorEndOverlap.AddUFunction(this, n"OnTriggerEndOverlap");

		for(auto Shape : AdditionalShapes)
		{
			if(Shape == nullptr)
				continue;

			Shape.OnActorBeginOverlap.AddUFunction(this, n"OnTriggerBeginOverlap");
			Shape.OnActorEndOverlap.AddUFunction(this, n"OnTriggerEndOverlap");
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnTriggerBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;
		
		OverlappingShapeCount[Player.Player]++;
		if(OverlappingShapeCount[Player.Player] == 1)
		{
			if(Player.IsCody())
				Player.AddLocomotionAsset(CodyAnimationAsset, this, 200);
			else
				Player.AddLocomotionAsset(MayAnimationAsset, this, 200);
		}
	}	

	UFUNCTION(NotBlueprintCallable)
   	private void OnTriggerEndOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;
	
		OverlappingShapeCount[Player.Player]--;
		if(OverlappingShapeCount[Player.Player] == 0)
		{
			if(Player.IsCody())
				Player.RemoveLocomotionAsset(CodyAnimationAsset, this);
			else
				Player.RemoveLocomotionAsset(MayAnimationAsset, this);
		}
	}
}

