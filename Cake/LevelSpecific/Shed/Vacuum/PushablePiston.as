import Vino.PlayerHealth.PlayerHealthStatics;
import Peanuts.Audio.AudioStatics;
import Vino.Interactions.InteractionComponent;
import Vino.Camera.Components.WorldCameraShakeComponent;
import Cake.LevelSpecific.Shed.VOBanks.VacuumVOBank;

UCLASS(Abstract)
class APushablePiston : AHazeActor
{	
	UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent Base;

    UPROPERTY(DefaultComponent, Attach = Base)
    UStaticMeshComponent Piston;

    UPROPERTY(DefaultComponent, Attach = Base)
    UBoxComponent KillTrigger;

    UPROPERTY(DefaultComponent, Attach = Base)
	UInteractionComponent InteractionComp;
    default InteractionComp.RelativeRotation = FRotator(0.f, -90.f, 0.f);
    default InteractionComp.RelativeLocation = FVector(-175, 470, 8);

	UPROPERTY(DefaultComponent, Attach = Base)
	UNiagaraComponent ImpactEffect;
	default ImpactEffect.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BarkDistanceCheckOrigin;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent SyncVectorComp;

	UPROPERTY(DefaultComponent)
	UForceFeedbackComponent ForceFeedbackComp;

	UPROPERTY(DefaultComponent)
	UWorldCameraShakeComponent CameraShakeComp;

	UPROPERTY(DefaultComponent, Attach = Piston)
	UHazeAkComponent HazeAkCompPiston;

	UPROPERTY(Category = "Audio Events", EditDefaultsOnly)
	UAkAudioEvent StartPistonAudioEvent; 

	UPROPERTY(Category = "Audio Events", EditDefaultsOnly)
	UAkAudioEvent StopPistonAudioEvent; 

	UPROPERTY(Category = "Audio Events", EditDefaultsOnly)
	UAkAudioEvent HitClampPistonAudioEvent; 

	UPROPERTY(Category = "Audio Events", EditDefaultsOnly)
	UAkAudioEvent MoveBackImpactPistonAudioEvent; 

	UPROPERTY(EditDefaultsOnly)
	UVacuumVOBank VOBank;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect HitClampForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

    bool bMovingBack = false;

    UPROPERTY()
    float MaxOffset = -280.f;

	bool bPlayBarks = true;
	
	bool bClampHitLastFrame = true;

	bool bControlMovedBack = true;
	bool bRemoteMovedBack = true;
	bool bFullyMovedBack = true;
	bool bSyncValueFullyReset = true;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		InteractionComp.OnActivated.AddUFunction(this, n"InteractionActivated");

        KillTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterCrushTrigger");
    }

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		
	}

    UFUNCTION(NotBlueprintCallable)
	void EnterCrushTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

        if (Player != nullptr && bMovingBack)
        {
            CrushPlayer(Player);
        }
    }

    UFUNCTION(NotBlueprintCallable)
	void InteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		bClampHitLastFrame = true;
		HazeAkCompPiston.SetRTPCValue("Rtpc_Platform_Shed_Vacuum_PushablePiston_Velocity", 0.f);

		SetOwner(Player);
        Player.SetCapabilityAttributeObject(n"Piston", this);
        Player.SetCapabilityActionState(n"PushingPiston", EHazeActionState::Active);
        Component.Disable(n"PistonUsed");
		SyncVectorComp.OverrideControlSide(Player);

		if (StartPistonAudioEvent != nullptr)
			HazeAkCompPiston.HazePostEvent(StartPistonAudioEvent);
    }

    UFUNCTION()
    void MovePiston(FVector2D Input)
    {
        float PushingMultiplier = FMath::GetMappedRangeValueClamped(FVector2D(-280.f, 0.f), FVector2D(50.f, 150.f), Base.RelativeLocation.X);

        if (Input.Y > 0.f)
            PushingMultiplier = 150.f;

        float MovementDirection = Input.Y * PushingMultiplier;

        float NewOffset = Base.RelativeLocation.X + MovementDirection * GetActorDeltaSeconds();
        NewOffset = FMath::Clamp(NewOffset, MaxOffset, 0);

		bool bClampHitThisFrame = false;

		if (NewOffset == MaxOffset)
		{
			if (!bClampHitLastFrame)
			{
				bClampHitLastFrame = true;
				bClampHitThisFrame = true;
			}
		}
		else if (NewOffset == 0.f)
		{
			if (!bClampHitLastFrame)
			{
				bClampHitLastFrame = true;
				bClampHitThisFrame = true;
			}
		}
		else
			bClampHitLastFrame = false;

		if (bClampHitThisFrame)
		{
			if (HitClampPistonAudioEvent != nullptr)
				HazeAkCompPiston.HazePostEvent(HitClampPistonAudioEvent);
		}

        Base.SetRelativeLocation(FVector(NewOffset, 0.f, 0.f));
    }

    void ReleasePiston(bool bSlamShut)
    {
		if (!bSlamShut)
		{
			// InteractionComp.Enable(n"PistonUsed");
			InteractionComp.EnableAfterFullSyncPoint(n"PistonUsed");
			
			if (StopPistonAudioEvent != nullptr)
				HazeAkCompPiston.HazePostEvent(StopPistonAudioEvent);
		}
		else
		{
        	bMovingBack = true;
			bFullyMovedBack = false;
			bControlMovedBack = false;
			bRemoteMovedBack = false;
			bSyncValueFullyReset = false;
		}
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float Delta)
    {
		if (bMovingBack)
        {
			Base.SetRelativeLocation(FMath::VInterpConstantTo(Base.RelativeLocation, FVector::ZeroVector, Delta, 3500.f));

			HazeAkCompPiston.SetRTPCValue("Rtpc_Platform_Shed_Vacuum_PushablePiston_Velocity", 2.f);

            if (Base.RelativeLocation == FVector::ZeroVector)
            {
				NetPistonFullyMovedBack(SyncVectorComp.HasControl());
				for (AHazePlayerCharacter Player : Game::GetPlayers())
				{
					if (KillTrigger.IsOverlappingActor(Player))
						CrushPlayer(Player);
				}

				ForceFeedbackComp.Play();
				CameraShakeComp.Play();

                bMovingBack = false;
                // InteractionComp.Enable(n"PistonUsed");
				InteractionComp.EnableAfterFullSyncPoint(n"PistonUsed");
				HazeAkCompPiston.SetRTPCValue("Rtpc_Platform_Shed_Vacuum_PushablePiston_Velocity", 0.f);
				ImpactEffect.Activate(true);

				if (StopPistonAudioEvent != nullptr)
					HazeAkCompPiston.HazePostEvent(StopPistonAudioEvent);
				
				if (MoveBackImpactPistonAudioEvent != nullptr)
					HazeAkCompPiston.HazePostEvent(MoveBackImpactPistonAudioEvent);
            }

			return;
        }

		if (Network::IsNetworked())
		{
			if (SyncVectorComp.HasControl())
			{
				if (bFullyMovedBack)
					SyncVectorComp.Value = Base.RelativeLocation;
			}
			else
			{
				if (!bSyncValueFullyReset)
				{
					if (FMath::IsNearlyEqual(SyncVectorComp.Value.Size(), FVector::ZeroVector.Size(), 0.1f))
						bSyncValueFullyReset = true;
					else
						return;
				}

				if (!bMovingBack && bSyncValueFullyReset)
					Base.SetRelativeLocation(SyncVectorComp.Value);
			}
		}
		else
		{
			SyncVectorComp.Value = Base.RelativeLocation;
			
			if (!bMovingBack)
				Base.SetRelativeLocation(SyncVectorComp.Value);
		}
    }

	UFUNCTION(NetFunction)
	void NetPistonFullyMovedBack(bool bFromControl)
	{
		if (bFromControl)
			bControlMovedBack = true;
		else
			bRemoteMovedBack = true;

		if (bControlMovedBack && bRemoteMovedBack)
			NetBothMovedBack();
	}

	UFUNCTION(NetFunction)
	void NetBothMovedBack()
	{
		if (bFullyMovedBack)
			return;

		bFullyMovedBack = true;
	}

	void CrushPlayer(AHazePlayerCharacter Player)
	{
		if (Player.HasControl())
			NetCrushPlayer(Player);
	}

	UFUNCTION(NetFunction)
	void NetCrushPlayer(AHazePlayerCharacter Player)
	{
		KillPlayer(Player);
		if (Player.IsCody())
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumChipRoomEntranceCodyEntersDeathMay");
		else
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumChipRoomEntranceMayEntersDeathCody");
	}

	UFUNCTION()
	void DisableBarks()
	{
		bPlayBarks = false;
	}
}