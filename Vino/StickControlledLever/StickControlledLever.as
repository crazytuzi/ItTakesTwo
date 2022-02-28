import Vino.Interactions.InteractionComponent;
import Peanuts.Audio.AudioStatics;

event void FStickControlledLeverSignature(float Value);
event void FInteractionStateChangedSignature(AHazePlayerCharacter player);

class UStickControlledLeverFeature : UHazeLocomotionFeatureBase
{
	default Tag = n"StickControlledLever";

	UPROPERTY()
	FHazePlaySequenceData Enter;

	UPROPERTY()
	FHazePlayBlendSpaceData BlendSpace;

	UPROPERTY()
	FHazePlayBlendSpaceData AdditiveEffort;

	UPROPERTY()
	FHazePlaySequenceData IKReference;
};

class AStickControlledLever : AHazeActor
{
	// Alpha per second that the level moves if the stick is held
	UPROPERTY(Category = "Lever")
	float LeverPullSpeed = 1.f;

	// How fast the player's lever pulling accelerates. 0 indicates no acceleration and constant speed.
	UPROPERTY(Category = "Lever")
	float LeverPullAcceleration = 1.f;

	// What position between 0 and 1 is considered the neutral starting position
	UPROPERTY(Category = "Lever", Meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float NeutralPosition = 0.f;

	// Whether to automatically return the stick back to neutral when nobody is holding it
	UPROPERTY(Category = "Lever")
	bool bAutoReturnToNeutral = false;

	// How fast the stick returns to neutral after releasing it
	UPROPERTY(Category = "Lever", Meta = (EditCondition = "bAutoReturnToNeutral", EditConditionHides))
	float ReturnToNeutralSpeed = 1.f;

	// How fast the stick returning to neutral accelerates. 0 indicates no acceleration and constant speed.
	UPROPERTY(Category = "Lever", Meta = (EditCondition = "bAutoReturnToNeutral", EditConditionHides))
	float ReturnToNeutralAcceleration = 1.f;

	// If set, the camera direction is ignored for stick input, and left on the stick is always backwards on the lever.
	UPROPERTY(Category = "Lever")
	bool bUseRawStickControls = false;

	// What feature to request while pulling the lever
	UPROPERTY(Category = "Animation")
	FName AnimationFeatureTag = n"StickControlledLever";

	// Feature to add to the player while they are pulling the lever
	UPROPERTY(Category = "Animation")
	UHazeLocomotionFeatureBase AddedFeature_May;

	// Feature to add to the player while they are pulling the lever
	UPROPERTY(Category = "Animation")
	UHazeLocomotionFeatureBase AddedFeature_Cody;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartMoveAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopMoveAudioEvent;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent LeverHazeAkComp;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = InteractionComp)
	UHazeSkeletalMeshComponentBase PreviewMesh;
	default PreviewMesh.bHiddenInGame = true;
	default PreviewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default PreviewMesh.bIsEditorOnly = true;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncPosition;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 5000.f;

	UPROPERTY()
	FStickControlledLeverSignature LeverValueChanged;

	UPROPERTY()
	FInteractionStateChangedSignature PlayerStartedInteracting;

	UPROPERTY()
	FInteractionStateChangedSignature PlayerLeft;

	bool bHasStartedAudio = false;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	private AHazePlayerCharacter PlayerUser;
	private float PlayerUserInput = 0.f;

	private float PreviousPosition = 0.f;
	private float StickVelocity = 0.f;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		PreviewMesh.SetCullDistance(Editor::GetDefaultCullingDistance(PreviewMesh) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetPlayerUsingLever() property
	{
		return PlayerUser;
	}

	float GetLeverVelocity() property
	{
		return StickVelocity;
	}

	float GetLeverPosition() property
	{
		return SyncPosition.Value;
	}

	UHazeLocomotionFeatureBase GetAddedFeature() property
	{
		if (PlayerUser.IsCody())
			return AddedFeature_Cody;
		else
			return AddedFeature_May;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"LeverActivated");

		SyncPosition.Value = NeutralPosition;
		PreviousPosition = NeutralPosition;
	}

