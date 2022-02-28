import Vino.Characters.AICharacter;
import Vino.Movement.Components.MovementComponent;
import Vino.Interactions.InteractionComponent;
import Vino.Movement.MovementSettings;
import Vino.Checkpoints.Statics.DeathStatics;
import Peanuts.Audio.AudioStatics;

import void EnableHeadButtingDinoSlam() from "Cake.LevelSpecific.PlayRoom.GoldBerg.HeadButtingDino";
import void DisableHeadButtingDinoSlam() from "Cake.LevelSpecific.PlayRoom.GoldBerg.HeadButtingDino";

// Struct representing a set of angles to transform the neck
// Manipulated in this file, then read in the ABP
struct FDinoCraneAngles
{
	// Yaw of the entire neck
	UPROPERTY()
	float BaseYaw;

	// Pitch of the entire neck
	UPROPERTY()
	float BasePitch;

	// Relative pitch of base-joint
	UPROPERTY()
	float Neck;

	// Relative pitch of first neck-joint from base
	UPROPERTY()
	float Neck1;

	// Relative pitch of second neck-joint from base
	UPROPERTY()
	float Neck2;

	// Relative pitch of head-joint
	UPROPERTY()
	float HeadPitch;

	// Relative pitch of head-joint
	UPROPERTY()
	float HeadYaw;

	FDinoCraneAngles ToDegrees()
	{
		FDinoCraneAngles Result;
		Result.BaseYaw = BaseYaw * RAD_TO_DEG;
		Result.BasePitch = BasePitch * RAD_TO_DEG;
		Result.Neck = Neck * RAD_TO_DEG;
		Result.Neck1 = Neck1 * RAD_TO_DEG;
		Result.Neck2 = Neck2 * RAD_TO_DEG;
		Result.HeadPitch = HeadPitch * RAD_TO_DEG;
		Result.HeadYaw = HeadYaw * RAD_TO_DEG;

		return Result;
	}
}

import void InitDinoCraneRiding(AHazePlayerCharacter Player, ADinoCrane DinoCrane) from "Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCraneRidingComponent";
import void RemoveDinoCraneRiding(AHazePlayerCharacter Player, ADinoCrane DinoCrane) from "Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCraneRidingComponent";

//delegate void FPlayerDinoInteractionChanged(AHazePlayerCharacter Player, bool JumpedOn);
event void FPlayerDinoInteractionChanged(AHazePlayerCharacter Player, bool JumpedOn);

settings ADinoCraneDefaultMovementSettings for UMovementSettings
{
	ADinoCraneDefaultMovementSettings.StepUpAmount = 0.f;
}

UCLASS(Abstract)
class ADinoCrane : AAICharacter
{
	default AIMovementComponent.DefaultMovementSettings = ADinoCraneDefaultMovementSettings;

	UPROPERTY()
	FText MoveNeckupText;

	UPROPERTY()
	FText MoveNeckDownText;

	UPROPERTY()
	FText ReleaseText;

