import Cake.LevelSpecific.Hopscotch.BallFallValve;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Hopscotch.BallFallStatics;
import Vino.Checkpoints.Volumes.DeathVolume;
import Cake.LevelSpecific.Hopscotch.BallFallPlatform;

event void FBallFallTubeSignature(int Intensity);

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class ABallFallTube : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent TubeMesh;
	default TubeMesh.RelativeLocation = FVector(-981.f, 25.f, 523.f);
	default TubeMesh.RelativeRotation = FRotator(0.f, 0.f, 45.f);
	default TubeMesh.RelativeScale3D = FVector(31.f, 5.f, 7.f);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent BallFallYellowFX;
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent BallFallYellowFXDistant;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent BallFallRedFX;
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent BallFallRedFXDistant;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent BallFallBlueFX;
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent BallFallBlueFXDistant;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent BallFallGreenFX;
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent BallFallGreenFXDistant;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent BallFallWhiteFX;
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent BallFallWhiteFXDistant;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DeathVolume;
	default DeathVolume.RelativeLocation = FVector(-966.f, 0.f, -2632.f);
	default DeathVolume.BoxExtent = FVector(1650.f, 32.f, 3250.f);

	UPROPERTY()
	bool bUseExternalDeathVolume = false;

	UPROPERTY()
	bool bMainBallFall = false;

	UPROPERTY()
	ADeathVolume ExternalDeathVolume;

	UPROPERTY()
	TArray <ABallFallPlatform> BallFallPlatforms;

	UPROPERTY()
	FLinearColor YellowColor;

	UPROPERTY()
	FLinearColor RedColor;

	UPROPERTY()
	FLinearColor BlueColor;

	UPROPERTY()
	FLinearColor GreenColor;

	UPROPERTY()
	FLinearColor WhiteColor;

	UPROPERTY()
	bool bYellowActive = true;

	UPROPERTY()
	bool bRedActive = true;

	UPROPERTY()
	bool bBlueActive = true;

	UPROPERTY()
	bool bGreenActive = true;

	UPROPERTY()
	bool bWhiteActive = true;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY()
	FBallFallTubeSignature AudioBallFallChangedIntensity;

	UPROPERTY()
	int NumberOfValvesToDeactive = 0;

	int BallFallIntensity = 3;


    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		float LodDistance = 2000;
		BallFallYellowFX.LDMaxDrawDistance = LodDistance;
		BallFallYellowFXDistant.MinDrawDistance = LodDistance;
		BallFallRedFX.LDMaxDrawDistance = LodDistance;
		BallFallRedFXDistant.MinDrawDistance = LodDistance;
		BallFallBlueFX.LDMaxDrawDistance = LodDistance;
		BallFallBlueFXDistant.MinDrawDistance = LodDistance;
		BallFallGreenFX.LDMaxDrawDistance = LodDistance;
		BallFallGreenFXDistant.MinDrawDistance = LodDistance;
		BallFallWhiteFX.LDMaxDrawDistance = LodDistance;
		BallFallWhiteFXDistant.MinDrawDistance = LodDistance;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DeathVolume.OnComponentBeginOverlap.AddUFunction(this, n"DeathVolumeOverlap");
		bYellowActive ? BallFallYellowFX.Activate() : BallFallYellowFX.Deactivate(); 
		bYellowActive ? BallFallYellowFXDistant.Activate() : BallFallYellowFXDistant.Deactivate(); 
		bRedActive ? BallFallRedFX.Activate() : BallFallRedFX.Deactivate(); 
		bRedActive ? BallFallRedFXDistant.Activate() : BallFallRedFXDistant.Deactivate(); 
		bBlueActive ? BallFallBlueFX.Activate() : BallFallBlueFX.Deactivate(); 
		bBlueActive ? BallFallBlueFXDistant.Activate() : BallFallBlueFXDistant.Deactivate(); 
		bGreenActive ? BallFallGreenFX.Activate() : BallFallGreenFX.Deactivate();
		bGreenActive ? BallFallGreenFXDistant.Activate() : BallFallGreenFXDistant.Deactivate(); 
		bWhiteActive ? BallFallWhiteFX.Activate() : BallFallWhiteFX.Deactivate(); 
		bWhiteActive ? BallFallWhiteFXDistant.Activate() : BallFallWhiteFXDistant.Deactivate();

		BallFallYellowFX.SetNiagaraVariableLinearColor("User.Color", YellowColor);
		BallFallYellowFXDistant.SetNiagaraVariableLinearColor("User.Color", YellowColor);
		BallFallRedFX.SetNiagaraVariableLinearColor("User.Color", RedColor);
		BallFallRedFXDistant.SetNiagaraVariableLinearColor("User.Color", RedColor);
		BallFallBlueFX.SetNiagaraVariableLinearColor("User.Color", BlueColor);
		BallFallBlueFXDistant.SetNiagaraVariableLinearColor("User.Color", BlueColor);
		BallFallGreenFX.SetNiagaraVariableLinearColor("User.Color", GreenColor);
		BallFallGreenFXDistant.SetNiagaraVariableLinearColor("User.Color", GreenColor);
		BallFallWhiteFX.SetNiagaraVariableLinearColor("User.Color", WhiteColor);
		BallFallWhiteFXDistant.SetNiagaraVariableLinearColor("User.Color", WhiteColor);
		//BallFallGreenFX.SetFloatParameter(n"User.SpawnRate", 850.f);


	}

	UFUNCTION()
    void DeathVolumeOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
        if (bUseExternalDeathVolume)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			if (Player.HasControl())
			{
				KillPlayer(Player, DeathEffect);
			}
		}
    }
	
	UFUNCTION(NetFunction)
	void NetBallColorDeactivated(EValveColor ValveColor)
	{
		switch (ValveColor)
		{
			case EValveColor::Yellow:
				if (!bYellowActive)
					return;

				bYellowActive = false;
				BallFallYellowFX.Deactivate();
				BallFallYellowFXDistant.Deactivate();
				NumberOfValvesToDeactive--;
				break;
				

			case EValveColor::Red:
				if (!bRedActive)
					return;

				BallFallRedFX.Deactivate();
				BallFallRedFXDistant.Deactivate();
				NumberOfValvesToDeactive--;
				break;

			case EValveColor::Blue:
				if (!bBlueActive)
					return;

				BallFallBlueFX.Deactivate();
				BallFallBlueFXDistant.Deactivate();
				NumberOfValvesToDeactive--;
				break;

			case EValveColor::Green:
				if (!bGreenActive)
					return;

				BallFallGreenFX.Deactivate();
				BallFallGreenFXDistant.Deactivate();
				NumberOfValvesToDeactive--;
				break;

			case EValveColor::White:
				if (!bWhiteActive)
					return;

				BallFallWhiteFX.Deactivate();
				BallFallWhiteFXDistant.Deactivate();
				NumberOfValvesToDeactive--;
				break;
		}

		BallFallIntensity--;
		AudioBallFallChangedIntensity.Broadcast(BallFallIntensity);

		if (HasControl())
		{
			if (NumberOfValvesToDeactive <= 0)
			{
				NetSetBoxCollisionDisabled();
			
				if (BallFallPlatforms.Num() > 0)
				{
					NetMovePlatforms();
				}
			}			
		}
	}

	void SetBallFallSpawnRate(EValveColor ValveColor, float NewSpawnRate, AHazePlayerCharacter PlayerInteracting)
	{
		switch (ValveColor)
		{
			case EValveColor::Yellow:
				BallFallYellowFX.SetFloatParameter(n"User.SpawnRate", FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(550.f, 0.f), NewSpawnRate));
				BallFallYellowFXDistant.SetFloatParameter(n"User.SpawnRate", FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(550.f, 0.f), NewSpawnRate));
				if (NewSpawnRate >= 1.f && PlayerInteracting.HasControl())
					NetBallColorDeactivated(ValveColor);
				
				break;

			case EValveColor::Red:
				BallFallRedFX.SetFloatParameter(n"User.SpawnRate", FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(550.f, 0.f), NewSpawnRate));
				BallFallRedFXDistant.SetFloatParameter(n"User.SpawnRate", FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(550.f, 0.f), NewSpawnRate));
				if (NewSpawnRate >= 1.f && PlayerInteracting.HasControl())
					NetBallColorDeactivated(ValveColor);

				break;

			case EValveColor::Blue:
				BallFallBlueFX.SetFloatParameter(n"User.SpawnRate", FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(550.f, 0.f), NewSpawnRate));
				BallFallBlueFXDistant.SetFloatParameter(n"User.SpawnRate", FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(550.f, 0.f), NewSpawnRate));
				if (NewSpawnRate >= 1.f && PlayerInteracting.HasControl())
					NetBallColorDeactivated(ValveColor);

				break;

			case EValveColor::Green:
				BallFallGreenFX.SetFloatParameter(n"User.SpawnRate", FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(850.f, 0.f), NewSpawnRate));
				BallFallGreenFXDistant.SetFloatParameter(n"User.SpawnRate", FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(850.f, 0.f), NewSpawnRate));
				if (NewSpawnRate >= 1.f && PlayerInteracting.HasControl())
					NetBallColorDeactivated(ValveColor);

				break;

			case EValveColor::White:
				BallFallWhiteFX.SetFloatParameter(n"User.SpawnRate", FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(850.f, 0.f), NewSpawnRate));
				BallFallWhiteFXDistant.SetFloatParameter(n"User.SpawnRate", FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(850.f, 0.f), NewSpawnRate));
				if (NewSpawnRate >= 1.f && PlayerInteracting.HasControl())
					NetBallColorDeactivated(ValveColor);

				break;
		}
	}

	UFUNCTION(NetFunction)
	void NetSetBoxCollisionDisabled()
	{
		DeathVolume.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		
		if (ExternalDeathVolume != nullptr)
		{
			for(auto Player : Game::GetPlayers())
				ExternalDeathVolume.DisablePlayerKillableByDeathVolume(Player);
		}
	}

	UFUNCTION(NetFunction)
	void NetMovePlatforms()
	{
		for (auto Platform : BallFallPlatforms)
		{
			Platform.StartMovingPlatform();
		}
	}
}