	void MoveStick(float DeltaTime, float TargetPosition, float MaxSpeed, float Acceleration)
	{
		if (FMath::IsNearlyEqual(TargetPosition, SyncPosition.Value, 0.01f))
		{
			// Already very close to the target, so snap to it
			SyncPosition.Value = TargetPosition;
			StickVelocity = 0.f;
			return;
		}

		float Direction = FMath::Sign(TargetPosition - SyncPosition.Value);
		if (Acceleration <= 0.f)
		{
			// Snap speed to wanted speed
			StickVelocity = Direction * MaxSpeed;
		}
		else
		{
			// Accelerate the speed at which we move
			StickVelocity += (DeltaTime * Direction);
			StickVelocity = FMath::Clamp(StickVelocity, -MaxSpeed, +MaxSpeed);
		}

		float NewPosition = SyncPosition.Value + (StickVelocity * DeltaTime);
		if ((Direction > 0.f && NewPosition >= TargetPosition)
			|| (Direction < 0.f && NewPosition <= TargetPosition))
		{
			// We overshot the target, so just stop at the target
			SyncPosition.Value = TargetPosition;
			StickVelocity = 0.f;
			return;
		}

		// Still going towards the target
		SyncPosition.Value = FMath::Clamp(NewPosition, 0.f, 1.f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		if (FMath::Abs(StickVelocity) != 0.f && !bHasStartedAudio)
		{
			bHasStartedAudio = true;
			LeverHazeAkComp.HazePostEvent(StartMoveAudioEvent);
		}
		else if (FMath::Abs(StickVelocity) == 0.f && bHasStartedAudio)
		{
			bHasStartedAudio = false;
			LeverHazeAkComp.HazePostEvent(StopMoveAudioEvent);
		}

		LeverHazeAkComp.SetRTPCValue("Rtpc_World_Shared_Interactables_StickControlledLever_Velocity", StickVelocity);
		
		if (SyncPosition.HasControl())
		{
			// Move the stick in the direction of the input
			if (PlayerUser != nullptr)
			{
				if (PlayerUserInput > 0.f)
					MoveStick(DeltaTime, 1.f, FMath::Abs(PlayerUserInput) * LeverPullSpeed, LeverPullAcceleration);
				else if (PlayerUserInput < 0.f)
					MoveStick(DeltaTime, 0.f, FMath::Abs(PlayerUserInput) * LeverPullSpeed, LeverPullAcceleration);
				else
					StickVelocity = 0.f;
			}
			// Return to neutral if nobody is interacting
			else if (bAutoReturnToNeutral)
			{
				MoveStick(DeltaTime, NeutralPosition, ReturnToNeutralSpeed, ReturnToNeutralAcceleration);
			}
		}
		else
		{
			if (PreviousPosition != SyncPosition.Value)
				StickVelocity = FMath::Sign(SyncPosition.Value - PreviousPosition);
			else
				StickVelocity = 0.f;
		}

		// Send change events if the value has changed
		if (PreviousPosition != SyncPosition.Value)
		{
			LeverValueChanged.Broadcast(SyncPosition.Value);
			PreviousPosition = SyncPosition.Value;
		}

		// Stop ticking if nobody is interacting and we aren't returning to neutral
		if (PlayerUser == nullptr && (!bAutoReturnToNeutral || SyncPosition.Value == NeutralPosition))
		{
			SetActorTickEnabled(false);

			if (bHasStartedAudio)
			{
				LeverHazeAkComp.HazePostEvent(StopMoveAudioEvent);
				bHasStartedAudio = false;
			}
				
		}
			

		
		
		// if (StickVelocity == 0)
		// 	BP_StopMove();
		
		// if (StickVelocity > 0)
		// 	BP_StartMove();
	}

	UFUNCTION()
	void LeverActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		PlayerUser = Player;
		SyncPosition.OverrideControlSide(PlayerUser);
		Player.AddCapability(n"StickControlledLeverCapability");
		Player.SetCapabilityAttributeObject(n"StickControlledLever", this);
		Player.SetCapabilityAttributeObject(n"LeverInteractionComp", InteractionComp);

		if (AddedFeature != nullptr)
			Player.AddLocomotionFeature(AddedFeature);

		InteractionComp.Disable(n"IsInteractedWith");
		PlayerUserInput = 0.f;
		PlayerStartedInteracting.Broadcast(Player);

		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void LeverDeActivated()
	{
		PlayerUser.SetCapabilityAttributeObject(n"StickControlledLever", nullptr);
		PlayerLeft.Broadcast(PlayerUser);

		if (AddedFeature != nullptr)
			PlayerUser.RemoveLocomotionFeature(AddedFeature);

		PlayerUser = nullptr;

		// Don't re-enable the lever until a full sync point has passed,
		// that way we don't get issues due to the capability being
		// in a different actor channel.
		InteractionComp.EnableAfterFullSyncPoint(n"IsInteractedWith");
	}

	UFUNCTION(NetFunction)
	void NetForceStopLever()
	{
		if(PlayerUsingLever != nullptr)
			PlayerUsingLever.SetCapabilityActionState(n"ForceStopLever", EHazeActionState::ActiveForOneFrame);
	}

	void SetPlayerInput(float Input)
	{
		PlayerUserInput = Input;
	}
}