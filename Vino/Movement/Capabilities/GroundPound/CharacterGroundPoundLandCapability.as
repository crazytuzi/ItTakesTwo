import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.GroundPound.GroundPoundNames;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;

class UCharacterGroundPoundLandCapability : UCharacterMovementCapability
{
	default RespondToEvent(GroundPoundEventActivation::Falling);

	default CapabilityTags.Add(MovementSystemTags::GroundPound);
	default CapabilityTags.Add(GroundPoundTags::Land);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 15;

	UCharacterGroundPoundComponent GroundPoundComp;
	UPrimitiveComponent Floor = nullptr;
	AHazePlayerCharacter PlayerOwner = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		Super::Setup(Params);
		GroundPoundComp = UCharacterGroundPoundComponent::GetOrCreate(Owner);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		ensure(PlayerOwner != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!GroundPoundComp.IsCurrentState(EGroundPoundState::Falling))
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.DownHit.bBlockingHit)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		if (MoveComp.IsGrounded())
		{
			OutParams.AddActionState(GroundPoundSyncNames::LandGrounded);

			auto WantedFloor = MoveComp.DownHit.Component;
			if (WantedFloor != nullptr && WantedFloor.Owner != nullptr && WantedFloor.IsNetworked())
			{
				OutParams.AddObject(GroundPoundSyncNames::LandPrimitive, WantedFloor);
				
				UGroundPoundedCallbackComponent GroundPoundCallbackComponent = UGroundPoundedCallbackComponent::Get(WantedFloor.Owner);
				if(GroundPoundCallbackComponent != nullptr)
				{
					if(GroundPoundCallbackComponent.CanTriggerEvent(PlayerOwner, WantedFloor))
						OutParams.AddObject(GroundPoundSyncNames::CallbackComp, GroundPoundCallbackComponent);
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		Floor = Cast<UPrimitiveComponent>(Params.GetObject(GroundPoundSyncNames::LandPrimitive));
		
		if (Params.GetActionState(GroundPoundSyncNames::LandGrounded))
		{
			GroundPoundComp.GroundPoundLand();

			auto GroundPoundCallbackComponent = Cast<UGroundPoundedCallbackComponent>(Params.GetObject(GroundPoundSyncNames::CallbackComp));
			if (GroundPoundCallbackComponent != nullptr)
				GroundPoundCallbackComponent.OnActorGroundPounded.Broadcast(PlayerOwner);

			PlayerOwner.PlayForceFeedback(GroundPoundComp.LandForceFeedbackEffect, false, false, n"GroundPoundLand");

			FHazeCameraImpulse CamImpulse = GroundPoundComp.CurrentLandCameraImpulse;
			CamImpulse.WorldSpaceImpulse *= PlayerOwner.MovementWorldUp;

			if (SceneView::IsFullScreen())
			{
				for (AHazePlayerCharacter Player : Game::GetPlayers())
				{
					Player.PlayCameraShake(GroundPoundComp.CurrentLandCameraShake, 2.f);
					Player.ApplyCameraImpulse(CamImpulse, this);
				}
			}
			else
			{
				PlayerOwner.PlayCameraShake(GroundPoundComp.CurrentLandCameraShake, 2.f);
				PlayerOwner.ApplyCameraImpulse(CamImpulse, this);
			}
		}
		else
		{
			GroundPoundComp.ResetState();
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (!GroundPoundComp.IsCurrentState(EGroundPoundState::Landing))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		GroundPoundComp.LandedTimer += DeltaTime;
		GroundPoundComp.LandedFrameCounter += 1;

		FHazeFrameMovement LandMove = MoveComp.MakeFrameMovement(n"GroundPoundLand");

		if(HasControl())
		{
			LandMove.OverrideStepUpHeight(0.f);

			if(Floor != nullptr)
				LandMove.SetMoveWithComponent(Floor);
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			LandMove.ApplyConsumedCrumbData(CrumbData);
		}

		MoveCharacter(LandMove, FeatureName::GroundPound);
		CrumbComp.LeaveMovementCrumb();
	}
}
