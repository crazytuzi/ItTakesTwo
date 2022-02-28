import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Clockwork.Fishing.PlayerFishingComponent;
import Cake.LevelSpecific.Clockwork.Fishing.FishingCatchManager;
import Cake.LevelSpecific.Clockwork.Fishing.FishingCatchPile;
import Cake.LevelSpecific.Clockwork.Fishing.RodBaseComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlParams;
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.PlayerTimeSequenceComponent;
import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

enum EHazePlayerControllerSide
{
	Cody,
	May 
};

class ARodBase : AHazeActor
{
	//*** ACTOR SETUP ***//
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BaseRoot;

	UPROPERTY(DefaultComponent, Attach = BaseRoot)
	USkeletalMeshComponent BaseSkeleton;
	default BaseSkeleton.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	
	UPROPERTY(DefaultComponent, Attach = BaseMesh)
	USceneComponent CameraLoc;

	UPROPERTY(DefaultComponent, Attach = BaseRoot)
	UStaticMeshComponent FishingBall;

	UPROPERTY(DefaultComponent, Attach = BaseRoot)
	UStaticMeshComponent FishingLineMesh;
	default FishingLineMesh.SetWorldScale3D(FVector(0.015f, 0.015f, 0.015f));
	FVector DefaultLineScale(0.015f, 0.015f, 0.015f); 

	UPROPERTY(DefaultComponent, Attach = BaseRoot)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent TurningGear1;	

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent TurningGear2;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	AHazePlayerCharacter CurrentPlayer;

	//*** MAIN SETUP ***//
	UPROPERTY(Category = "Setup")
	AFishingCatchManager FishingCatchManager;

	UPROPERTY(Category = "Setup")
	AFishingCatchPile FishingCatchPile;

	UPROPERTY(Category = "Setup")
	UFoghornVOBankDataAssetBase VOLevelBank;

	UPROPERTY(DefaultComponent)
	URodBaseComponent RodBaseComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent FishingAkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent RodRotationStart;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent RodRotationEnd;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent RodWindUpStart;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent RodWindUpEnd;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent RodStruggleStart;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent RodStruggleEnd;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent LineBackToDefault;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent CastLineEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent CatchOnLine;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartReelEvent;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent EndReelEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent HaulingItemFromWater;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ThrowCatchEvent;

	UPROPERTY(Category = "Setup")
	EHazePlayerControllerSide PlayerControlSide;

	UPROPERTY(Category = "Setup")
	UHazeCapabilitySheet PlayerCapabilitySheet;

	UPROPERTY(Category = "Setup")
	UHazeCapabilitySheet RodCapabilitySheet;

	//*** CAMERA SETTINGS ***//
	bool bHaveAttached;

	UPROPERTY(Category = "CameraSettings")
	UHazeCameraSpringArmSettingsDataAsset SpringArmSettingsDefault;

	UPROPERTY(Category = "CameraSettings")
	UHazeCameraSpringArmSettingsDataAsset SpringArmSettingsGotCatch;

	UPROPERTY(Category = "CameraSettings")
	UHazeCameraSpringArmSettingsDataAsset SpringArmSettingsThrowCatch;

	UPROPERTY(Category = "CameraSettings")
	AHazeCameraActor CameraThrowCatch;

	bool bFirstTimeInteracting;

	//*** IMPORTANT REFERENCES ***//

	UPlayerFishingComponent PlayerComp;

	AFishingCatchObject CurrentCatch;

	//*** LINE MATERIAL ***//
	float Slack;
	float Wind;

	float DefaultSlackTarget = 0.f;
	float CastSlackTarget = 110.f;
	float NextCastSlackTarget = -70.f;
	float CatchingCastSlackTarget = 80.f;
	float ReelSlackTarget = 0.f;

	float DefaultWindTarget = 0.f;
	float AfterCastWindTarget = 100.f;
	float ReelWindTarget = 150.f;
	float ThrowingWindTarget = 200.f;

	//*** ANGLE CHECKS ***//
	FVector StartForwardVector;
	FVector StartRightVector;
	
	UPROPERTY()
	float DotLeftMax;

