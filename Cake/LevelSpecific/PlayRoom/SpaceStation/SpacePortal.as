import Cake.LevelSpecific.PlayRoom.SpaceStation.SpacePortal.SpacePortalExitCapability;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SpacePortal.SpacePortalExitPoint;

event void FOnSpacePortalEntered(AHazePlayerCharacter Player);
event void FOnSpacePortalExit(AHazePlayerCharacter Player);

UCLASS(Abstract)
class ASpacePortal : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PortalGate;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PortalTrigger;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Star1;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Star2;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Star3;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Star4;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Star5;

	UPROPERTY(DefaultComponent, Attach = Star1)
	UNiagaraComponent StarEffect1;
	UPROPERTY(DefaultComponent, Attach = Star2)
	UNiagaraComponent StarEffect2;
	UPROPERTY(DefaultComponent, Attach = Star3)
	UNiagaraComponent StarEffect3;
	UPROPERTY(DefaultComponent, Attach = Star4)
	UNiagaraComponent StarEffect4;
	UPROPERTY(DefaultComponent, Attach = Star5)
	UNiagaraComponent StarEffect5;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlayerSpawnPoint;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeCameraComponent MayCamera;
	default MayCamera.RelativeLocation = FVector(600.f, 0.f, 700.f);
	default MayCamera.RelativeRotation = FRotator(0.f, 180.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeCameraComponent CodyCamera;
	default CodyCamera.RelativeLocation = FVector(600.f, 0.f, 700.f);
	default CodyCamera.RelativeRotation = FRotator(0.f, 180.f, 0.f);

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 10000.f;

	UPROPERTY()
	FOnSpacePortalEntered OnSpacePortalEntered;

	UPROPERTY()
	FOnSpacePortalExit OnSpacePortalExit;

	UPROPERTY()
	ASpacePortalExitPoint ExitPoint;

	UPROPERTY()
	bool bActivateEntryCamera = true;

	UPROPERTY()
	ESpaceStation TargetStation;

	UPROPERTY(Category = "Stars")
	bool bHideStars = false;

	UPROPERTY(Category = "Stars")
	bool bShowStarEffectsWhenActivated = true;

	UPROPERTY(EditDefaultsOnly, Category = "Stars")
	UMaterialInterface StarMaterial;

	UPROPERTY(EditDefaultsOnly, Category = "Stars")
	float StarDelay = 0.5f;

	UPROPERTY(EditDefaultsOnly, Category = "Stars")
	UForceFeedbackEffect StarForceFeedback;

	UPROPERTY()
	EHazeSelectPlayer BarkingPlayer = EHazeSelectPlayer::May;

	bool bConnectedStationActivated = false;

	TArray<UStaticMeshComponent> Stars;
	TArray<UNiagaraComponent> StarEffects;
	int StarsActivated = 0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bHideStars)
		{
			Star1.SetHiddenInGame(true, true);
			Star2.SetHiddenInGame(true, true);
			Star3.SetHiddenInGame(true, true);
			Star4.SetHiddenInGame(true, true);
			Star5.SetHiddenInGame(true, true);
		}
		else
		{
			Star1.SetHiddenInGame(false, true);
			Star2.SetHiddenInGame(false, true);
			Star3.SetHiddenInGame(false, true);
			Star4.SetHiddenInGame(false, true);
			Star5.SetHiddenInGame(false, true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PortalTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterPortal");

		if (bHideStars)
			return;

		Stars.Add(Star1);
		Stars.Add(Star2);
		Stars.Add(Star3);
		Stars.Add(Star4);
		Stars.Add(Star5);

		StarEffects.Add(StarEffect1);
		StarEffects.Add(StarEffect2);
		StarEffects.Add(StarEffect3);
		StarEffects.Add(StarEffect4);
		StarEffects.Add(StarEffect5);
	}

	UFUNCTION()
	void EnterPortal(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr && Player.HasControl() && !Player.IsAnyCapabilityActive(USpacePortalExitCapability::StaticClass()))
		{
			NetEnterPortal(Player);
		}
	}

	UFUNCTION(NetFunction)
	void NetEnterPortal(AHazePlayerCharacter Player)
	{
		Player.SetCapabilityAttributeObject(n"CurrentPortal", this);
		Player.SetCapabilityAttributeObject(n"ExitPoint", ExitPoint);
		Player.SetCapabilityActionState(n"EnterSpacePortal", EHazeActionState::ActiveForOneFrame);
		Player.SetCapabilityActionState(n"ForceResetSize", EHazeActionState::ActiveForOneFrame);
		BP_EnterPortal(Player);
		OnSpacePortalEntered.Broadcast(Player);
	}

	UFUNCTION(BlueprintEvent)
	void BP_EnterPortal(AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintEvent)
	void BP_ShowAndHideLevels(AHazePlayerCharacter Player) {}

	void ExitPortal(AHazePlayerCharacter Player)
	{
		OnSpacePortalExit.Broadcast(Player);
		BP_ExitPortal(Player);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ExitPortal(AHazePlayerCharacter Player) {}

	UFUNCTION()
	void ConnectedStationActivated()
	{
		if (!bConnectedStationActivated)
		{
			if (bShowStarEffectsWhenActivated)
				ActivateStar();
			else
			{
				for (UStaticMeshComponent Star : Stars)
				{
					Star.SetMaterial(0, StarMaterial);
				}
			}
			bConnectedStationActivated = true;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void ActivateStar()
	{
		StarsActivated++;

		Stars[StarsActivated - 1].SetMaterial(0, StarMaterial);
		StarEffects[StarsActivated - 1].Activate(true);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayForceFeedback(StarForceFeedback, false, true, n"PortalStar");

		if (StarsActivated < Stars.Num())
			System::SetTimer(this, n"ActivateStar", StarDelay, false);
	}
}