	UPROPERTY(Category = "DinoInteraction")
	FPlayerDinoInteractionChanged DinoInteractionChanged;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 8000;
	default DisableComponent.bRenderWhileDisabled = true;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = PlayerAttachSocket)
	UInteractionComponent RideInteraction;
	default RideInteraction.bUseLazyTriggerShapes = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RideJumpOffPoint;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent EatOtherPlayerInteraction;
	default EatOtherPlayerInteraction.ActivationSettings.ActivationTag = n"DinoCraneInteraction";
	default EatOtherPlayerInteraction.ActivationSettings.WaitingSheet = Asset("/Game/Blueprints/LevelSpecific/PlayRoom/Goldberg/Dinoland/DinoCrane/DinoCraneWaitingSheet.DinoCraneWaitingSheet");

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent SyncHeadPositionTarget;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent StartBodyMovementEvent;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent StopBodyMovementEvent;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent NeckOverlappingEvent;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent StartCraneMovementEvent;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent StopCraneMovementEvent;

	bool bHasTriggeredNeckOverlap = false;	
	bool bPlayingCraneLoop = false;
	float LastHeadDelta;
	float LastRotationDelta; 

	bool bWaitForAwake = true;
	float Timer = 0.f;

	// Movement speed of the dino in the pen
	UPROPERTY()
	float DinoMovementSpeed = 1000.f;

	// Rotation speed of the dino's rotation
	UPROPERTY()
	float DinoRotationSpeed = 10.f;

	// Sheet given to the player while they are riding the dino
	UPROPERTY(EditDefaultsOnly)
	UHazeCapabilitySheet RideSheet;

	// Locomotion asset given to the player while they are riding the dino
	UPROPERTY(EditDefaultsOnly)
	UHazeLocomotionAssetBase CodyLocomotionAsset;

	// Locomotion asset given to the player while they are riding the dino
	UPROPERTY(EditDefaultsOnly)
	UHazeLocomotionAssetBase MayLocomotionAsset;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence EatOtherPlayerAnimation_Cody;
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence EatOtherPlayerAnimation_May;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence EatOtherPlayerAndSlammerAnimation_Cody;
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence EatOtherPlayerAndSlammerAnimation_May;
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence EatOtherPlayerAndSlammerAnimation_DinoSlammer;

	// Readable property for ABP for neck joints
	UPROPERTY(NotEditable)
	FDinoCraneAngles CraneAngles;

	// The base pivot of the neck, used as a basis for transformation
	UPROPERTY(DefaultComponent)
	USceneComponent NeckBase;

	// Minimum height relative to the root of the head during movement
	UPROPERTY()
	float MinHeadHeight = 1100.f;

	// Maximum height relative to the root of the head during movement
	UPROPERTY()
	float MaxHeadHeight = 2000.f;

	// The heads relative location (in neck-space with X forward)
	UPROPERTY(NotEditable)
	FVector HeadRelativeLocation;

	// The length of the bones in the neck
	UPROPERTY()
	float NeckBoneLength = 880.f;

	// The default position of the neck
	UPROPERTY(meta = (MakeEditWidget))
	FVector DefaultHeadPosition;

	// Head head movement speed during normal movement
	UPROPERTY()
	float HeadMoveSpeed = 1200.f;

	UPROPERTY(NotVisible)
	float DinoCraneHeadNormalizedVelo;

	float MovePlatformSpeed;
	bool bIsEatingOtherPlayer = false;
	TArray<UObject> DisableEatOtherPlayerInstigators;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter RidingPlayer;

	AHazeActor GrabbedPlatform;
	FVector InitialCapsuleOffset;
	float EatOtherCooldownUntil = 0.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		HeadRelativeLocation = GetDefaultRelativePosition();
		LastHeadDelta = HeadRelativeLocation.Z;
		LastRotationDelta = FMath::Abs(GetActorRotation().Yaw);

		SetPositionOfDinoHead(GetWorldPositionOfHead(), GetActorForwardVector());
		
	}

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		AAICharacter::BeginPlay();

		AddCapability(n"DinoCraneMovementCapability");
		AddCapability(n"DinoCraneBiteAirCapability");
		AddCapability(n"DinoCraneMoveGrabbedPlatformCapability");
		AddCapability(n"DinoCraneEatOtherPlayerCapability");

		RideInteraction.OnActivated.AddUFunction(this, n"OnRideInteractionActivated");

		// Get the actual length of the neck bones here, we can't do it in construction script
		NeckBoneLength = Mesh.GetSocketTransform(n"Neck1", ERelativeTransformSpace::RTS_ParentBoneSpace).Translation.Size();

		FHazeTriggerCondition Condition;
		Condition.Delegate.BindUFunction(this, n"CheckDinoHeadNearby");
		Condition.bOnlyCheckOnPlayerControl = true;
		EatOtherPlayerInteraction.AddTriggerCondition(n"DinoHeadNearby", Condition);

		FHazeTriggerCondition EatCondition;
		EatCondition.Delegate.BindUFunction(this, n"CheckCanEatOtherPlayer");
		EatOtherPlayerInteraction.AddTriggerCondition(n"CanEatOtherPlayer", EatCondition);

		EatOtherPlayerInteraction.Disable(n"NobodyOnDino");
		EatOtherPlayerInteraction.OnActivated.AddUFunction(this, n"StartEatingOtherPlayer");			
	}

	UFUNCTION()
	bool CheckDinoHeadNearby(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
	{
		FVector HeadWorldPos = GetWorldPositionOfHead();
		FVector TriggerRelativePos = ActorRotation.UnrotateVector(Trigger.WorldLocation - HeadWorldPos).Abs;
		return TriggerRelativePos.Z < 400.f && TriggerRelativePos.X < 1600 && TriggerRelativePos.Y < 400.f;
	}

	UFUNCTION()
	bool CheckCanEatOtherPlayer(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
	{
		if (EatOtherCooldownUntil != 0.f && Time::GameTimeSeconds < EatOtherCooldownUntil)
			return false;
		if (!Player.OtherPlayer.IsAnyCapabilityActive(n"RidingHeadbuttingDino"))
			return false;
		return DisableEatOtherPlayerInstigators.Num() == 0;
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_PlayerMounted(FHazeDelegateCrumbData CrumbData)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Player"));
		SetControlSide(Player);
	}

	UFUNCTION()
	void OnRideInteractionActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		CleanupCurrentMovementTrail();

		if (HasControl())
		{
			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.Movement = EHazeActorReplicationSyncTransformType::NoMovement;
			CrumbParams.AddObject(n"Player", Player);
			CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_PlayerMounted"), CrumbParams);
		}

		HazeAudio::SetPlayerPanning(HazeAkComp, Player);

		RidingPlayer = Player;

		Player.TriggerMovementTransition(this);

		InitDinoCraneRiding(Player, this);
		Player.AddCapabilitySheet(RideSheet, EHazeCapabilitySheetPriority::High, this);
		Player.AddLocomotionAsset(Player.IsCody() ? CodyLocomotionAsset : MayLocomotionAsset, this);
		UHazeTriggerUserComponent::Get(Player).SetTriggerRequiredTag(n"DinoCraneInteraction");
		RideInteraction.Disable(n"Riding");
		StartDino();

		if(StartBodyMovementEvent != nullptr)
		{
			HazeAkComp.HazePostEvent(StartBodyMovementEvent);
		}		

		EatOtherPlayerInteraction.AttachToComponent(Player.OtherPlayer.RootComponent);
		EatOtherPlayerInteraction.Enable(n"NobodyOnDino");
		
	}

	UFUNCTION()
	void ReleaseRidingPlayer()
	{
		if (HasControl())
			NetReleaseRidingPlayer();
	}

	UFUNCTION(NetFunction)
	private void NetReleaseRidingPlayer()
	{
		StopDino();
		if(StopBodyMovementEvent != nullptr)
		{
			HazeAkComp.HazePostEvent(StopBodyMovementEvent);
		}	

		if (RidingPlayer == nullptr)
			return;

		auto PreviousPlayer = RidingPlayer;
		RemoveDinoCraneRiding(RidingPlayer, this);
		RidingPlayer.TriggerMovementTransition(this);

		RidingPlayer.ClearLocomotionAssetByInstigator(this);
		UHazeTriggerUserComponent::Get(RidingPlayer).SetTriggerRequiredTag(NAME_None);
		RideInteraction.EnableAfterFullSyncPoint(n"Riding");
		RidingPlayer = nullptr;
		GrabbedPlatform = nullptr;		

		EatOtherPlayerInteraction.DetachFromParent(true);
		EatOtherPlayerInteraction.Disable(n"NobodyOnDino");
	}

	UFUNCTION(BlueprintEvent)
	void StartDino()
	{
		DinoInteractionChanged.Broadcast(RidingPlayer, true);
	}

	UFUNCTION(BlueprintEvent)
	void StopDino()
	{
		DinoInteractionChanged.Broadcast(RidingPlayer, false);
	}

	UFUNCTION(BlueprintEvent)
	void StartBigDinoStomp()
	{
		RidingPlayer.BlockCapabilities(CapabilityTags::Interaction, this);
		RidingPlayer.BlockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION()
	void StopBigDinoStomp()
	{
		RidingPlayer.UnblockCapabilities(CapabilityTags::Interaction, this);
		RidingPlayer.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	void UpdateAudio()
	{
		float DinoCraneBodyNormalizedVelo = HazeAudio::NormalizeRTPC01(GetActorVelocity().Size(), 0.f, 1000.f);

		float DinoCraneHeadHeightPosition = HazeAudio::NormalizeRTPC01(HeadRelativeLocation.Z, -200.f, 2500.f);
		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::DinoCraneHeadElevation, DinoCraneHeadHeightPosition, 0.f);

		float HeadDelta = FMath::Abs(HeadRelativeLocation.Z - LastHeadDelta);
		LastHeadDelta = HeadRelativeLocation.Z;
		
		if(GrabbedPlatform == nullptr)
		{
			DinoCraneHeadNormalizedVelo = FMath::Clamp(HazeAudio::NormalizeRTPC01(HeadDelta, 0.f, 13.f), 0.f, 1.f);		
		}
		
		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::DinoCraneHeadMovementVelocity, DinoCraneHeadNormalizedVelo, 0.f);			

		if(DinoCraneHeadNormalizedVelo > 0 && !bPlayingCraneLoop && StartCraneMovementEvent != nullptr && !bWaitForAwake)			
		{
			HazeAkComp.HazePostEvent(StartCraneMovementEvent);
			bPlayingCraneLoop = true;
		}
		else if(DinoCraneHeadNormalizedVelo == 0 && bPlayingCraneLoop && StopCraneMovementEvent != nullptr)
		{
			HazeAkComp.HazePostEvent(StopCraneMovementEvent);
			bPlayingCraneLoop = false;
		}				

		float DinoCraneHeadFoldedPosition = FMath::Clamp(HazeAudio::NormalizeRTPC01(CraneAngles.BasePitch, -44.f, -159.f), 0.f, 1.f);
		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::DinoCraneHeadFoldedElevation, DinoCraneHeadFoldedPosition, 0.f);

		float RotationDelta = FMath::Abs(GetActorRotation().Yaw) - LastRotationDelta;
		LastRotationDelta = FMath::Abs(GetActorRotation().Yaw);

		float DinoCraneNormalizedAngularVelocity = FMath::Abs(HazeAudio::NormalizeRTPC01(RotationDelta, 0.f, 6.f));

		float DinoCraneNormalizedCombinedVelocity = FMath::Clamp(DinoCraneBodyNormalizedVelo + DinoCraneNormalizedAngularVelocity, 0.f, 1.f);		
		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::DinoCraneMovementVelocity, FMath::Abs(DinoCraneNormalizedCombinedVelocity), 0.f);		
		
		if(CraneAngles.Neck2 <= 179.f && bHasTriggeredNeckOverlap)
		{
			bHasTriggeredNeckOverlap = false;
		}

		if(DinoCraneHeadFoldedPosition < 1.0f && bHasTriggeredNeckOverlap)
		{
			bHasTriggeredNeckOverlap = false;
		}

		if(CraneAngles.Neck2 == 180.f && DinoCraneHeadFoldedPosition == 1.0f && !bHasTriggeredNeckOverlap)
		{
			if(NeckOverlappingEvent != nullptr)
			{
				HazeAkComp.HazePostEvent(NeckOverlappingEvent);					
			}
			bHasTriggeredNeckOverlap = true;
		}

		//Debug
		// PrintToScreen("DinoCraneHeadElevation : " + DinoCraneHeadHeightPosition);
		// PrintToScreen("DinoCraneHeadMovementVelocity : " + DinoCraneHeadNormalizedVelo);
		// PrintToScreen("DinoCraneHeadFoldedElevation : " + DinoCraneHeadFoldedPosition);
		// PrintToScreen("DinoCraneMovementVelocity : " + FMath::Abs(DinoCraneNormalizedCombinedVelocity));
		//~Debug
	}

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bWaitForAwake)
		{
			Timer += DeltaTime;

			if(Timer >= 1.f)
			{
				bWaitForAwake = false;
			}
		}
		if(HasControl())
		{
			SyncHeadPositionTarget.Value = HeadRelativeLocation;
			UpdateAudio();
		}
		else
		{
			if(GrabbedPlatform == nullptr && !IsEatingOtherPlayer())
			{
				if (HeadRelativeLocation != SyncHeadPositionTarget.Value)
				{
					HeadRelativeLocation = SyncHeadPositionTarget.Value;
					SetPositionOfDinoHead(GetWorldPositionOfHead(), GetActorForwardVector());
				}
			}

			UpdateAudio();
		}
	}

	void SetPositionOfDinoHead(FVector InGrabPosition, FVector HeadForward)
	{
		// Offset grab-position so the front of the head will be at the position
		FVector GrabPosition = InGrabPosition;
		GrabPosition -= HeadForward * 800.f;
		
		// Get position in neck-space
		FTransform NeckTransform = GetNeckBaseNoRotationTransform();
		FVector RelativeGrabPosition = NeckTransform.InverseTransformPosition(GrabPosition);

		// Distance to target grab position
		float Distance = RelativeGrabPosition.Size();

		// Determine size of the lift-rectangle with distance as diagonal
		float A = FMath::Sqrt((9.f * NeckBoneLength * NeckBoneLength - Distance * Distance) / 8.f);

		// Distance too big, just stretch as much as possible
		if (Distance > NeckBoneLength * 3.f)
			A = 0.f;

		// Now determine the bone rotations base on the size of the rectangle
		float BoneAngle = FMath::Acos(A /NeckBoneLength );

		// 90 degree inverse
		BoneAngle = PI/2.f - BoneAngle;
		CraneAngles.Neck = BoneAngle;
		CraneAngles.Neck1 = -2.f * BoneAngle;
		CraneAngles.Neck2 = 2.f * BoneAngle;

		// Rotate the base to align with target
		CraneAngles.BaseYaw = -FMath::Atan2(
			RelativeGrabPosition.Y,
			RelativeGrabPosition.X
		);
		CraneAngles.BasePitch = -FMath::Atan2(
			RelativeGrabPosition.Z,
			RelativeGrabPosition.Size2D(FVector::UpVector)
		);
		CraneAngles.BasePitch -= FMath::Asin(A / Distance);

		// Rotate head
		FVector RelativeForward = NeckTransform.InverseTransformVector(HeadForward);
		float HeadAddYaw = FMath::Atan2(
			RelativeForward.Y,
			RelativeForward.X
		);
		float HeadAddPitch = FMath::Atan2(
			RelativeForward.Z,
			RelativeForward.Size2D(FVector::UpVector)
		);

		// We also take into account the base and and pitch of the base, so that the head (by default) looks straight forwards, then add the additional rotation to look towards the given input forward
		CraneAngles.HeadPitch = -(BoneAngle + CraneAngles.BasePitch + HeadAddPitch);
		CraneAngles.HeadYaw = -(CraneAngles.BaseYaw + HeadAddYaw);

		CraneAngles = CraneAngles.ToDegrees();
	}

	void MoveHead(FVector MoveAmount, bool bSetStandardDistance)
	{
		HeadRelativeLocation += MoveAmount;

		// Clamp height of head
		HeadRelativeLocation.Z = FMath::Clamp(
			HeadRelativeLocation.Z,
			MinHeadHeight,
			MaxHeadHeight
		);

		if (bSetStandardDistance)
		{
			FVector DefaultRelative = GetDefaultRelativePosition();
			HeadRelativeLocation.X = DefaultRelative.X;
		}

		// Update the neck
		SetPositionOfDinoHead(GetWorldPositionOfHead(), GetActorForwardVector());
	}

	// Transforms the heads target relative position into world space
	FVector GetWorldPositionOfHead()
	{
		FTransform NeckTransform = GetNeckBaseNoRotationTransform();
		return NeckTransform.TransformPosition(HeadRelativeLocation);
	}

	// Get the transform of the neck-base with no rotation
	FTransform GetNeckBaseNoRotationTransform()
	{
		return NeckBase.WorldTransform;
	}

	// Get the relative (neck-space) default head position
	FVector GetDefaultRelativePosition()
	{
		// First transform default position to world-space
		FVector WorldPosition = RootComponent.WorldTransform.TransformPosition(DefaultHeadPosition);

		// Then transform into neck-space
		FTransform NeckTransform = GetNeckBaseNoRotationTransform();
		return NeckTransform.InverseTransformPosition(WorldPosition);
	}

	UFUNCTION()
	void StartEatingOtherPlayer(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		// TODO: This has a race condition right now, the interaction point's disable status is checked on
		// our side, rather than on the other player's side. Once we can override interaction point
		// control sides, make sure we change the eat other player's one appropriately.
		bIsEatingOtherPlayer = true;
		DisableHeadButtingDinoSlam();
	}

	void StopEatingOtherPlayer()
	{
		bIsEatingOtherPlayer = false;
		EnableHeadButtingDinoSlam();
	}

	bool IsEatingOtherPlayer()
	{
		return bIsEatingOtherPlayer;
	}
}