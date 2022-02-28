import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SpaceWeightDropper;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Vino.PlayerHealth.PlayerHealthStatics;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;
import Peanuts.Triggers.SquishTriggerBox;

UCLASS(Abstract)
class ASpaceLaunchBoard : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent RootComp;

    UPROPERTY(DefaultComponent, Attach = RootComp)
    USceneComponent BoardBase;

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UStaticMeshComponent BoardBaseMesh;

    UPROPERTY(DefaultComponent, Attach = BoardBase)
    UStaticMeshComponent BoardMesh;

    UPROPERTY(DefaultComponent, Attach = BoardBase)
    UBoxComponent LaunchTrigger;

    UPROPERTY(DefaultComponent, Attach = BoardBase)
    UBoxComponent ImpactTrigger;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USquishTriggerBoxComponent TopSquishBox;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USquishTriggerBoxComponent BottomSquishBox;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ImpactLargeForceAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ImpactMediumForceAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ImpactSmallForceAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BoardFinishRotationAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	USpacestationVOBank VOBank;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDeathEffect> SmallCodyDeathEffect;

    UPROPERTY(EditDefaultsOnly)
    FHazeTimeLike RotateLaunchBoardTimeLike;
    default RotateLaunchBoardTimeLike.Duration = 1.f;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect NormalLaunchRumble;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect HeavyLaunchRumble;
    
    bool bRotating = false;
    float StartRot;
	float TargetRot;
	float SmallImpactRot = -4.f;
	float MediumImpactRot = 2.f;
	float LargeImpactRot = 10.f;

	UPROPERTY()
	float SmallImpactForce = 2000.f;

	UPROPERTY()
	float MediumImpactForce = 4250.f;

	UPROPERTY()
	float LargeImpactForce = 5500.f;

	UPROPERTY()
	float SmallLaunchForce = 15000.f;

	UPROPERTY()
	float LargeLaunchForce = 2000.f;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> ImpactCapability;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        ImpactTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterImpactTrigger");

        RotateLaunchBoardTimeLike.BindUpdate(this, n"UpdateRotateLaunchBoard");
        RotateLaunchBoardTimeLike.BindFinished(this, n"FinishRotateLaunchBoard");

        FActorGroundPoundedDelegate GroundPoundedDelegate;
        GroundPoundedDelegate.BindUFunction(this, n"LaunchBoardGroundPounded");
        BindOnActorGroundPounded(this, GroundPoundedDelegate);

        StartRot = BoardBase.RelativeRotation.Roll;

		Capability::AddPlayerCapabilityRequest(ImpactCapability.Get());
    }

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(ImpactCapability.Get());
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

	}

	UFUNCTION()
	void EnterImpactTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		ASpaceWeightDropper Weight = Cast<ASpaceWeightDropper>(OtherActor);

		if (Weight != nullptr && !bRotating)
		{
			if (!bRotating)
			{
				LaunchPlayers(LargeLaunchForce);
				TargetRot = MediumImpactRot;
				RotateLaunchBoardTimeLike.PlayFromStart();
			}
		}
	}

    UFUNCTION()
    void LaunchBoardGroundPounded(AHazePlayerCharacter Player)
    {
		TArray<AActor> ActorsNearImpactTrigger;
        ImpactTrigger.GetOverlappingActors(ActorsNearImpactTrigger, AHazePlayerCharacter::StaticClass());

        if (ActorsNearImpactTrigger.Contains(Player) && !bRotating && Player.HasControl())
        {
            Player.SetCapabilityAttributeObject(n"SpaceLaunchBoard", this);
            Player.SetCapabilityActionState(n"LaunchBoardImpact", EHazeActionState::Active);;
        }
    }

	UFUNCTION(NetFunction)
    void TriggerImpact(AHazePlayerCharacter Player)
    {
		float LaunchForce = MediumImpactForce;
		TargetRot = MediumImpactRot;

		if (Player == Game::GetMay())
		{
			HazeAkComp.HazePostEvent(ImpactMediumForceAudioEvent);
		}


		if (Player != nullptr)
		{
			UCharacterChangeSizeComponent SizeComp = Cast<UCharacterChangeSizeComponent>(Player.GetComponentByClass(UCharacterChangeSizeComponent::StaticClass()));
			if (SizeComp != nullptr)
			{
				if (SizeComp.CurrentSize == ECharacterSize::Large)
				{
					LaunchForce = LargeImpactForce;
					TargetRot = LargeImpactRot;
					HazeAkComp.HazePostEvent(ImpactLargeForceAudioEvent);
				}
				else if (SizeComp.CurrentSize == ECharacterSize::Small)
				{
					LaunchForce = SmallImpactForce;
					TargetRot = SmallImpactRot;
					HazeAkComp.HazePostEvent(ImpactSmallForceAudioEvent);
				}
				else if (SizeComp.CurrentSize == ECharacterSize::Medium)
				{
					HazeAkComp.HazePostEvent(ImpactMediumForceAudioEvent);
				}
			}
		}
		else
		{
			LaunchForce = LargeImpactForce;
			TargetRot = LargeImpactRot;
		}

        bRotating = true;
        RotateLaunchBoardTimeLike.PlayFromStart();
		LaunchPlayers(LaunchForce);
    }


	void LaunchPlayers(float LaunchForce)
	{
		TArray<AActor> ActorsNearLaunchTrigger;
        LaunchTrigger.GetOverlappingActors(ActorsNearLaunchTrigger, AHazePlayerCharacter::StaticClass());

		float FinalLaunchForce = LaunchForce;

		for (AActor CurActor : ActorsNearLaunchTrigger)
		{
			AHazePlayerCharacter LaunchedPlayer = Cast<AHazePlayerCharacter>(CurActor);

			if (LaunchedPlayer != nullptr)
			{
				UCharacterChangeSizeComponent SizeComp = Cast<UCharacterChangeSizeComponent>(LaunchedPlayer.GetComponentByClass(UCharacterChangeSizeComponent::StaticClass()));
				if (SizeComp != nullptr)
				{
					if (SizeComp.CurrentSize == ECharacterSize::Large)
						FinalLaunchForce = LargeLaunchForce;
					else if (SizeComp.CurrentSize == ECharacterSize::Small)
					{
						KillPlayer(LaunchedPlayer, SmallCodyDeathEffect);
						FinalLaunchForce = SmallLaunchForce;
						FOnRespawnTriggered RespawnEvent;
						RespawnEvent.BindUFunction(this, n"PlayerRespawned");
						BindOnPlayerRespawnedEvent(RespawnEvent);
					}
				}
				LaunchedPlayer.AddImpulse(FVector(0.f, 0.f, FinalLaunchForce));
				UForceFeedbackEffect LaunchRumble = FinalLaunchForce == MediumImpactForce ? NormalLaunchRumble : HeavyLaunchRumble;
				LaunchedPlayer.PlayForceFeedback(LaunchRumble, false, true, n"LaunchBoard");
			}
		}
	}

    UFUNCTION()
    void UpdateRotateLaunchBoard(float CurValue)
    {
        float CurRot = FMath::Lerp(StartRot, TargetRot, CurValue);

        BoardBase.SetRelativeRotation(FRotator(0.f, 0.f, CurRot));

		float SquishHeight = FMath::Lerp(30.f, 500.f, CurValue);
		FVector SquishLoc = FVector(0.f, -790.f, SquishHeight);
		TopSquishBox.SetRelativeLocation(SquishLoc);
    }

    UFUNCTION()
    void FinishRotateLaunchBoard()
    {
        bRotating = false;
		HazeAkComp.HazePostEvent(BoardFinishRotationAudioEvent);
    }

	UFUNCTION(NotBlueprintCallable)
	void PlayerRespawned(AHazePlayerCharacter Player)
	{
		System::SetTimer(this, n"PlayTinyCodyLaunchBark", 0.5f, false);
		UnbindOnPlayerRespawnedEvent(this);
		for (AHazePlayerCharacter CurPlayer : Game::GetPlayers())
			Online::UnlockAchievement(CurPlayer, n"SpaceLaunch");
	}

	UFUNCTION()
	void PlayTinyCodyLaunchBark()
	{
		VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationLaunchBoardRespawn");
	}
}