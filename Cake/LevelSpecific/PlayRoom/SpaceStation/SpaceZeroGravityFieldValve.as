import Vino.LevelSpecific.Garden.ValveTurnInteractionActor;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeStatics;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SpaceConductorIndicatorStar;
import Peanuts.Audio.AudioStatics;

event void FZeroGravityFieldValveInteractionStarted(AHazePlayerCharacter Player);

class ASpaceZeroGravityFieldValve : AValveTurnInteractionActor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LeftDoor;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RightDoor;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BackPiece;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartValveAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopValveAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopAfterReleaseValveAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ValveFullyTurnedAudioEvent;


	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 8000.f;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface BackPieceMaterial;

	UPROPERTY()
	TArray<ASpaceConductorIndicatorStar> Stars;
	float StarThresholdValue;

	UPROPERTY()
	FZeroGravityFieldValveInteractionStarted InteractionStarted;

	bool bInteracting = false;
	bool bCompleted = false;
	bool bValveReleased = true;

	float LastTurnProgress;
	float LastTurnDirection;
	float LastTurnSpeed;

	private FHazeAudioEventInstance ValveTurningEventInstance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		StarThresholdValue = MaxValue/6.f;
	}

	UFUNCTION()
	void SetCompleted()
	{
		bCompleted = true;
		EnterInteraction.Disable(n"Completed");
		RightDoor.SetRelativeRotation(FRotator(0.f, 15, 0.f));
		LeftDoor.SetRelativeRotation(FRotator(0.f, 165, 0.f));
		BackPiece.SetMaterial(0, BackPieceMaterial);
		HazeAkComp.HazePostEvent(ValveFullyTurnedAudioEvent);
		HazeAkComp.HazePostEvent(StopValveAudioEvent);

		for (ASpaceConductorIndicatorStar Star : Stars)
			Star.SetActiveStatus(true);

		ForceEnd();
	}

	UFUNCTION()
	void OpenDoors()
	{
		BackPiece.SetMaterial(0, BackPieceMaterial);
		RightDoor.SetRelativeRotation(FRotator(0.f, 15, 0.f));
		LeftDoor.SetRelativeRotation(FRotator(0.f, 165, 0.f));

		EnterInteractionActionShape.SetBoxExtent(EnterInteractionActionShape.BoxExtent * 2, false);
		EnterInteractionActionShape.SetRelativeLocation(FVector(EnterInteractionActionShape.RelativeLocation.X + (EnterInteractionActionShape.BoxExtent.X/2), 0.f, EnterInteractionActionShape.RelativeLocation.Z + (EnterInteractionActionShape.BoxExtent.Z/2)));
	}
	
	void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		Super::OnInteractionActivated(Component, Player);

		bInteracting = true;

		if (Player.IsCody())
			ForceCodyMediumSize();

		FHazeCameraClampSettings ClampSettings;
		ClampSettings.bUseClampYawLeft = true;
		ClampSettings.bUseClampYawRight = true;
		ClampSettings.ClampYawLeft = 85.f;
		ClampSettings.ClampYawRight = 85.f;
		Player.ApplyCameraClampSettings(ClampSettings, FHazeCameraBlendSettings(2.f), this);

		HazeAudio::SetPlayerPanning(HazeAkComp, Player);
		ValveTurningEventInstance = HazeAkComp.HazePostEvent(StartValveAudioEvent);

		InteractionStarted.Broadcast(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bCompleted)
		{
			for (ASpaceConductorIndicatorStar Star : Stars)
				Star.SetActiveStatus(true);

			SetActorTickEnabled(false);
			return;
		}

		if (!bInteracting && SyncComponent.HasControl())
			SyncComponent.Value = FMath::FInterpConstantTo(SyncComponent.Value, 0.f, DeltaTime, 18.f);

		int ThresholdIncrement = 0;
		int ThresholdMultiplier = 1;
		for (ASpaceConductorIndicatorStar CurStar : Stars)
		{
			if (ThresholdIncrement >= 2)
			{
				ThresholdMultiplier++;
				ThresholdIncrement = 0;
			}

			CurStar.SetActiveStatus(SyncComponent.Value >= StarThresholdValue * ThresholdMultiplier);
			ThresholdIncrement++;
		}

		const float TurnProgress = SyncComponent.Value;	
		const float TurnDirection = FMath::Sign(TurnProgress - LastTurnProgress);
		if(TurnDirection != LastTurnDirection)
			LastTurnDirection = TurnDirection;

		float TurnSpeed = FMath::Abs(TurnDirection);
		if(TurnSpeed != LastTurnSpeed)
		{
			HazeAkComp.SetRTPCValue("Rtpc_World_Shared_Interactables_Rotators_Velocity", TurnSpeed);
			LastTurnSpeed = TurnSpeed;
		}		

		if(TurnProgress >= MaxValue && TurnProgress != LastTurnProgress)
		{
			HazeAkComp.HazePostEvent(ValveFullyTurnedAudioEvent);
			LastTurnProgress = TurnProgress;
		}
					
		LastTurnProgress = TurnProgress;	
		
		if(!bValveReleased && SyncComponent.Value == 0.f)
		{
			HazeAkComp.HazePostEvent(StopAfterReleaseValveAudioEvent);
			HazeAkComp.HazePostEvent(StopValveAudioEvent);
			bValveReleased = true;
		}

		if(SyncComponent.Value > 0.f)
			bValveReleased = false;

	}

	void EndInteraction(AHazePlayerCharacter Player) override
	{	
		Super::EndInteraction(Player);
		if (SyncComponent.Value == 0.f)
		{
			HazeAkComp.HazePostEvent(StopValveAudioEvent);
		}
		
		Player.ClearCameraClampSettingsByInstigator(this);
		bInteracting = false;
		SetActorTickEnabled(true);
	}
}