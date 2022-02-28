import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.StickyWall.CourtyardStickyWall;

class UCourtyardStickyWallCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Example");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ACourtyardStickyWall ActiveStickyWall;

	UButtonMashProgressHandle ButtonMashHandle;
	float ButtonMashDecay = 0.25f;

	UPROPERTY()
	UForceFeedbackEffect LandFeedback;

	UPROPERTY()
	UForceFeedbackEffect ReleaseFeedback;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
        	return EHazeNetworkActivation::DontActivate;

		if (Cast<ACourtyardStickyWall>(MoveComp.ForwardHit.Actor) == nullptr)
        	return EHazeNetworkActivation::DontActivate;

		if (DeactiveDuration < 0.5f)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
        	return EHazeNetworkDeactivation::DeactivateLocal;

		if (ButtonMashHandle.Progress < 1.f)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"StickyWall", MoveComp.ForwardHit.Actor);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ActiveStickyWall = Cast<ACourtyardStickyWall>(ActivationParams.GetObject(n"StickyWall"));
		
		Player.AddLocomotionFeature(ActiveStickyWall.PlayerFeatures[Player]);

		ButtonMashHandle = StartButtonMashProgressAttachToComponent(Player, Player.Mesh, NAME_None, FVector(0.f, 0.f, 200.f));
		ButtonMashHandle.bSyncOverNetwork = true;

		if (Player.IsMay())
		{
			Player.PlayerHazeAkComp.HazePostEvent(ActiveStickyWall.PlayEffortMayAudioEvent);
			Player.PlayerHazeAkComp.HazePostEvent(ActiveStickyWall.PlayStruggleAudioEvent);
		}
		else
		{
			Player.PlayerHazeAkComp.HazePostEvent(ActiveStickyWall.PlayEffortCodyAudioEvent);
			Player.PlayerHazeAkComp.HazePostEvent(ActiveStickyWall.PlayStruggleAudioEvent);
		}
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(n"CourtyardCannon", this);

		if (LandFeedback != nullptr)
			Player.PlayForceFeedback(LandFeedback, false, false, NAME_None, 1.f);

		if (ActiveStickyWall.VOBank != nullptr)
		{
			FVector PlayerLocation = Player.Mesh.GetSocketLocation(n"Spine2");
			FVector ToPlayerLocation = PlayerLocation - ActiveStickyWall.ActorLocation;
			ToPlayerLocation = ToPlayerLocation.ConstrainToPlane(ActiveStickyWall.ActorForwardVector);

			float DistanceFromMiddle = ToPlayerLocation.Size();
			if (DistanceFromMiddle <= 90.f)
			{
				if (Player.IsMay())
					PlayFoghornVOBankEvent(ActiveStickyWall.VOBank, n"FoghornDBPlayroomCastleDartBoardBullseyeMay");
				else
					PlayFoghornVOBankEvent(ActiveStickyWall.VOBank, n"FoghornDBPlayroomCastleDartBoardBullseyeCody");
			}
			else
			{
				if (Player.IsMay())
					PlayFoghornVOBankEvent(ActiveStickyWall.VOBank, n"FoghornDBPlayroomCastleDartBoardNotBullseyeMay");
				else
					PlayFoghornVOBankEvent(ActiveStickyWall.VOBank, n"FoghornDBPlayroomCastleDartBoardNotBullseyeCody");

			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.RemoveLocomotionFeature(ActiveStickyWall.PlayerFeatures[Player]);

		StopButtonMash(ButtonMashHandle);

		if (Player.IsMay())
		{
			Player.PlayerHazeAkComp.HazePostEvent(ActiveStickyWall.StopEffortMayAudioEvent);
			Player.PlayerHazeAkComp.HazePostEvent(ActiveStickyWall.StopStruggleAudioEvent);
		}
		else
		{
			Player.PlayerHazeAkComp.HazePostEvent(ActiveStickyWall.StopEffortCodyAudioEvent);
			Player.PlayerHazeAkComp.HazePostEvent(ActiveStickyWall.StopStruggleAudioEvent);
		}
		FVector ExitVelocity = ActiveStickyWall.ActorForwardVector * 1000.f;
		MoveComp.Velocity = ExitVelocity;

		
		if (ReleaseFeedback != nullptr)
			Player.PlayForceFeedback(ReleaseFeedback, false, false, NAME_None, 1.f);

		ActiveStickyWall = nullptr;

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(n"CourtyardCannon", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		ButtonMashHandle.Progress -= ButtonMashDecay * DeltaTime;	
		ButtonMashHandle.Progress += ButtonMashHandle.MashRateControlSide * 0.1f * DeltaTime;
		Player.SetAnimFloatParam(n"StruggleAmount", ButtonMashHandle.Progress);
		
		float MashRate = Player.HasControl() ? ButtonMashHandle.MashRateControlSide * 0.12f : ButtonMashHandle.MashRateRemoteSide * 0.12f;
		Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interactions_VelcroWall_MashRate", MashRate);
		
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"StickyWall");
		if (HasControl())
		{
			FVector TargetFacingDirection = -ActiveStickyWall.ActorForwardVector;
			MoveComp.SetTargetFacingDirection(TargetFacingDirection, 5.f);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}
		FrameMove.ApplyTargetRotationDelta();

		MoveCharacter(FrameMove, n"StickyWall");
	}
}