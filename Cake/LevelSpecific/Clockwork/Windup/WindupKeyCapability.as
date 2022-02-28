import Cake.Interactions.Windup.WindupCapability;
import Cake.Interactions.Windup.WindupActor;
import Cake.LevelSpecific.Clockwork.Windup.WindupKeyActor;
import Vino.Tutorial.TutorialStatics;

class UWindupKeyCapability : UWindupCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;

	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	const float ValidInput = 0.f;

	UInteractionComponent Interaction;
	AWindupKeyActor WindupActor;
	bool bWaitingForEnableFullSync = false;
	bool bWaitingForActivationFullSync = false;
	AHazePlayerCharacter PlayerOwner;
	UHazeMovementComponent MoveComponent;
	EWindupInputDirection LastInputType = EWindupInputDirection::None;
	float LastWindupAmount = 0.f;
	float FailedMoveLastFrameAount = 0.f;

	FVector LastSteeringVector;
	float LastValidInputAmount;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		MoveComponent = UHazeMovementComponent::Get(PlayerOwner);
	}
	
    UFUNCTION(BlueprintOverride)
    void PreTick(float DeltaTime)
	{
		if(!IsActive() && !IsBlocked() && !bWaitingForEnableFullSync)
		{
			Interaction = Cast<UInteractionComponent>(GetAttributeObject(n"Windup"));
			if(Interaction != nullptr)
			{
				WindupActor = Cast<AWindupKeyActor>(Interaction.GetOwner());
				if(WindupActor != nullptr)
				{
					UObject Removed;
					ConsumeAttribute(n"Windup", Removed);
				}
				else
				{
					Interaction = nullptr;
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(bWaitingForEnableFullSync)
			return EHazeNetworkActivation::DontActivate;

		if(WindupActor == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bWaitingForActivationFullSync)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(WindupActor.IsFinished(true))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ShowCancelPrompt(PlayerOwner, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::Interaction, this);
		WindupActor.SetPendingInteractionCapabiltiesBlocked(PlayerOwner, false);

		PlayerOwner.TriggerMovementTransition(this);
		PlayerOwner.AttachToComponent(Interaction);
		Interaction.Disable(n"WindupActive");
		LastInputType = EWindupInputDirection::None;
		LastWindupAmount = WindupActor.GetCurrentWindup();
		
		WindupActor.ActivatePlayerInteracting(PlayerOwner);
		if(PlayerOwner.IsMay())
			PlayerOwner.AddLocomotionFeature(WindupActor.MayFeature);
		else
			PlayerOwner.AddLocomotionFeature(WindupActor.CodyFeature);

		bWaitingForActivationFullSync = true;
		Sync::FullSyncPoint(this, n"InteractionActivation");
    }
  
    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		PlayerOwner.StopForceFeedback(WindupActor.MovingEffect, n"Windup");
		if(WindupActor.IsFinished())
		{
			PlayerOwner.PlayForceFeedback(WindupActor.FinishedEffect, false, false, n"WindupFinished");
		}

		if(PlayerOwner.IsMay())
			PlayerOwner.RemoveLocomotionFeature(WindupActor.MayFeature);
		else
			PlayerOwner.RemoveLocomotionFeature(WindupActor.CodyFeature);

		PlayerOwner.UnblockMovementSyncronization(this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::Interaction, this);
		PlayerOwner.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		WindupActor.DeactivatePlayerInteracting(PlayerOwner);		
		WindupActor = nullptr;
		bWaitingForEnableFullSync = true;
		Sync::FullSyncPoint(this, n"EnableInteraction");

		RemoveCancelPromptByInstigator(PlayerOwner, this);
		PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
    }

	UFUNCTION(NotBlueprintCallable)
	void InteractionActivation()
	{
		bWaitingForActivationFullSync = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void EnableInteraction()
	{
		bWaitingForEnableFullSync = false;
		if(Interaction != nullptr)
		{
			Interaction.Enable(n"WindupActive");
			Interaction = nullptr;
		}
	}

	
    UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl() && !bWaitingForActivationFullSync)
		{
			UpdateControlSide(DeltaTime);
		}

		FVector InputDir;
		if(LastInputType == EWindupInputDirection::Push)
		{
			InputDir = Interaction.GetForwardVector();
		}		
		else if(LastInputType == EWindupInputDirection::Pull)
		{
			InputDir = -Interaction.GetForwardVector();
		}
		else
		{
			InputDir = FVector::ZeroVector;
		}

		const float CurrentWindupAmount = WindupActor.GetCurrentWindup();
		
		const bool bIsMoving = FMath::Abs(CurrentWindupAmount - LastWindupAmount) > SMALL_NUMBER;
		const float InputDirAmount = InputDir.DotProduct(Interaction.GetForwardVector());
		
		LastWindupAmount = CurrentWindupAmount;

		if(MoveComponent.CanCalculateMovement())
		{
			if(InputDirAmount == 0.f || WindupActor.IsFinished())
			{
				PlayerOwner.SetAnimFloatParam(n"PushInputX", 0.f);
				PlayerOwner.SetAnimFloatParam(n"PushInputY", 0.f);
				PlayerOwner.StopForceFeedback(WindupActor.MovingEffect, n"Windup");
				FailedMoveLastFrameAount = 0.f;
			}
			else
			{
				if(bIsMoving)
				{
					PlayerOwner.SetAnimFloatParam(n"PushInputX", 0.f);
					PlayerOwner.SetAnimFloatParam(n"PushInputY", InputDirAmount);
					PlayerOwner.PlayForceFeedback(WindupActor.MovingEffect, true, false, n"Windup");
					FailedMoveLastFrameAount = 0.f;
				}
				else
				{
					PlayerOwner.SetAnimFloatParam(n"PushInputX", InputDirAmount);
					PlayerOwner.SetAnimFloatParam(n"PushInputY", 0.f);
					if(FailedMoveLastFrameAount != InputDirAmount)
					{
						PlayerOwner.PlayForceFeedback(WindupActor.TryMovingEffect, false, false, n"FailedWindup");
						FailedMoveLastFrameAount = InputDirAmount;
					}
				}
			}

			FHazeFrameMovement FinalMovement = MoveComponent.MakeFrameMovement(n"Windup");
			MoveComponent.Move(FinalMovement);
	
			FHazeRequestLocomotionData AnimationRequest;
			AnimationRequest.AnimationTag = n"Windup";
			PlayerOwner.RequestLocomotion(AnimationRequest);
		}
	}

	void UpdateControlSide(float DeltaTime)
	{
		const FVector ActorForward = PlayerOwner.GetActorForwardVector();

		float CurrentValidInput = 0;
		const FVector SteeringVector = GetAttributeVector(AttributeVectorNames::MovementDirection);
		if(SteeringVector.Size() > KINDA_SMALL_NUMBER)
		{
			if(WindupActor.bAnyInputIsValidInput)
			{
				CurrentValidInput = 1.f;
			}
			else
			{
				CurrentValidInput = SteeringVector.DotProduct(ActorForward);
				if(LastSteeringVector.Size() > KINDA_SMALL_NUMBER && FMath::Abs(LastValidInputAmount) > KINDA_SMALL_NUMBER)
				{
					if(SteeringVector.GetSafeNormal().DotProduct(LastSteeringVector) > 1.f - KINDA_SMALL_NUMBER)
						CurrentValidInput = FMath::Sign(LastValidInputAmount) * SteeringVector.Size();
				}
			}
		}
		LastSteeringVector = SteeringVector.GetSafeNormal();
		LastValidInputAmount = CurrentValidInput;
	
		const bool bIsPush = Interaction.HasTag(n"Push");
		EWindupInputDirection TargetDirection = EWindupInputDirection::None;
		if(bIsPush)
		{	
			if(CurrentValidInput > ValidInput)
			{		
				TargetDirection = EWindupInputDirection::Push;	
			}	
			else if(CurrentValidInput < -ValidInput)
			{
				TargetDirection = EWindupInputDirection::Pull;	
			}	
		}
		else
		{
			if(CurrentValidInput < -ValidInput)
			{
				TargetDirection = EWindupInputDirection::Pull;
			}		
			else if(CurrentValidInput > ValidInput)
			{
				TargetDirection = EWindupInputDirection::Push;
			}		
		}

		if(TargetDirection != LastInputType)
		{
			NetReplicateInput(TargetDirection);
		}
	}
	
	UFUNCTION(NetFunction)
	void NetReplicateInput(EWindupInputDirection ReplicatedDirection)
	{
		if(Interaction == nullptr)
			return;

		if(WindupActor == nullptr)
			return;

		if(PlayerOwner == nullptr)
			return;

		const bool bIsPushForward = Interaction.HasTag(n"Push");
		if(ReplicatedDirection == EWindupInputDirection::Push)
		{
			if(bIsPushForward)
			{	
				WindupActor.SetInputType(PlayerOwner, EWindupInputActorDirection::Forward);	
			}
			else
			{
				WindupActor.SetInputType(PlayerOwner, EWindupInputActorDirection::Backward);
			}
		}
		else if(ReplicatedDirection == EWindupInputDirection::Pull)
		{
			if(bIsPushForward)
			{	
				WindupActor.SetInputType(PlayerOwner, EWindupInputActorDirection::Backward);	
			}
			else
			{
				WindupActor.SetInputType(PlayerOwner, EWindupInputActorDirection::Forward);
			}
		}
		else
		{
			WindupActor.SetInputType(PlayerOwner, EWindupInputActorDirection::None);
		}

		LastInputType = ReplicatedDirection;
	}
}