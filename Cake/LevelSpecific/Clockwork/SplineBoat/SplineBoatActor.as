import Vino.Interactions.InteractionComponent;
import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatPath;
import Vino.Tutorial.TutorialStatics;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatTurntable;
import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatPlayerComponent;
import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatJumpComponent;
import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatSpeedTrackerComponent;
import Cake.LevelSpecific.Clockwork.SplineBoat.TunnelRideDoors;
import Vino.Checkpoints.Volumes.CheckpointVolume;
import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class ASplineBoatActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USkeletalMeshComponent BoatSkeleton;

	UPROPERTY(DefaultComponent, Attach = BoatSkeleton)
	UPointLightComponent PointLightFront;
	default PointLightFront.SetCastShadows(false);

	UPROPERTY(DefaultComponent, Attach = BoatSkeleton)
	UPointLightComponent PointLightBack;
	default PointLightBack.SetCastShadows(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp1;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp2;

	UPROPERTY(DefaultComponent)
	UHazeSplineFollowComponent SplineFollowComponent; 

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 10000.f;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent AkCompPeddleMay;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent AkCompPeddleCody;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent AkCompBoatMovement;

	UPROPERTY(Category = "VOBank")
	UFoghornVOBankDataAssetBase VOLevelBank;

	UPROPERTY(Category = "Setup")
	UTexture LightsOn;

	UPROPERTY(Category = "Setup")
	UTexture LightsOff;

	UPROPERTY(Category = "Setup")
	UHazeCameraSettingsDataAsset CamSettings;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent PeddleMayStarted;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent PeddleMayEnded;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent PeddleCodyStarted;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent PeddleCodyEnded;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BoatMovementStarted;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BoatMovementEnded;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent LightSwitchOn;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent LightSwitchOff;

	UPROPERTY()
	UHazeCapabilitySheet BoatCapabilitySheet;

	UPROPERTY()
	UHazeCapabilitySheet PlayerCapabilitySheet;

	UPROPERTY()
	ATunnelRideDoors TunnelDoorsOne;

	UPROPERTY()
	ATunnelRideDoors TunnelDoorsTwo;

	UPROPERTY()
    ASplineBoatPath SplineBoatPath;

	ASplineBoatTurntable Turntable;
	USplineBoatPlayerComponent PlayerCompMay;
	USplineBoatPlayerComponent PlayerCompCody;
	AHazePlayerCharacter May;
	AHazePlayerCharacter Cody;
	USplineBoatSpeedTrackerComponent SpeedTrackerComp;

	EHazeUpdateSplineStatusType SplineStatus;

	bool bPlayerIsAttached;
	bool bIsMoving;
	bool bIsClose;
	bool bIsReturning;
	bool bIsSlowSpeed;

	UPROPERTY()
	bool bLightsOn;

	float BoatSpeed;
	float CurrrentMoveSpeedMay;
	float CurrrentMoveSpeedCody;

	UPROPERTY(Category = "Setup")
	float MaxLightIntensity = 3000.f;

	FVector CurrentNextLoc;

	UPROPERTY()
	FHazeTimeLike TimeLike;

	TArray<USplineBoatJumpComponent> JumpCompArray;

	TArray<AHazeCharacter> PlayerArray; 

	FHazeSplineSystemPosition SystemPosition;

	UMaterialInstanceDynamic DynamicBoatMat;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;
	
	TPerPlayer<bool> bPlayersVO;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		BoatSkeleton.SetCullDistance(Editor::GetDefaultCullingDistance(BoatSkeleton) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp1.SetExclusiveForPlayer(EHazePlayer::Cody, true);
		InteractionComp2.SetExclusiveForPlayer(EHazePlayer::May, true);

		AddCapabilitySheet(BoatCapabilitySheet);
		
		InteractionComp1.OnActivated.AddUFunction(this, n"OnInteractionActivated1");
		InteractionComp2.OnActivated.AddUFunction(this, n"OnInteractionActivated2");
		InteractionComp1.OnActivated.AddUFunction(this, n"OnInteractionActivatedVO");
		InteractionComp2.OnActivated.AddUFunction(this, n"OnInteractionActivatedVO");
		
		DynamicBoatMat = BoatSkeleton.CreateDynamicMaterialInstance(0);
		DynamicBoatMat.SetTextureParameterValue(n"M4", LightsOff);

		PointLightFront.SetIntensity(0.f);
		PointLightBack.SetIntensity(0.f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (PlayerCompMay != nullptr)
		{
			PlayerCompMay.LockedPosition = InteractionComp2.WorldLocation;
			PlayerCompMay.RotatedPosition =  InteractionComp2.WorldRotation;
		}

		if (PlayerCompCody != nullptr)
		{
			PlayerCompCody.LockedPosition = InteractionComp1.WorldLocation;
			PlayerCompCody.RotatedPosition =  InteractionComp1.WorldRotation;			
		}
	}

	UFUNCTION()
    void OnInteractionActivated1(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		SetupPlayer(Component, Player);
		PlayerArray.Add(Player); 

		if (PlayerArray.Num() == 2)
			SetLightState(true);

		InteractionComp1.Disable(n"Only one player can use this");

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.5f;
		Player.ApplyCameraSettings(CamSettings, Blend, this, EHazeCameraPriority::High);
    }
	
	UFUNCTION()
    void OnInteractionActivated2(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		SetupPlayer(Component, Player);
		PlayerArray.Add(Player);
		
		if (PlayerArray.Num() == 2)
			SetLightState(true);

		InteractionComp2.Disable(n"Only one player can use this"); 

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.5f;
		Player.ApplyCameraSettings(CamSettings, Blend, this, EHazeCameraPriority::High);
	}

	UFUNCTION()
    void OnInteractionActivatedVO(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		if (Player.IsMay() && !bPlayersVO[Player])
		{
			PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBClockworkOutsidePaddleBoatInteractMay");
			bPlayersVO[Player] = true;
		}
		else if (Player.IsCody() && !bPlayersVO[Player])
		{
			PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBClockworkOutsidePaddleBoatInteractCody");
			bPlayersVO[Player] = true;
		}
	}

	void SetupPlayer(UInteractionComponent OurInteractionComp, AHazePlayerCharacter Player)
	{
		if (Player.IsMay())
		{
			May = Player;
			May.AddCapabilitySheet(PlayerCapabilitySheet); 
			May.BlockCapabilities(CapabilityTags::Collision, this);
			PlayerCompMay = USplineBoatPlayerComponent::GetOrCreate(Player);
			PlayerCompMay.LockedPosition = InteractionComp2.WorldLocation;
			PlayerCompMay.RotatedPosition =  InteractionComp2.WorldRotation;
			PlayerCompMay.CancelBoatAction.BindUFunction(this, n"CancelBoatInteractionMay");
			PlayerCompMay.OurInteractionComp = OurInteractionComp;
			PlayerCompMay.SplinePath = SplineBoatPath;
			PlayerCompMay.BoatRef = this;
			PlayerCompMay.bIsInBoat = true;
		}
		else
		{
			Cody = Player;
			Cody.AddCapabilitySheet(PlayerCapabilitySheet); 
			Cody.BlockCapabilities(CapabilityTags::Collision, this);
			PlayerCompCody = USplineBoatPlayerComponent::GetOrCreate(Player);
			PlayerCompCody.LockedPosition = InteractionComp1.WorldLocation;
			PlayerCompCody.RotatedPosition =  InteractionComp1.WorldRotation;	
			PlayerCompCody.CancelBoatAction.BindUFunction(this, n"CancelBoatInteractionCody");
			PlayerCompCody.OurInteractionComp = OurInteractionComp;
			PlayerCompCody.SplinePath = SplineBoatPath;
			PlayerCompCody.BoatRef = this;
			PlayerCompCody.bIsInBoat = true;
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_SwitchLightsOn() {}

	UFUNCTION(BlueprintEvent)
	void BP_SwitchLightsOff() {}

	UFUNCTION()
	void BP_SwitchMaterial(bool bState)
	{
		if (bState)
			DynamicBoatMat.SetTextureParameterValue(n"M4", LightsOn);
		else
			DynamicBoatMat.SetTextureParameterValue(n"M4", LightsOff);
	}

	UFUNCTION()
	void SetLightState(bool bState)
	{
		if (bState)
		{
			bLightsOn = true;
			BP_SwitchLightsOn();
			AudioLightSwitchOn();
		}
		else
		{
			bLightsOn = false;
			BP_SwitchLightsOff();
			AudioLightSwitchOff();
		}
	}
	
	UFUNCTION()
	void CancelBoatInteractionMay(UInteractionComponent InteractionComp)
	{
		May.RemoveCapabilitySheet(PlayerCapabilitySheet);
		May.UnblockCapabilities(CapabilityTags::Collision, this);
		May.ClearCameraSettingsByInstigator(this, 1.5f);

		InteractionComp2.EnableAfterFullSyncPoint(n"Only one player can use this");

		PlayerArray.Remove(May); 

		if (PlayerArray.Num() > 0)
		{
			SetLightState(false);
			BP_SwitchMaterial(false);
		}
	}

	UFUNCTION()
	void CancelBoatInteractionCody(UInteractionComponent InteractionComp)
	{
		Cody.RemoveCapabilitySheet(PlayerCapabilitySheet);
		Cody.UnblockCapabilities(CapabilityTags::Collision, this);
		Cody.ClearCameraSettingsByInstigator(this, 1.5f);

		InteractionComp1.EnableAfterFullSyncPoint(n"Only one player can use this");
		
		PlayerArray.Remove(Cody); 

		if (PlayerArray.Num() > 0)
		{
			SetLightState(false);
			BP_SwitchMaterial(false);
		}
	}

    UFUNCTION()
    void TriggeredOnBeginOverlapTurntable(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		if (OtherActor.ActorHasTag(n"Turntable"))
			Turntable = Cast<ASplineBoatTurntable>(OtherActor);
    }

	UFUNCTION()
    void TriggeredOnBeginOverlapBoat(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		AHazeCharacter Player = Cast<AHazeCharacter>(OtherActor);
		
		if (Player == nullptr)
			return;

		USplineBoatJumpComponent JumpComp = USplineBoatJumpComponent::GetOrCreate(Player);
		JumpComp.bIsOnBoat = true;
		JumpComp.BoatActor = this; 

		if (!JumpCompArray.Contains(JumpComp))
			JumpCompArray.Add(JumpComp);

		Player.AddCapability(n"SplineBoatPlayerJumpCapability"); 
    }

	UFUNCTION()
    void TriggeredOnEndOverlapBoat(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		AHazeCharacter Player = Cast<AHazeCharacter>(OtherActor);
		
		if (Player == nullptr)
			return;
		
		USplineBoatJumpComponent JumpComp = USplineBoatJumpComponent::Get(Player);

		JumpComp.bIsOnBoat = false;
    }

	UFUNCTION()
	void OpenDoorOne()
	{
		TunnelDoorsOne.ActivateDoors();
	}

	UFUNCTION()
	void OpenDoorTwo()
	{
		TunnelDoorsTwo.ActivateDoors();
	}

	void AudioMayStartedPeddling()
	{
		AkCompPeddleMay.HazePostEvent(PeddleMayStarted);
		//Print("PeddleMayStarted");
	}

	void AudioCodyStartedPeddling()
	{
		AkCompPeddleCody.HazePostEvent(PeddleCodyStarted);
		//Print("PeddleCodyStarted");
	}

	void AudioMayEndedPeddling()
	{
		AkCompPeddleMay.HazePostEvent(PeddleMayEnded);
		//Print("PeddleMayEnded");
	}

	void AudioCodyEndedPeddling()
	{
		AkCompPeddleCody.HazePostEvent(PeddleCodyEnded);
		//Print("PeddleCodyEnded");
	}

	void AudioRTCPMayPeddling(float Value)
	{
		AkCompPeddleMay.SetRTPCValue("Rtpc_World_SideContent_Clockwork_Interactions_SplineBoat_MayPeddle", Value);
	}

	void AudioRTCPCodyPeddling(float Value)
	{
		AkCompPeddleCody.SetRTPCValue("Rtpc_World_SideContent_Clockwork_Interactions_SplineBoat_CodyPeddle", Value);
	}

	void AudioBoatMovementStarted()
	{
		AkCompBoatMovement.HazePostEvent(BoatMovementStarted);
		//Print("BoatMovementStarted");
	}

	void AudioBoatMovementEnded()
	{
		AkCompBoatMovement.HazePostEvent(BoatMovementEnded);
		//Print("BoatMovementEnded");
	}

	void AudioRTCPBoatMovement(float Value)
	{
		AkCompBoatMovement.SetRTPCValue("Rtpc_World_SideContent_Clockwork_Interactions_SplineBoat_BoatMovement", Value);
		//PrintToScreen("AkCompBoatMovement: " + Value);
	}

	void AudioLightSwitchOn()
	{
		AkCompBoatMovement.HazePostEvent(LightSwitchOn);
	}

	void AudioLightSwitchOff()
	{
		AkCompBoatMovement.HazePostEvent(LightSwitchOff);
	}
}