	UPROPERTY()
	float DotRightMax;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FishingBall.SetCullDistance(Editor::GetDefaultCullingDistance(FishingBall) * CullDistanceMultiplier);
		FishingLineMesh.SetCullDistance(Editor::GetDefaultCullingDistance(FishingLineMesh) * CullDistanceMultiplier);
		TurningGear1.SetCullDistance(Editor::GetDefaultCullingDistance(TurningGear1) * CullDistanceMultiplier);
		TurningGear2.SetCullDistance(Editor::GetDefaultCullingDistance(TurningGear2) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"FishingInteraction");

		AddCapabilitySheet(RodCapabilitySheet);

		StartForwardVector = ActorForwardVector;
		StartRightVector = ActorRightVector;

		if (PlayerControlSide == EHazePlayerControllerSide::Cody)
		{
			Network::SetActorControlSide(this, Game::GetCody());
			InteractionComp.SetExclusiveForPlayer(EHazePlayer::Cody);
		}
		else
		{
			Network::SetActorControlSide(this, Game::GetMay());
			InteractionComp.SetExclusiveForPlayer(EHazePlayer::May);
		}

		InteractionComp.SetWorldLocation(BaseSkeleton.GetSocketLocation(n"PlayerAttach_Socket"));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (PlayerComp == nullptr)
			return;

