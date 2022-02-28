import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonTargetOscillation;
import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonToShootMarbleActor;
import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonToShootMarblePlayerComponent;

event void FBalloonPoppedSignature();

class ACannonTargetActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Oscillation)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent FX;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BalloonPopAudioEvent;

	UPROPERTY(DefaultComponent)
	UCannonTargetOscillation Oscillation;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 20000.f;
	default DisableComponent.bRenderWhileDisabled = true;

	bool bIsDestroyed = false;
	UCannonToShootMarblePlayerComponent ActivePlayerComponent;
	AHazePlayerCharacter ActivePlayer;
	float DistanceCheck;

	ACannonToShootMarbleActor CannonActor;

	UPROPERTY()
	FBalloonPoppedSignature OnBalloonPopped;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{


		FVector Bounds;
		FVector Center;
		GetActorBounds(true, Center, Bounds);
		DistanceCheck = Bounds.Size() * 2;
		DistanceCheck = FMath::Square(DistanceCheck);
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// We need to do this on tick since there are ballons on different levels than the canon
		if(CannonActor == nullptr)
		{
			TArray<AActor> FoundActors;
			Gameplay::GetAllActorsOfClass(ACannonToShootMarbleActor::StaticClass(), FoundActors);

			if(FoundActors.Num() == 0)
				return;
		
			CannonActor = Cast<ACannonToShootMarbleActor>(FoundActors[0]);
			CannonActor.OnShootCannon.AddUFunction(this, n"OnShootCannon");
			CannonActor.OnPlayerHitSometing.AddUFunction(this, n"OnPlayerHitSometing");
		}

		// If the player is flying trough the air
		// We test the collision
		// This is a cheap way instead of doing bGenerateOverlapEvents
		if(ActivePlayer != nullptr && !bIsDestroyed && ActivePlayer.GetActorLocation().DistSquared(GetActorLocation()) < DistanceCheck)
		{
			if (Trace::ComponentOverlapComponent(
				ActivePlayer.CapsuleComponent,
				Mesh,
				Mesh.WorldLocation,
				Mesh.ComponentQuat,
				bTraceComplex = false
			))
			{
				auto CrumbComp = UHazeCrumbComponent::Get(ActivePlayer);
				FHazeDelegateCrumbParams CrumbParams;
				CrumbParams.AddObject(n"OtherActor", ActivePlayer);
				CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_MarkerHit"), CrumbParams);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnShootCannon(AHazePlayerCharacter Player)
	{
		if(!Player.HasControl())
				return;

		auto PlayerComponent = UCannonToShootMarblePlayerComponent::Get(Player);
		if(PlayerComponent == nullptr)
			return;

		if(!PlayerComponent.bIsBeeingShot)
			return;

		ActivePlayer = Player;
		ActivePlayerComponent = PlayerComponent;	
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnPlayerHitSometing(AHazePlayerCharacter Player)
	{
		ActivePlayerComponent = nullptr;
		ActivePlayer = nullptr;
	}

	UFUNCTION(NotBlueprintCallable)
	protected void Crumb_MarkerHit(const FHazeDelegateCrumbData& CrumbData)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"OtherActor"));
		PlayhitBalloonEffects(Player);
	}

	UFUNCTION()
	void PlayhitBalloonEffects(AHazePlayerCharacter Player)
	{
		if(ActivePlayerComponent != nullptr)
			ActivePlayerComponent.bHitBaloon = true;
			
		bIsDestroyed = true;
		FX.Activate(true);
		Mesh.SetHiddenInGame(true);
		OnBalloonPopped.Broadcast();

		UHazeAkComponent::HazePostEventFireForget(BalloonPopAudioEvent, this.GetActorTransform());
	}
}