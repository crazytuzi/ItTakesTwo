import Cake.LevelSpecific.PlayRoom.PillowFort.TechDoubleInteract.TVHackingActor;
import Cake.LevelSpecific.PlayRoom.PillowFort.TechDoubleInteract.TVHackingRemote;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureArcadeScreenLever;

class UTVHackingStickCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 30;

	AHazePlayerCharacter Player;
	ATVHackingRemote RemoteActor;
	UHazeBaseMovementComponent MoveComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartIconMoveAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopIconMoveAudioEvent;

	UPROPERTY(Category = "Setup")
	TPerPlayer<ULocomotionFeatureArcadeScreenLever> JoystickFeatures;
	ULocomotionFeatureArcadeScreenLever AnimFeature;

	bool bIsLeftPlayer;
	FVector2D PlayerInput;

	bool bJoystickIsMoving = false;

	float NetworkRate = 0.075;
	float NetworkNewTime = 0.f;

	FHazeAcceleratedVector2D AcceleratedTargetInput;
	FVector2D TargetInput;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		RemoteActor = Cast<ATVHackingRemote>(GetAttributeObject(n"TVRemoteActor"));
		MoveComp = UHazeBaseMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"InteractingLeftTV"))
		{
			return EHazeNetworkActivation::ActivateUsingCrumb;
		}
		else if(IsActioning(n"InteractingRightTV"))
		{
			return EHazeNetworkActivation::ActivateUsingCrumb;
		}
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(n"InteractingLeftTV") && !IsActioning(n"InteractingRightTV"))
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(IsActioning(n"InteractingLeftTV"))
			bIsLeftPlayer = true;
		else if (IsActioning(n"InteractingRightTV"))
			bIsLeftPlayer = false;

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		RemoteActor.SetAnimBoolParam(n"HasInteractingPlayer", true);

		if(Player.IsMay())
		{
			AnimFeature = JoystickFeatures[0];
			Player.AttachToComponent(RemoteActor.JoystickSkelMesh, n"Attach_May", EAttachmentRule::SnapToTarget);
		}
		else
		{
			AnimFeature = JoystickFeatures[1];
			Player.AttachToComponent(RemoteActor.JoystickSkelMesh, n"Attach_Cody", EAttachmentRule::SnapToTarget);
		}

		Player.AddLocomotionFeature(AnimFeature);

		RemoteActor.RemoteHazeAkComp.HazePostEvent(StartIconMoveAudioEvent);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoteActor.OnInteractionExit(Player, bIsLeftPlayer);
		RemoteActor.SetAnimBoolParam(n"HasInteractingPlayer", false);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);

		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		RemoteActor.RemoteHazeAkComp.HazePostEvent(StopIconMoveAudioEvent);

		if(AnimFeature != nullptr)
			Player.RemoveLocomotionFeature(AnimFeature);

		Player.SetCapabilityActionState(n"LockedIntoInteraction", EHazeActionState::Inactive);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			PlayerInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

			SetAnimFloatValues(PlayerInput);
			NetworkVerify(DeltaTime);

			// PrintToScreen("player input X " + PlayerInput.X);
			// PrintToScreen("player input Y " + PlayerInput.Y);
			RemoteActor.RemoteHazeAkComp.SetRTPCValue("Rtpc_World_Playroom_Pillowfort_Interactable_TVHacking_Input_X", FMath::Abs(PlayerInput.X));
			RemoteActor.RemoteHazeAkComp.SetRTPCValue("Rtpc_World_Playroom_Pillowfort_Interactable_TVHacking_Input_Y", FMath::Abs(PlayerInput.Y));

			// float TotalPlayerInput = (FMath::Abs(PlayerInput.X) + FMath::Abs(PlayerInput.Y));

			// if(!bJoystickIsMoving && TotalPlayerInput > 0)
			// {
			// 	RemoteActor.RemoteHazeAkComp.HazePostEvent(StartJoystickMoveAudioEvent);
			// 	bJoystickIsMoving = true;
			// }

			// if(TotalPlayerInput == 0 && bJoystickIsMoving)
			// {
			// 	RemoteActor.RemoteHazeAkComp.HazePostEvent(StopJoystickMoveAudioEvent);
			// 	bJoystickIsMoving = false;
			// }
		}
		else
		{
			AcceleratedTargetInput.AccelerateTo(TargetInput, 0.5f, DeltaTime);
			
			SetAnimFloatValues(AcceleratedTargetInput.Value);
		}

		FHazeRequestLocomotionData LocomotionData;
		LocomotionData.AnimationTag = AnimFeature.Tag;

		Player.RequestLocomotion(LocomotionData);
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"TVHackingStickCapability");
			FrameMove.OverrideCollisionProfile(n"NoCollision");
			MoveComp.Move(FrameMove);
		}
	}

	void SetAnimFloatValues(FVector2D Input)
	{
		Player.SetAnimFloatParam(n"JoystickInputX", Input.X);
		RemoteActor.SetAnimFloatParam(n"JoystickInputX", Input.X);
		Player.SetAnimFloatParam(n"JoystickInputY", Input.Y);
		RemoteActor.SetAnimFloatParam(n"JoystickInputY", Input.Y);
	}

	void NetworkVerify(float DeltaTime)
	{
		if(NetworkNewTime <= System::GameTimeInSeconds)
		{
			NetworkNewTime = System::GameTimeInSeconds + NetworkRate;

			NetSetTargetInput(PlayerInput);
		}
	}

	UFUNCTION(NetFunction)
	void NetSetTargetInput(FVector2D PlayerInput)
	{
		TargetInput = PlayerInput;
	}
}