		CheckAngle();
		ThrowCameraAttachAndLocation();
	}

	UFUNCTION()
	void FishingInteraction(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		Player.AddCapabilitySheet(PlayerCapabilitySheet);

		if (Player.IsMay())
			Player.BlockCapabilities(TimeControlCapabilityTags::TimeSequenceCapability, this);
		else
			Player.BlockCapabilities(TimeControlCapabilityTags::TimeControlCapability, this);

		UTimeControlSequenceComponent SeqComp = UTimeControlSequenceComponent::Get(Game::May);
		
		if (SeqComp != nullptr)
			SeqComp.DeactiveClone(Game::May);

		PlayerComp = UPlayerFishingComponent::Get(Player);
		PlayerComp.FishingState = EFishingState::Default;
		PlayerComp.DotLeftMax = DotLeftMax;
		PlayerComp.DotRightMax = DotRightMax;
		PlayerComp.MaxCatchIndexAmount = FishingCatchManager.CatchObjectArray.Num() - 1;
		
		PlayerComp.RodBase = this;
		PlayerComp.CameraThrowCatch = CameraThrowCatch;

		PlayerComp.EventExitFishing.AddUFunction(this, n"PlayerExitFishing");
		// PlayerComp.EventCatchObject.AddUFunction(this, n"EnableAndAttachCatch");
		PlayerComp.EventSlackValue.AddUFunction(this, n"SetSlackValue");
		PlayerComp.EventWindValue.AddUFunction(this, n"SetWindValue");

		PlayerComp.DefaultSlackTarget = DefaultSlackTarget;
		PlayerComp.CastSlackTarget = CastSlackTarget;
		PlayerComp.ReelSlackTarget = ReelSlackTarget;

		InteractComp.Disable(n"Turn off prompt");	

		if (!bFirstTimeInteracting)
		{
			if (Player.IsMay())
				PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBClockworkOutsideFishingInteractMay");
			else
				PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBClockworkOutsideFishingInteractCody");

			bFirstTimeInteracting = true;
		}
	}

	UFUNCTION()
	void PlayerExitFishing(AHazePlayerCharacter Player)
	{
		Player.RemoveCapabilitySheet(PlayerCapabilitySheet);
		PlayerComp = nullptr;

		if (Player.IsMay())
			Player.UnblockCapabilities(TimeControlCapabilityTags::TimeSequenceCapability, this);
		else
			Player.UnblockCapabilities(TimeControlCapabilityTags::TimeControlCapability, this);

		DetatchCatch();
		DisableCatch();

		InteractionComp.EnableAfterFullSyncPoint(n"Turn off prompt");
	}

	UFUNCTION()
	void CheckAngle()
	{
		PlayerComp.CurrentDotRight = BaseRoot.ForwardVector.DotProduct(StartRightVector);
		PlayerComp.CurrentDotForward = BaseRoot.ForwardVector.DotProduct(StartForwardVector);
	}

	UFUNCTION()
	void SetSlackValue(float Value)
	{
		Slack = Value;
	}

	UFUNCTION()
	void SetWindValue(float Value)
	{
		Wind = Value;
	}

	UFUNCTION(NetFunction)
	void NetEnableAndAttachCatch(int RIndex)
	{	
		// AFishingCatchObject CatchObj = Cast<AFishingCatchObject>(FishingCatchManager.CatchObjectArray[RIndex]); 
		AFishingCatchObject CatchObj = FishingCatchManager.EnableCaughtObj(RIndex);
		CurrentCatch = CatchObj;
		CurrentCatch.AttachToComponent(FishingBall, NAME_None, EAttachmentRule::SnapToTarget);
	}

	UFUNCTION()
	void DetatchCatch()
	{
		if (CurrentCatch == nullptr)
			return;

		CurrentCatch.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
	}
	
	UFUNCTION()
	void DisableCatch()
	{
		if (CurrentCatch == nullptr)
			return;
			
		CurrentCatch.MeshComp.SetHiddenInGame(false);
		FishingCatchManager.DisableCaughtObj(CurrentCatch);
		CurrentCatch = nullptr;
	}

	UFUNCTION()
	void HideCatch()
	{
		CurrentCatch.MeshComp.SetHiddenInGame(true);
	}
	
	UFUNCTION()
	void ThrowCameraAttachAndLocation()
	{
		float Distance = (CameraLoc.WorldLocation - FishingCatchPile.ActorLocation).Size();

		if (Distance <= 1350.f || Distance >= 1550.f)
		{
			//Do nothing mate
		}
		else
		{
			CameraThrowCatch.ActorLocation = CameraLoc.WorldLocation;
		}
	}

	void PlayVOCatchFish(AHazePlayerCharacter Player)
	{
		if (Player.IsMay())
			PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBClockworkOutsideFishingCatchMay");
		else
			PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBClockworkOutsideFishingCatchCody");
	}

	void PlayVOReelFish(AHazePlayerCharacter Player)
	{
		if (Player.IsMay())
			PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBClockworkOutsideFishingReelingMay");
		else
			PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBClockworkOutsideFishingReelingCody");
		
	}

	void AudioRodRotationStart()
	{
		FishingAkComp.HazePostEvent(RodRotationStart);
	}

	void AudioRodRotationEnd()
	{
		FishingAkComp.HazePostEvent(RodRotationEnd);
	}

	void AudioLineBackToDefault()
	{
		FishingAkComp.HazePostEvent(LineBackToDefault);
	}

	void AudioCastLine()
	{
		FishingAkComp.HazePostEvent(CastLineEvent);
	}

	void AudioHaulingItemFromWater()
	{
		FishingAkComp.HazePostEvent(HaulingItemFromWater);
	}

	void AudioThrowCatch()
	{
		FishingAkComp.HazePostEvent(ThrowCatchEvent);
	}

	void AudioStartReel()
	{
		FishingAkComp.HazePostEvent(StartReelEvent);
	}

	void AudioEndReel()
	{
		FishingAkComp.HazePostEvent(EndReelEvent);
	}

	void AudioStartCatchOnLine()
	{
		FishingAkComp.HazePostEvent(CatchOnLine);
	}

	void AudioRodWindUpStart()
	{
		FishingAkComp.HazePostEvent(RodWindUpStart);
	}

	void AudioRodWindUpEnd()
	{
		FishingAkComp.HazePostEvent(RodWindUpEnd);
	}

	void AudioRodStruggleStart()
	{
		FishingAkComp.HazePostEvent(RodStruggleStart);
	}

	void AudioRodStruggleEnd()
	{
		FishingAkComp.HazePostEvent(RodStruggleEnd);
	}

	void AudioCatchOnLine(float CatchingVolumeLevel)
	{
		FishingAkComp.SetRTPCValue("Rtcp_World_SideContent_Clockwork_Interactions_Fishing_Catch_OnLine_CatchingVolumeLevel", CatchingVolumeLevel);
	}
	
	void AudioWindingUpRod(float WindValue)
	{
		FishingAkComp.SetRTPCValue("Rtcp_World_SideContent_Clockwork_Interactions_Fishing_Rod_WindingUp", WindValue);
	}

	void AudioReelingCatch(float InputValue)
	{
		FishingAkComp.SetRTPCValue("Rtcp_World_SideContent_Clockwork_Interactions_Fishing_Reel_Speed", InputValue);
	}

	void AudioReelingStruggle(float StruggleValue)
	{
		FishingAkComp.SetRTPCValue("Rtcp_World_SideContent_Clockwork_Interactions_Fishing_Rod_StruggleValue", StruggleValue);
	}

	void AudioRotatingRodBase(float RotationValue)
	{
		FishingAkComp.SetRTPCValue("Rtcp_World_SideContent_Clockwork_Interactions_Fishing_Platform_Rotation", RotationValue);
	}
}